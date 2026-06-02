import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('citizen_report')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# ─── Scheduled Tasks ──────────────────────────────────────────────────────────
app.conf.beat_schedule = {
    # Run auto-escalation check every day at midnight (Dar es Salaam time)
    'auto-escalate-complaints': {
        'task': 'apps.complaints.tasks.auto_escalate_complaints',
        'schedule': crontab(hour=0, minute=0),
        'options': {'queue': 'escalation'},
    },
    # Send escalation warning notifications (2 days before)
    'send-escalation-warnings': {
        'task': 'apps.complaints.tasks.send_escalation_warnings',
        'schedule': crontab(hour=8, minute=0),  # 8 AM daily
        'options': {'queue': 'notifications'},
    },
    # Clean up expired OTPs every hour
    'cleanup-expired-otps': {
        'task': 'apps.users.tasks.cleanup_expired_otps',
        'schedule': crontab(minute=0),
        'options': {'queue': 'default'},
    },
}

app.conf.task_routes = {
    'apps.complaints.tasks.*': {'queue': 'escalation'},
    'apps.notifications.tasks.*': {'queue': 'notifications'},
    'apps.users.tasks.*': {'queue': 'default'},
}
