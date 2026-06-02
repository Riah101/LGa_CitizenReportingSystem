from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, OTPCode


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['phone', 'full_name', 'role', 'region', 'district', 'ward', 'is_verified', 'is_active', 'created_at']
    list_filter = ['role', 'is_verified', 'is_active', 'region']
    search_fields = ['phone', 'full_name', 'email', 'national_id']
    ordering = ['-created_at']

    fieldsets = (
        (None, {'fields': ('phone', 'password')}),
        (_('Personal Info'), {'fields': ('full_name', 'email', 'national_id', 'profile_photo')}),
        (_('Role & Jurisdiction'), {'fields': ('role', 'mtaa', 'ward', 'district', 'region')}),
        (_('Preferences'), {'fields': ('preferred_language',)}),
        (_('Status'), {'fields': ('is_active', 'is_verified', 'is_staff', 'is_superuser')}),
        (_('Stats'), {'fields': ('total_complaints', 'resolved_complaints')}),
        (_('Permissions'), {'fields': ('groups', 'user_permissions')}),
        (_('Dates'), {'fields': ('created_at', 'last_login')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone', 'full_name', 'role', 'password1', 'password2'),
        }),
    )

    readonly_fields = ['created_at', 'total_complaints', 'resolved_complaints']


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ['phone', 'code', 'is_used', 'expires_at', 'created_at']
    list_filter = ['is_used']
    search_fields = ['phone']
    readonly_fields = ['created_at']
