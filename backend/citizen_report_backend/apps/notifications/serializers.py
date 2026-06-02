from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    complaint_tracking_code = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'message',
            'is_read', 'complaint_tracking_code', 'created_at',
        ]

    def get_complaint_tracking_code(self, obj):
        return obj.complaint.tracking_code if obj.complaint else None
