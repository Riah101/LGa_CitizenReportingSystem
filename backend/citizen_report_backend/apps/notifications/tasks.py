from celery import shared_task
import logging

logger = logging.getLogger(__name__)


@shared_task
def notify_complaint_submitted(complaint_id: str):
    """Notify citizen that their complaint was received."""
    try:
        from apps.complaints.models import Complaint
        from .models import Notification, NotificationType

        complaint = Complaint.objects.select_related('citizen').get(id=complaint_id)
        Notification.objects.create(
            user=complaint.citizen,
            complaint=complaint,
            notification_type=NotificationType.COMPLAINT_SUBMITTED,
            title='Complaint Submitted / Lalamiko Limewasilishwa',
            message=(
                f'Your complaint "{complaint.title}" has been submitted successfully. '
                f'Tracking code: {complaint.tracking_code}. '
                f'It will be reviewed by the Mtaa authority.\n\n'
                f'Lalamiko lako "{complaint.title}" limewasilishwa. '
                f'Nambari ya ufuatiliaji: {complaint.tracking_code}.'
            ),
        )
    except Exception as e:
        logger.error(f'notify_complaint_submitted failed: {e}')


@shared_task
def notify_status_changed(complaint_id: str, old_status: str, new_status: str):
    """Notify citizen of status change."""
    try:
        from apps.complaints.models import Complaint
        from .models import Notification, NotificationType

        complaint = Complaint.objects.select_related('citizen').get(id=complaint_id)
        notif_type = (
            NotificationType.RESOLVED
            if new_status == 'resolved'
            else NotificationType.STATUS_CHANGED
        )
        Notification.objects.create(
            user=complaint.citizen,
            complaint=complaint,
            notification_type=notif_type,
            title=f'Complaint Status Updated / Hali Imebadilika',
            message=(
                f'Your complaint [{complaint.tracking_code}] status changed: '
                f'{old_status.replace("_", " ").title()} → {new_status.replace("_", " ").title()}.'
            ),
        )
    except Exception as e:
        logger.error(f'notify_status_changed failed: {e}')


@shared_task
def notify_escalated(complaint_id: str):
    """Notify citizen that complaint was escalated."""
    try:
        from apps.complaints.models import Complaint
        from .models import Notification, NotificationType
        from django.contrib.auth import get_user_model

        User = get_user_model()
        complaint = Complaint.objects.select_related('citizen').get(id=complaint_id)

        # Notify citizen
        Notification.objects.create(
            user=complaint.citizen,
            complaint=complaint,
            notification_type=NotificationType.ESCALATED,
            title='Complaint Escalated / Lalamiko Limepandishwa',
            message=(
                f'Your complaint [{complaint.tracking_code}] "{complaint.title}" '
                f'has been escalated to {complaint.get_current_level_display()} level '
                f'because it was not addressed in time.\n\n'
                f'Lalamiko lako limepandishwa hadi ngazi ya {complaint.current_level}.'
            ),
        )

        # Notify officer at new level
        level = complaint.current_level
        officer_role = f'{level}_officer'
        location_filter = {}
        if level == 'region': location_filter['region'] = complaint.region
        elif level == 'district': location_filter['district'] = complaint.district
        elif level == 'ward': location_filter['ward'] = complaint.ward
        elif level == 'mtaa': location_filter['mtaa'] = complaint.mtaa

        officers = User.objects.filter(role=officer_role, **location_filter)
        for officer in officers:
            Notification.objects.create(
                user=officer,
                complaint=complaint,
                notification_type=NotificationType.ASSIGNED,
                title=f'New Complaint Assigned / Lalamiko Jipya',
                message=(
                    f'Complaint [{complaint.tracking_code}] "{complaint.title}" '
                    f'has been escalated to your level ({complaint.get_current_level_display()}).'
                ),
            )
    except Exception as e:
        logger.error(f'notify_escalated failed: {e}')


@shared_task
def notify_comment_added(complaint_id: str, comment_id: str):
    """Notify complaint owner of new official comment."""
    try:
        from apps.complaints.models import Complaint, Comment
        from .models import Notification, NotificationType

        complaint = Complaint.objects.select_related('citizen').get(id=complaint_id)
        comment = Comment.objects.select_related('author').get(id=comment_id)

        # Only notify if it's an official (officer) response
        if not comment.is_official or comment.is_internal:
            return

        Notification.objects.create(
            user=complaint.citizen,
            complaint=complaint,
            notification_type=NotificationType.COMMENT_ADDED,
            title='Official Response / Jibu Rasmi',
            message=(
                f'{comment.author.full_name} ({comment.author.get_role_display()}) '
                f'responded to your complaint [{complaint.tracking_code}]:\n'
                f'"{comment.content[:150]}{"..." if len(comment.content) > 150 else ""}"'
            ),
        )
    except Exception as e:
        logger.error(f'notify_comment_added failed: {e}')
