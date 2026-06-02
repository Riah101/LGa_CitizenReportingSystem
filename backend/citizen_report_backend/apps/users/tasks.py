from celery import shared_task
from django.utils import timezone
from .models import OTPCode


@shared_task
def cleanup_expired_otps():
    """Delete OTPs older than 1 hour."""
    deleted, _ = OTPCode.objects.filter(expires_at__lt=timezone.now()).delete()
    return f'Deleted {deleted} expired OTPs'


@shared_task
def send_sms_otp(phone, code):
    """
    Send OTP via Africa's Talking SMS gateway.
    Install: pip install africastalking
    """
    try:
        from django.conf import settings
        # Uncomment when africastalking is installed:
        # import africastalking
        # africastalking.initialize(
        #     settings.AFRICASTALKING_USERNAME,
        #     settings.AFRICASTALKING_API_KEY,
        # )
        # sms = africastalking.SMS
        # sms.send(
        #     f'Your Sauti ya Raia OTP is: {code}. Valid for 10 minutes.',
        #     [phone]
        # )
        print(f'[SMS] Sending OTP {code} to {phone}')
        return f'OTP sent to {phone}'
    except Exception as e:
        return f'SMS failed: {str(e)}'
