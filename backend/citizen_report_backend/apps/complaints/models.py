import uuid
from django.db import models
from django.utils import timezone
from django.conf import settings


class GovernmentLevel(models.TextChoices):
    MTAA = 'mtaa', 'Mtaa'
    WARD = 'ward', 'Ward / Kata'
    DISTRICT = 'district', 'District / Wilaya'
    REGION = 'region', 'Region / Mkoa'
    NATIONAL = 'national', 'National / Taifa'


class ComplaintStatus(models.TextChoices):
    PENDING = 'pending', 'Pending / Inasubiri'
    IN_PROGRESS = 'in_progress', 'In Progress / Inashughulikiwa'
    ESCALATED = 'escalated', 'Escalated / Imepandishwa'
    RESOLVED = 'resolved', 'Resolved / Imesuluhiwa'
    CLOSED = 'closed', 'Closed / Imefungwa'


class ComplaintCategory(models.TextChoices):
    INFRASTRUCTURE = 'infrastructure', 'Infrastructure / Miundombinu'
    WATER = 'water', 'Water / Maji'
    ELECTRICITY = 'electricity', 'Electricity / Umeme'
    HEALTH = 'health', 'Health / Afya'
    EDUCATION = 'education', 'Education / Elimu'
    SECURITY = 'security', 'Security / Usalama'
    ENVIRONMENT = 'environment', 'Environment / Mazingira'
    SOCIAL_SERVICES = 'social_services', 'Social Services / Huduma za Jamii'
    CORRUPTION = 'corruption', 'Corruption / Rushwa'
    OTHER = 'other', 'Other / Nyingine'


# Days at each level before auto-escalation
ESCALATION_DAYS = {
    GovernmentLevel.MTAA: 7,
    GovernmentLevel.WARD: 14,
    GovernmentLevel.DISTRICT: 21,
    GovernmentLevel.REGION: 30,
}

LEVEL_ORDER = [
    GovernmentLevel.MTAA,
    GovernmentLevel.WARD,
    GovernmentLevel.DISTRICT,
    GovernmentLevel.REGION,
    GovernmentLevel.NATIONAL,
]


class Complaint(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tracking_code = models.CharField(max_length=10, unique=True, db_index=True)

    # Citizen
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='complaints',
    )
    is_anonymous = models.BooleanField(default=False)

    # Content
    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=30, choices=ComplaintCategory.choices)

    # Status & Level
    status = models.CharField(
        max_length=20,
        choices=ComplaintStatus.choices,
        default=ComplaintStatus.PENDING,
        db_index=True,
    )
    current_level = models.CharField(
        max_length=20,
        choices=GovernmentLevel.choices,
        default=GovernmentLevel.MTAA,
        db_index=True,
    )

    # Location (Tanzania administrative hierarchy)
    mtaa = models.CharField(max_length=100)
    ward = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    region = models.CharField(max_length=100)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)

    # Priority
    is_urgent = models.BooleanField(default=False)
    priority_score = models.PositiveIntegerField(default=0, db_index=True)
    upvotes = models.PositiveIntegerField(default=0)
    view_count = models.PositiveIntegerField(default=0)

    # Timestamps
    submitted_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    last_action_at = models.DateTimeField(default=timezone.now)  # Resets on any officer action
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'complaints'
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['status', 'current_level']),
            models.Index(fields=['region', 'district', 'ward', 'mtaa']),
            models.Index(fields=['category']),
            models.Index(fields=['last_action_at']),
            models.Index(fields=['citizen', 'status']),
        ]

    def __str__(self):
        return f'[{self.tracking_code}] {self.title}'

    def save(self, *args, **kwargs):
        if not self.tracking_code:
            self.tracking_code = self._generate_tracking_code()
        super().save(*args, **kwargs)

    @staticmethod
    def _generate_tracking_code():
        import random, string
        chars = string.ascii_uppercase + string.digits
        while True:
            code = 'SR' + ''.join(random.choices(chars, k=6))
            if not Complaint.objects.filter(tracking_code=code).exists():
                return code

    @property
    def days_at_current_level(self):
        return (timezone.now() - self.last_action_at).days

    @property
    def days_until_escalation(self):
        allowed = ESCALATION_DAYS.get(self.current_level)
        if allowed is None:
            return -1
        remaining = allowed - self.days_at_current_level
        return max(0, remaining)

    @property
    def should_escalate(self):
        if self.status in [ComplaintStatus.RESOLVED, ComplaintStatus.CLOSED]:
            return False
        if self.current_level == GovernmentLevel.NATIONAL:
            return False
        allowed = ESCALATION_DAYS.get(self.current_level, 7)
        return self.days_at_current_level >= allowed

    @property
    def next_level(self):
        try:
            idx = LEVEL_ORDER.index(self.current_level)
            if idx < len(LEVEL_ORDER) - 1:
                return LEVEL_ORDER[idx + 1]
        except ValueError:
            pass
        return None

    def escalate(self, reason='Auto-escalated', escalated_by=None):
        """Escalate complaint to the next government level."""
        next_lvl = self.next_level
        if not next_lvl:
            return False

        EscalationHistory.objects.create(
            complaint=self,
            from_level=self.current_level,
            to_level=next_lvl,
            reason=reason,
            escalated_by=escalated_by,
        )

        self.current_level = next_lvl
        self.status = ComplaintStatus.ESCALATED
        self.last_action_at = timezone.now()
        self.save(update_fields=['current_level', 'status', 'last_action_at', 'updated_at'])
        return True

    def resolve(self, resolved_by=None, notes=''):
        self.status = ComplaintStatus.RESOLVED
        self.resolved_at = timezone.now()
        self.last_action_at = timezone.now()
        self.save(update_fields=['status', 'resolved_at', 'last_action_at', 'updated_at'])

        # Update citizen stats
        from django.contrib.auth import get_user_model
        User = get_user_model()
        User.objects.filter(id=self.citizen_id).update(
            resolved_complaints=models.F('resolved_complaints') + 1
        )

    def mark_in_progress(self):
        self.status = ComplaintStatus.IN_PROGRESS
        self.last_action_at = timezone.now()
        self.save(update_fields=['status', 'last_action_at', 'updated_at'])


class ComplaintAttachment(models.Model):
    """Photos or documents attached to a complaint."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='complaints/attachments/%Y/%m/')
    file_type = models.CharField(max_length=10, default='image')  # image, document
    uploaded_at = models.DateTimeField(auto_now_add=True)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
    )

    class Meta:
        db_table = 'complaint_attachments'

    def __str__(self):
        return f'Attachment for {self.complaint.tracking_code}'


class EscalationHistory(models.Model):
    """Tracks every level change of a complaint."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    complaint = models.ForeignKey(
        Complaint, on_delete=models.CASCADE, related_name='escalation_history'
    )
    from_level = models.CharField(max_length=20, choices=GovernmentLevel.choices)
    to_level = models.CharField(max_length=20, choices=GovernmentLevel.choices)
    reason = models.TextField()
    escalated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    escalated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'escalation_history'
        ordering = ['escalated_at']

    def __str__(self):
        return f'{self.complaint.tracking_code}: {self.from_level} → {self.to_level}'


class Comment(models.Model):
    """Comments on complaints from citizens or officers."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    complaint = models.ForeignKey(
        Complaint, on_delete=models.CASCADE, related_name='comments'
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comments',
    )
    content = models.TextField()
    is_official = models.BooleanField(default=False)  # True for officer responses
    is_internal = models.BooleanField(default=False)  # True = only visible to officers
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'complaint_comments'
        ordering = ['created_at']

    def __str__(self):
        return f'Comment by {self.author.full_name} on {self.complaint.tracking_code}'


class ComplaintUpvote(models.Model):
    """Track which users upvoted which complaints (prevent duplicates)."""
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='upvote_records')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'complaint_upvotes'
        unique_together = [('complaint', 'user')]


class StatusUpdate(models.Model):
    """Audit log of all status changes."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    complaint = models.ForeignKey(
        Complaint, on_delete=models.CASCADE, related_name='status_updates'
    )
    from_status = models.CharField(max_length=20, choices=ComplaintStatus.choices)
    to_status = models.CharField(max_length=20, choices=ComplaintStatus.choices)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
    )
    notes = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'status_updates'
        ordering = ['updated_at']
