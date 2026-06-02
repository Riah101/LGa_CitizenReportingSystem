from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import models as db_models
from django.db.models import Count, Q
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema, OpenApiParameter

from .models import (
    Complaint, ComplaintAttachment, Comment,
    ComplaintUpvote, StatusUpdate, ComplaintStatus,
    GovernmentLevel,
)
from .serializers import (
    ComplaintListSerializer, ComplaintDetailSerializer,
    ComplaintCreateSerializer, ComplaintUpdateSerializer,
    AddCommentSerializer, EscalateSerializer, TrackingSerializer,
    CommentSerializer, AttachmentSerializer,
)
from .filters import ComplaintFilter
from apps.users.permissions import IsComplaintOwnerOrOfficer, IsOfficerForLevel
from apps.notifications.tasks import (
    notify_complaint_submitted,
    notify_status_changed,
    notify_escalated,
    notify_comment_added,
)


class ComplaintListCreateView(generics.ListCreateAPIView):
    """
    GET  /api/v1/complaints/        - List complaints (filtered by role)
    POST /api/v1/complaints/        - Submit new complaint
    """
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ComplaintFilter
    search_fields = ['title', 'description', 'tracking_code', 'mtaa', 'ward']
    ordering_fields = ['submitted_at', 'updated_at', 'priority_score', 'upvotes']
    ordering = ['-submitted_at']

    def get_queryset(self):
        user = self.request.user
        qs = Complaint.objects.select_related('citizen').prefetch_related(
            'attachments', 'comments', 'escalation_history'
        )

        # Admin sees all
        if user.is_staff:
            return qs

        # Officers see complaints at their jurisdiction
        if user.is_officer:
            level = user.jurisdiction_level
            if level == 'national':
                return qs
            if level == 'region':
                return qs.filter(region=user.region)
            if level == 'district':
                return qs.filter(district=user.district)
            if level == 'ward':
                return qs.filter(ward=user.ward)
            if level == 'mtaa':
                return qs.filter(mtaa=user.mtaa)

        # Citizens see only their own complaints
        return qs.filter(citizen=user)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ComplaintCreateSerializer
        return ComplaintListSerializer

    def perform_create(self, serializer):
        complaint = serializer.save()
        # Trigger async notification
        notify_complaint_submitted.delay(str(complaint.id))

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        complaint = Complaint.objects.get(id=serializer.instance.id)
        return Response(
            ComplaintDetailSerializer(complaint, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


class ComplaintDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/v1/complaints/<id>/  - Full detail
    PATCH  /api/v1/complaints/<id>/  - Update status (officers only)
    DELETE /api/v1/complaints/<id>/  - Delete (admin only)
    """
    permission_classes = [IsAuthenticated, IsComplaintOwnerOrOfficer]
    queryset = Complaint.objects.select_related('citizen').prefetch_related(
        'attachments', 'comments__author',
        'escalation_history__escalated_by',
        'status_updates__updated_by',
    )

    def get_serializer_class(self):
        if self.request.method in ['PATCH', 'PUT']:
            return ComplaintUpdateSerializer
        return ComplaintDetailSerializer

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Increment view count
        Complaint.objects.filter(id=instance.id).update(
            view_count=db_models.F('view_count') + 1
        )
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    def update(self, request, *args, **kwargs):
        complaint = self.get_object()
        old_status = complaint.status
        serializer = self.get_serializer(complaint, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        complaint = serializer.save()

        # Log status change
        if 'status' in request.data and request.data['status'] != old_status:
            StatusUpdate.objects.create(
                complaint=complaint,
                from_status=old_status,
                to_status=complaint.status,
                updated_by=request.user,
                notes=request.data.get('notes', ''),
            )
            complaint.last_action_at = timezone.now()
            complaint.save(update_fields=['last_action_at'])
            notify_status_changed.delay(str(complaint.id), old_status, complaint.status)

        return Response(ComplaintDetailSerializer(complaint, context={'request': request}).data)

    def destroy(self, request, *args, **kwargs):
        if not request.user.is_staff:
            return Response(
                {'error': 'Only admins can delete complaints.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)


@extend_schema(tags=['complaints'])
@api_view(['GET'])
@permission_classes([AllowAny])
def track_complaint(request):
    """
    Track a complaint by its tracking code.
    Public endpoint - no authentication needed.
    """
    code = request.query_params.get('code', '').strip().upper()
    if not code:
        return Response({'error': 'Tracking code is required.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        complaint = Complaint.objects.select_related('citizen').prefetch_related(
            'attachments', 'comments__author',
            'escalation_history', 'status_updates',
        ).get(tracking_code=code)
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found.'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ComplaintDetailSerializer(complaint, context={'request': request})
    return Response(serializer.data)


@extend_schema(tags=['complaints'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def escalate_complaint(request, pk):
    """
    Manually escalate a complaint to the next level.
    Officers and admins only.
    """
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found.'}, status=status.HTTP_404_NOT_FOUND)

    # Permission: officer at current level or admin
    user = request.user
    if not user.is_staff and not user.is_officer:
        return Response({'error': 'Only officers can escalate complaints.'}, status=status.HTTP_403_FORBIDDEN)

    if complaint.status in [ComplaintStatus.RESOLVED, ComplaintStatus.CLOSED]:
        return Response({'error': 'Cannot escalate a resolved complaint.'}, status=status.HTTP_400_BAD_REQUEST)

    if not complaint.next_level:
        return Response({'error': 'Complaint is already at national level.'}, status=status.HTTP_400_BAD_REQUEST)

    serializer = EscalateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    complaint.escalate(
        reason=serializer.validated_data['reason'],
        escalated_by=request.user,
    )

    notify_escalated.delay(str(complaint.id))
    return Response(
        ComplaintDetailSerializer(complaint, context={'request': request}).data
    )


@extend_schema(tags=['complaints'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def resolve_complaint(request, pk):
    """Mark a complaint as resolved."""
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    if not (request.user.is_officer or request.user.is_staff):
        return Response({'error': 'Only officers can resolve complaints.'}, status=status.HTTP_403_FORBIDDEN)

    old_status = complaint.status
    notes = request.data.get('notes', '')
    complaint.resolve(resolved_by=request.user, notes=notes)

    StatusUpdate.objects.create(
        complaint=complaint,
        from_status=old_status,
        to_status=ComplaintStatus.RESOLVED,
        updated_by=request.user,
        notes=notes,
    )

    notify_status_changed.delay(str(complaint.id), old_status, ComplaintStatus.RESOLVED)
    return Response(
        ComplaintDetailSerializer(complaint, context={'request': request}).data
    )


@extend_schema(tags=['complaints'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upvote_complaint(request, pk):
    """Upvote a complaint (each user once)."""
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    upvote, created = ComplaintUpvote.objects.get_or_create(
        complaint=complaint, user=request.user
    )

    if created:
        Complaint.objects.filter(id=pk).update(
            upvotes=db_models.F('upvotes') + 1,
            priority_score=db_models.F('priority_score') + 1,
        )
        return Response({'upvoted': True, 'upvotes': complaint.upvotes + 1})
    else:
        # Remove upvote (toggle)
        upvote.delete()
        Complaint.objects.filter(id=pk).update(
            upvotes=db_models.F('upvotes') - 1,
            priority_score=db_models.F('priority_score') - 1,
        )
        return Response({'upvoted': False, 'upvotes': max(0, complaint.upvotes - 1)})


@extend_schema(tags=['complaints'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_comment(request, pk):
    """Add a comment to a complaint."""
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    serializer = AddCommentSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    is_internal = serializer.validated_data.get('is_internal', False)
    is_official = request.user.is_officer or request.user.is_staff

    # Only officers can post internal comments
    if is_internal and not is_official:
        is_internal = False

    comment = Comment.objects.create(
        complaint=complaint,
        author=request.user,
        content=serializer.validated_data['content'],
        is_official=is_official,
        is_internal=is_internal,
    )

    complaint.last_action_at = timezone.now()
    complaint.save(update_fields=['last_action_at'])

    notify_comment_added.delay(str(complaint.id), str(comment.id))
    return Response(
        CommentSerializer(comment, context={'request': request}).data,
        status=status.HTTP_201_CREATED,
    )


@extend_schema(tags=['complaints'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_attachment(request, pk):
    """Upload file attachment to a complaint."""
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    if complaint.citizen != request.user and not request.user.is_staff:
        return Response({'error': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

    if 'file' not in request.FILES:
        return Response({'error': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)

    file = request.FILES['file']
    file_type = 'document'
    if file.content_type.startswith('image/'):
        file_type = 'image'

    attachment = ComplaintAttachment.objects.create(
        complaint=complaint,
        file=file,
        file_type=file_type,
        uploaded_by=request.user,
    )
    return Response(
        AttachmentSerializer(attachment, context={'request': request}).data,
        status=status.HTTP_201_CREATED,
    )


class DashboardStatsView(APIView):
    """
    GET /api/v1/complaints/stats/
    Returns stats tailored to user role.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        qs = self._get_queryset(user)

        stats = qs.aggregate(
            total=Count('id'),
            pending=Count('id', filter=Q(status=ComplaintStatus.PENDING)),
            in_progress=Count('id', filter=Q(status=ComplaintStatus.IN_PROGRESS)),
            escalated=Count('id', filter=Q(status=ComplaintStatus.ESCALATED)),
            resolved=Count('id', filter=Q(status=ComplaintStatus.RESOLVED)),
            closed=Count('id', filter=Q(status=ComplaintStatus.CLOSED)),
        )

        # Category breakdown
        by_category = list(
            qs.values('category')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Level breakdown
        by_level = list(
            qs.values('current_level')
            .annotate(count=Count('id'))
            .order_by('current_level')
        )

        # Region breakdown (for admin/national)
        by_region = []
        if user.is_staff or (user.is_officer and user.jurisdiction_level == 'national'):
            by_region = list(
                qs.values('region')
                .annotate(count=Count('id'))
                .order_by('-count')[:10]
            )

        # Due for escalation (0-2 days remaining)
        due_soon = []
        for complaint in qs.filter(
            status__in=[ComplaintStatus.PENDING, ComplaintStatus.IN_PROGRESS]
        ).exclude(current_level=GovernmentLevel.NATIONAL):
            if complaint.days_until_escalation <= 2:
                due_soon.append({
                    'id': str(complaint.id),
                    'tracking_code': complaint.tracking_code,
                    'title': complaint.title,
                    'days_remaining': complaint.days_until_escalation,
                    'current_level': complaint.current_level,
                })

        return Response({
            'summary': stats,
            'by_category': by_category,
            'by_level': by_level,
            'by_region': by_region,
            'due_for_escalation': due_soon[:10],
        })

    def _get_queryset(self, user):
        qs = Complaint.objects.all()
        if user.is_staff:
            return qs
        if user.is_officer:
            level = user.jurisdiction_level
            if level == 'national': return qs
            if level == 'region': return qs.filter(region=user.region)
            if level == 'district': return qs.filter(district=user.district)
            if level == 'ward': return qs.filter(ward=user.ward)
            if level == 'mtaa': return qs.filter(mtaa=user.mtaa)
        return qs.filter(citizen=user)


class PublicComplaintsView(generics.ListAPIView):
    """
    Public feed of non-anonymous complaints (for transparency).
    GET /api/v1/complaints/public/
    """
    serializer_class = ComplaintListSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ComplaintFilter
    search_fields = ['title', 'ward', 'district', 'region']
    ordering_fields = ['submitted_at', 'upvotes', 'priority_score']
    ordering = ['-priority_score', '-submitted_at']

    def get_queryset(self):
        return Complaint.objects.filter(
            is_anonymous=False
        ).select_related('citizen').prefetch_related('attachments', 'comments')
