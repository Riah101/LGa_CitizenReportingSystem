from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django_filters.rest_framework import DjangoFilterBackend

from apps.users.serializers import UserSerializer
from apps.users.permissions import IsAdminOrSelf

User = get_user_model()


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get or update own profile."""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        # Prevent role change via this endpoint
        request.data.pop('role', None)
        request.data.pop('is_verified', None)
        return super().update(request, *args, **kwargs)


class UserListView(generics.ListAPIView):
    """Admin: list all users."""
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]
    queryset = User.objects.all().order_by('-created_at')
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['role', 'is_verified', 'is_active', 'region', 'district']
    search_fields = ['phone', 'full_name', 'email', 'national_id']
    ordering_fields = ['created_at', 'full_name']


class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Admin: manage specific user."""
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]
    queryset = User.objects.all()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_profile_photo(request):
    """Upload or update profile photo."""
    if 'photo' not in request.FILES:
        return Response({'error': 'No photo provided.'}, status=status.HTTP_400_BAD_REQUEST)

    user = request.user
    user.profile_photo = request.FILES['photo']
    user.save()
    return Response({
        'message': 'Profile photo updated.',
        'photo_url': request.build_absolute_uri(user.profile_photo.url) if user.profile_photo else None,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_stats(request):
    """Get complaint stats for current user."""
    from apps.complaints.models import Complaint, ComplaintStatus
    user = request.user
    complaints = Complaint.objects.filter(citizen=user)
    return Response({
        'total': complaints.count(),
        'pending': complaints.filter(status=ComplaintStatus.PENDING).count(),
        'in_progress': complaints.filter(status=ComplaintStatus.IN_PROGRESS).count(),
        'escalated': complaints.filter(status=ComplaintStatus.ESCALATED).count(),
        'resolved': complaints.filter(status=ComplaintStatus.RESOLVED).count(),
        'closed': complaints.filter(status=ComplaintStatus.CLOSED).count(),
    })
