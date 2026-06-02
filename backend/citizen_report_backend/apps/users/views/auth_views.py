from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema, OpenApiExample

from .serializers import (
    UserRegisterSerializer,
    UserSerializer,
    CustomTokenObtainPairSerializer,
    OTPRequestSerializer,
    OTPVerifySerializer,
    ChangePasswordSerializer,
)

User = get_user_model()


class LoginView(TokenObtainPairView):
    """
    Login with phone + password.
    Returns JWT access/refresh tokens + user profile.
    """
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [AllowAny]


class RegisterView(generics.CreateAPIView):
    """Register a new citizen account."""
    serializer_class = UserRegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Auto-generate tokens on register
        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'message': 'Registration successful. Please verify your phone number.',
        }, status=status.HTTP_201_CREATED)


@extend_schema(tags=['auth'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Blacklist refresh token on logout."""
    try:
        refresh_token = request.data.get('refresh')
        token = RefreshToken(refresh_token)
        token.blacklist()
        return Response({'message': 'Logged out successfully.'})
    except Exception:
        return Response({'error': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(tags=['auth'])
@api_view(['POST'])
@permission_classes([AllowAny])
def request_otp(request):
    """Request OTP for phone verification."""
    serializer = OTPRequestSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    otp = serializer.create_otp()

    # In production: send via Africa's Talking SMS
    # For dev: return in response
    response_data = {'message': f'OTP sent to {otp.phone}'}
    if request.user.is_staff or True:  # Remove True in production
        response_data['dev_code'] = otp.code

    return Response(response_data)


@extend_schema(tags=['auth'])
@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """Verify OTP and mark phone as verified."""
    serializer = OTPVerifySerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    otp = serializer.validated_data['otp']
    phone = serializer.validated_data['phone']

    otp.is_used = True
    otp.save()

    # Mark user as verified
    User.objects.filter(phone=phone).update(is_verified=True)

    return Response({'message': 'Phone verified successfully.', 'verified': True})


@extend_schema(tags=['auth'])
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """Change user password."""
    serializer = ChangePasswordSerializer(
        data=request.data, context={'request': request}
    )
    serializer.is_valid(raise_exception=True)
    request.user.set_password(serializer.validated_data['new_password'])
    request.user.save()
    return Response({'message': 'Password changed successfully.'})


@extend_schema(tags=['auth'])
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """Get current authenticated user profile."""
    return Response(UserSerializer(request.user).data)
