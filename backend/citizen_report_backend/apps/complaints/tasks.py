from celery import shared_task
from django.utils import timezone
from django.db.models import Q
import logging

logger = logging.getLogger('apps.complaints')


@shared_task(bind=True, max_retries=3)
def auto_escalate_complaints(self):
    """
    Core task: runs daily at midnight.
    Checks all active complaints and escalates overdue ones.
    """
    from .models import Complaint, ComplaintStatus, GovernmentLevel, ESCALATION_DAYS

    try:
        active_complaints = Complaint.objects.filter(
            status__in=[ComplaintStatus.PENDING, ComplaintStatus.IN_PROGRESS, ComplaintStatus.ESCALATED]
        ).exclude(current_level=GovernmentLevel.NATIONAL)

        escalated_count = 0
        skipped_count = 0

        for complaint in active_complaints:
            if complaint.should_escalate:
                allowed_days = ESCALATION_DAYS.get(complaint.current_level, 7)
                reason = (
                    f'Auto-escalated: No action taken within {allowed_days} days '
                    f'at {complaint.get_current_level_display()} level.'
                )
                success = complaint.escalate(reason=reason, escalated_by=None)
                if success:
                    escalated_count += 1
                    logger.info(f'Auto-escalated: {complaint.tracking_code} → {complaint.current_level}')
                    # Notify the citizen
                    notify_escalated.delay(str(complaint.id))
            else:
                skipped_count += 1

        result = f'Auto-escalation complete: {escalated_count} escalated, {skipped_count} not due.'
        logger.info(result)
        return result

    except Exception as exc:
        logger.error(f'Auto-escalation failed: {exc}')
        raise self.retry(exc=exc, countdown=300)  # Retry in 5 minutes


@shared_task(bind=True, max_retries=3)
def send_escalation_warnings(self):
    """
    Runs every morning at 8AM.
    Warns officers about complaints escalating in 1-2 days.
    """
    from .models import Complaint, ComplaintStatus, GovernmentLevel, ESCALATION_DAYS
    from apps.notifications.models import Notification, NotificationType

    try:
        active = Complaint.objects.filter(
            status__in=[ComplaintStatus.PENDING, ComplaintStatus.IN_PROGRESS]
        ).exclude(current_level=GovernmentLevel.NATIONAL)

        warned = 0
        for complaint in active:
            days_left = complaint.days_until_escalation
            if days_left in [1, 2]:  # Warn 1-2 days before escalation
                # Notify the relevant officer
                _notify_officer_warning(complaint, days_left)
                warned += 1

        return f'Sent {warned} escalation warnings'

    except Exception as exc:
        raise self.retry(exc=exc, countdown=300)


def _notify_officer_warning(complaint, days_left):
    """Create warning notification for the officer at this level."""
    from django.contrib.auth import get_user_model
    from apps.notifications.models import Notification, NotificationType
    User = get_user_model()

    level = complaint.current_level
    filters = {'role': f'{level}_officer'}

    location_filter = {}
    if level == 'region': location_filter['region'] = complaint.region
    elif level == 'district': location_filter['district'] = complaint.district
    elif level == 'ward': location_filter['ward'] = complaint.ward
    elif level == 'mtaa': location_filter['mtaa'] = complaint.mtaa

    officers = User.objects.filter(**filters, **location_filter)

    for officer in officers:
        Notification.objects.get_or_create(
            user=officer,
            complaint=complaint,
            notification_type=NotificationType.ESCALATION_WARNING,
            defaults={
                'title': f'Complaint escalating in {days_left} day(s)',
                'message': (
                    f'Complaint [{complaint.tracking_code}] "{complaint.title}" '
                    f'will escalate to {complaint.next_level} level in {days_left} day(s) '
                    f'if not addressed.'
                ),
            }
        )
