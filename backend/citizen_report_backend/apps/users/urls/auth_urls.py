from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.users.views.auth_views import (
    LoginView,
    RegisterView,
    logout_view,
    request_otp,
    verify_otp,
    change_password,
    me,
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('logout/', logout_view, name='logout'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('otp/request/', request_otp, name='otp_request'),
    path('otp/verify/', verify_otp, name='otp_verify'),
    path('change-password/', change_password, name='change_password'),
    path('me/', me, name='me'),
]
