from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import random

from .models import OTPCode

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'phone', 'email', 'full_name', 'national_id',
            'role', 'mtaa', 'ward', 'district', 'region',
            'is_verified', 'preferred_language', 'profile_photo',
            'total_complaints', 'resolved_complaints', 'created_at',
        ]
        read_only_fields = [
            'id', 'role', 'is_verified', 'total_complaints',
            'resolved_complaints', 'created_at',
        ]


class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'phone', 'full_name', 'password', 'confirm_password',
            'email', 'national_id', 'mtaa', 'ward', 'district',
            'region', 'preferred_language',
        ]

    def validate_phone(self, value):
        # Normalize Tanzania numbers
        value = value.strip().replace(' ', '')
        if not value.startswith('+'):
            if value.startswith('0'):
                value = '+255' + value[1:]
            elif value.startswith('255'):
                value = '+' + value
        if User.objects.filter(phone=value).exists():
            raise serializers.ValidationError('A user with this phone number already exists.')
        return value

    def validate(self, data):
        if data['password'] != data.pop('confirm_password'):
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Add user data to login response."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['phone'] = user.phone
        token['full_name'] = user.full_name
        token['role'] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        return data


class OTPRequestSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        value = value.strip().replace(' ', '')
        if value.startswith('0'):
            value = '+255' + value[1:]
        elif value.startswith('255'):
            value = '+' + value
        return value

    def create_otp(self):
        phone = self.validated_data['phone']
        code = str(random.randint(100000, 999999))
        expires_at = timezone.now() + timedelta(minutes=10)
        OTPCode.objects.filter(phone=phone, is_used=False).update(is_used=True)
        otp = OTPCode.objects.create(phone=phone, code=code, expires_at=expires_at)
        return otp


class OTPVerifySerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=6)

    def validate(self, data):
        phone = data['phone']
        code = data['code']
        try:
            otp = OTPCode.objects.get(phone=phone, code=code, is_used=False)
            if not otp.is_valid():
                raise serializers.ValidationError({'code': 'OTP has expired.'})
            data['otp'] = otp
        except OTPCode.DoesNotExist:
            raise serializers.ValidationError({'code': 'Invalid OTP code.'})
        return data


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return data

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value
