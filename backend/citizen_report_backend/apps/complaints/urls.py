from django.urls import path
from .views import (
    ComplaintListCreateView,
    ComplaintDetailView,
    DashboardStatsView,
    PublicComplaintsView,
    track_complaint,
    escalate_complaint,
    resolve_complaint,
    upvote_complaint,
    add_comment,
    upload_attachment,
)

urlpatterns = [
    # Core CRUD
    path('', ComplaintListCreateView.as_view(), name='complaint_list_create'),
    path('<uuid:pk>/', ComplaintDetailView.as_view(), name='complaint_detail'),

    # Actions
    path('<uuid:pk>/escalate/', escalate_complaint, name='complaint_escalate'),
    path('<uuid:pk>/resolve/', resolve_complaint, name='complaint_resolve'),
    path('<uuid:pk>/upvote/', upvote_complaint, name='complaint_upvote'),
    path('<uuid:pk>/comment/', add_comment, name='complaint_comment'),
    path('<uuid:pk>/attachment/', upload_attachment, name='complaint_attachment'),

    # Public & Tracking
    path('track/', track_complaint, name='complaint_track'),
    path('public/', PublicComplaintsView.as_view(), name='complaint_public'),

    # Stats
    path('stats/', DashboardStatsView.as_view(), name='complaint_stats'),
]
