import uuid
from django.db import models
from django.conf import settings


class NotificationType(models.TextChoices):
    COMPLAINT_SUBMITTED = 'complaint_submitted', 'Complaint Submitted'
    STATUS_CHANGED = 'status_changed', 'Status Changed'
    ESCALATED = 'escalated', 'Complaint Escalated'
    ESCALATION_WARNING = 'escalation_warning', 'Escalation Warning'
    COMMENT_ADDED = 'comment_added', 'Comment Added'
    RESOLVED = 'resolved', 'Complaint Resolved'
    ASSIGNED = 'assigned', 'Complaint Assigned'
    SYSTEM = 'system', 'System Notification'


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    complaint = models.ForeignKey(
        'complaints.Complaint',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='notifications',
    )
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices)
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f'{self.notification_type} → {self.user.phone}'

    def mark_read(self):
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=['is_read'])
