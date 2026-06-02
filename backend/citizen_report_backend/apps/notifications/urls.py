from django.urls import path
from .views import (
    NotificationListView,
    mark_read,
    mark_all_read,
    unread_count,
    clear_all,
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification_list'),
    path('unread-count/', unread_count, name='notification_unread_count'),
    path('mark-all-read/', mark_all_read, name='notification_mark_all_read'),
    path('clear/', clear_all, name='notification_clear'),
    path('<uuid:pk>/read/', mark_read, name='notification_read'),
]
