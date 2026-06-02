from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Complaint, ComplaintAttachment, EscalationHistory,
    Comment, ComplaintUpvote, StatusUpdate
)


class AttachmentInline(admin.TabularInline):
    model = ComplaintAttachment
    extra = 0
    readonly_fields = ['uploaded_at', 'uploaded_by']


class EscalationHistoryInline(admin.TabularInline):
    model = EscalationHistory
    extra = 0
    readonly_fields = ['from_level', 'to_level', 'reason', 'escalated_by', 'escalated_at']
    can_delete = False


class CommentInline(admin.TabularInline):
    model = Comment
    extra = 0
    readonly_fields = ['author', 'created_at']


class StatusUpdateInline(admin.TabularInline):
    model = StatusUpdate
    extra = 0
    readonly_fields = ['from_status', 'to_status', 'updated_by', 'updated_at']
    can_delete = False


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = [
        'tracking_code', 'title', 'citizen_name', 'category',
        'colored_status', 'current_level', 'region', 'district',
        'is_urgent', 'upvotes', 'days_remaining', 'submitted_at'
    ]
    list_filter = ['status', 'current_level', 'category', 'is_urgent', 'region', 'is_anonymous']
    search_fields = ['tracking_code', 'title', 'description', 'citizen__full_name', 'citizen__phone']
    readonly_fields = [
        'id', 'tracking_code', 'submitted_at', 'updated_at',
        'last_action_at', 'view_count', 'upvotes', 'priority_score'
    ]
    ordering = ['-submitted_at']
    date_hierarchy = 'submitted_at'
    inlines = [AttachmentInline, EscalationHistoryInline, CommentInline, StatusUpdateInline]

    fieldsets = (
        ('Complaint Info', {
            'fields': ('id', 'tracking_code', 'citizen', 'is_anonymous', 'title', 'description', 'category')
        }),
        ('Status & Level', {
            'fields': ('status', 'current_level', 'is_urgent')
        }),
        ('Location', {
            'fields': ('mtaa', 'ward', 'district', 'region', 'latitude', 'longitude')
        }),
        ('Metrics', {
            'fields': ('upvotes', 'view_count', 'priority_score')
        }),
        ('Timestamps', {
            'fields': ('submitted_at', 'updated_at', 'last_action_at', 'resolved_at')
        }),
    )

    actions = ['mark_in_progress', 'mark_resolved', 'escalate_selected']

    def citizen_name(self, obj):
        if obj.is_anonymous:
            return 'Anonymous'
        return obj.citizen.full_name
    citizen_name.short_description = 'Citizen'

    def colored_status(self, obj):
        colors = {
            'pending': '#FF8F00',
            'in_progress': '#1565C0',
            'escalated': '#D32F2F',
            'resolved': '#2E7D32',
            'closed': '#757575',
        }
        color = colors.get(obj.status, '#000')
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display(),
        )
    colored_status.short_description = 'Status'

    def days_remaining(self, obj):
        days = obj.days_until_escalation
        if days == -1:
            return '∞'
        if days <= 2:
            return format_html('<span style="color: red; font-weight: bold;">{} days</span>', days)
        return f'{days} days'
    days_remaining.short_description = 'Escalation In'

    def mark_in_progress(self, request, queryset):
        for c in queryset:
            c.mark_in_progress()
        self.message_user(request, f'{queryset.count()} complaints marked as in progress.')
    mark_in_progress.short_description = 'Mark as In Progress'

    def mark_resolved(self, request, queryset):
        for c in queryset:
            c.resolve(resolved_by=request.user)
        self.message_user(request, f'{queryset.count()} complaints resolved.')
    mark_resolved.short_description = 'Mark as Resolved'

    def escalate_selected(self, request, queryset):
        count = 0
        for c in queryset:
            if c.next_level:
                c.escalate(reason='Manually escalated via admin', escalated_by=request.user)
                count += 1
        self.message_user(request, f'{count} complaints escalated.')
    escalate_selected.short_description = 'Escalate to next level'


@admin.register(EscalationHistory)
class EscalationHistoryAdmin(admin.ModelAdmin):
    list_display = ['complaint', 'from_level', 'to_level', 'escalated_by', 'escalated_at']
    list_filter = ['from_level', 'to_level']
    readonly_fields = ['id', 'escalated_at']


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ['complaint', 'author', 'is_official', 'is_internal', 'created_at']
    list_filter = ['is_official', 'is_internal']
    search_fields = ['content', 'author__full_name']
