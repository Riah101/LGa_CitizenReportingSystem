from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Complaint, ComplaintAttachment, EscalationHistory,
    Comment, ComplaintUpvote, StatusUpdate, ComplaintStatus
)

User = get_user_model()


class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'role', 'profile_photo']


class AttachmentSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = ComplaintAttachment
        fields = ['id', 'file_url', 'file_type', 'uploaded_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return None


class EscalationHistorySerializer(serializers.ModelSerializer):
    escalated_by_name = serializers.SerializerMethodField()

    class Meta:
        model = EscalationHistory
        fields = ['id', 'from_level', 'to_level', 'reason', 'escalated_by_name', 'escalated_at']

    def get_escalated_by_name(self, obj):
        if obj.escalated_by:
            return obj.escalated_by.full_name
        return 'System (Auto)'


class CommentSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'author', 'content', 'is_official', 'is_internal', 'created_at', 'updated_at']
        read_only_fields = ['id', 'author', 'is_official', 'created_at', 'updated_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Hide internal comments from non-officers
        request = self.context.get('request')
        if instance.is_internal and request:
            user = request.user
            if not (user.is_officer or user.is_staff):
                return None
        return data


class StatusUpdateSerializer(serializers.ModelSerializer):
    updated_by_name = serializers.SerializerMethodField()

    class Meta:
        model = StatusUpdate
        fields = ['id', 'from_status', 'to_status', 'updated_by_name', 'notes', 'updated_at']

    def get_updated_by_name(self, obj):
        return obj.updated_by.full_name if obj.updated_by else 'System'


class ComplaintListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views."""
    citizen_name = serializers.SerializerMethodField()
    attachments_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    days_until_escalation = serializers.IntegerField(read_only=True)

    class Meta:
        model = Complaint
        fields = [
            'id', 'tracking_code', 'title', 'category', 'status',
            'current_level', 'mtaa', 'ward', 'district', 'region',
            'is_urgent', 'is_anonymous', 'priority_score', 'upvotes',
            'citizen_name', 'attachments_count', 'comments_count',
            'days_until_escalation', 'submitted_at', 'updated_at',
        ]

    def get_citizen_name(self, obj):
        if obj.is_anonymous:
            return 'Anonymous'
        return obj.citizen.full_name

    def get_attachments_count(self, obj):
        return obj.attachments.count()

    def get_comments_count(self, obj):
        return obj.comments.filter(is_internal=False).count()


class ComplaintDetailSerializer(serializers.ModelSerializer):
    """Full serializer for detail views."""
    citizen = AuthorSerializer(read_only=True)
    attachments = AttachmentSerializer(many=True, read_only=True)
    escalation_history = EscalationHistorySerializer(many=True, read_only=True)
    comments = serializers.SerializerMethodField()
    status_updates = StatusUpdateSerializer(many=True, read_only=True)
    days_until_escalation = serializers.IntegerField(read_only=True)
    days_at_current_level = serializers.IntegerField(read_only=True)
    next_level = serializers.CharField(read_only=True)

    class Meta:
        model = Complaint
        fields = [
            'id', 'tracking_code', 'citizen', 'is_anonymous',
            'title', 'description', 'category',
            'status', 'current_level',
            'mtaa', 'ward', 'district', 'region', 'latitude', 'longitude',
            'is_urgent', 'priority_score', 'upvotes', 'view_count',
            'attachments', 'escalation_history', 'comments', 'status_updates',
            'days_until_escalation', 'days_at_current_level', 'next_level',
            'submitted_at', 'updated_at', 'last_action_at', 'resolved_at',
        ]

    def get_comments(self, obj):
        request = self.context.get('request')
        user = request.user if request else None
        qs = obj.comments.all()
        if not (user and (user.is_officer or user.is_staff)):
            qs = qs.filter(is_internal=False)
        serializer = CommentSerializer(qs, many=True, context=self.context)
        return [c for c in serializer.data if c is not None]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if instance.is_anonymous:
            data['citizen'] = {'full_name': 'Anonymous', 'role': 'citizen'}
        return data


class ComplaintCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = [
            'title', 'description', 'category',
            'mtaa', 'ward', 'district', 'region',
            'latitude', 'longitude',
            'is_anonymous', 'is_urgent',
        ]

    def validate_title(self, value):
        if len(value.strip()) < 5:
            raise serializers.ValidationError('Title must be at least 5 characters.')
        return value.strip()

    def validate_description(self, value):
        if len(value.strip()) < 20:
            raise serializers.ValidationError('Description must be at least 20 characters.')
        return value.strip()

    def create(self, validated_data):
        citizen = self.context['request'].user
        complaint = Complaint.objects.create(citizen=citizen, **validated_data)
        # Update citizen total complaints
        User.objects.filter(id=citizen.id).update(
            total_complaints=User.objects.get(id=citizen.id).total_complaints + 1
        )
        return complaint


class ComplaintUpdateSerializer(serializers.ModelSerializer):
    """Officers use this to update status, add notes."""
    class Meta:
        model = Complaint
        fields = ['status', 'is_urgent']

    def validate_status(self, value):
        complaint = self.instance
        # Prevent going back to pending from resolved/closed
        if complaint.status in [ComplaintStatus.RESOLVED, ComplaintStatus.CLOSED]:
            if value not in [ComplaintStatus.RESOLVED, ComplaintStatus.CLOSED]:
                raise serializers.ValidationError('Cannot reopen a resolved/closed complaint.')
        return value


class AddCommentSerializer(serializers.Serializer):
    content = serializers.CharField(min_length=1, max_length=2000)
    is_internal = serializers.BooleanField(default=False)


class EscalateSerializer(serializers.Serializer):
    reason = serializers.CharField(min_length=5, max_length=500)


class TrackingSerializer(serializers.Serializer):
    tracking_code = serializers.CharField(max_length=10)
