from django.urls import path
from apps.users.views.user_views import (
    UserProfileView,
    UserListView,
    UserDetailView,
    upload_profile_photo,
    user_stats,
)

urlpatterns = [
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('profile/photo/', upload_profile_photo, name='upload_photo'),
    path('stats/', user_stats, name='user_stats'),
    path('', UserListView.as_view(), name='user_list'),           # Admin only
    path('<uuid:pk>/', UserDetailView.as_view(), name='user_detail'),  # Admin only
]
