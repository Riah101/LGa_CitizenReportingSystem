import uuid
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models
from django.utils import timezone


class UserRole(models.TextChoices):
    CITIZEN = 'citizen', 'Citizen / Raia'
    MTAA_OFFICER = 'mtaa_officer', 'Mtaa Officer / Afisa Mtaa'
    WARD_OFFICER = 'ward_officer', 'Ward Officer / Afisa Kata'
    DISTRICT_OFFICER = 'district_officer', 'District Officer / Afisa Wilaya'
    REGION_OFFICER = 'region_officer', 'Regional Officer / Afisa Mkoa'
    NATIONAL_OFFICER = 'national_officer', 'National Officer / Afisa Kitaifa'
    ADMIN = 'admin', 'Administrator'


class UserManager(BaseUserManager):
    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError('Phone number is required')
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', UserRole.ADMIN)
        extra_fields.setdefault('is_verified', True)
        return self.create_user(phone, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=20, unique=True)
    email = models.EmailField(blank=True, null=True)
    full_name = models.CharField(max_length=200)
    national_id = models.CharField(max_length=30, blank=True, null=True, unique=True)
    profile_photo = models.ImageField(upload_to='profiles/', blank=True, null=True)

    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.CITIZEN,
    )

    # Location (for citizens - their home area; for officers - their jurisdiction)
    mtaa = models.CharField(max_length=100, blank=True, null=True)
    ward = models.CharField(max_length=100, blank=True, null=True)
    district = models.CharField(max_length=100, blank=True, null=True)
    region = models.CharField(max_length=100, blank=True, null=True)

    # Status
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)

    # Stats (cached)
    total_complaints = models.PositiveIntegerField(default=0)
    resolved_complaints = models.PositiveIntegerField(default=0)

    # Preferences
    preferred_language = models.CharField(
        max_length=5, choices=[('en', 'English'), ('sw', 'Kiswahili')], default='sw'
    )

    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = ['full_name']

    objects = UserManager()

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        indexes = [
            models.Index(fields=['phone']),
            models.Index(fields=['role']),
            models.Index(fields=['region', 'district', 'ward']),
        ]

    def __str__(self):
        return f"{self.full_name} ({self.phone})"

    @property
    def is_officer(self):
        return self.role != UserRole.CITIZEN

    @property
    def jurisdiction_level(self):
        """Returns the government level this officer manages."""
        mapping = {
            UserRole.MTAA_OFFICER: 'mtaa',
            UserRole.WARD_OFFICER: 'ward',
            UserRole.DISTRICT_OFFICER: 'district',
            UserRole.REGION_OFFICER: 'region',
            UserRole.NATIONAL_OFFICER: 'national',
        }
        return mapping.get(self.role)


class OTPCode(models.Model):
    """One-Time Password for phone verification."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=20)
    code = models.CharField(max_length=6)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'otp_codes'

    def is_valid(self):
        return not self.is_used and timezone.now() < self.expires_at

    def __str__(self):
        return f"OTP for {self.phone}"
