from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Complaint, ComplaintStatus


@receiver(post_save, sender=Complaint)
def complaint_post_save(sender, instance, created, **kwargs):
    """Recalculate priority score on save."""
    if not created:
        return
    score = instance.upvotes
    if instance.is_urgent:
        score += 10
    if score != instance.priority_score:
        Complaint.objects.filter(id=instance.id).update(priority_score=score)
