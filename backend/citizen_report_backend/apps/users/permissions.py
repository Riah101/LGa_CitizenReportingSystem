from rest_framework.permissions import BasePermission, SAFE_METHODS
from django.contrib.auth import get_user_model

User = get_user_model()


class IsAdminOrSelf(BasePermission):
    """Allow admin or the user themselves."""
    def has_object_permission(self, request, view, obj):
        return request.user.is_staff or obj == request.user


class IsOfficerOrAdmin(BasePermission):
    """Allow only officers and admins."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and (
            request.user.is_officer or request.user.is_staff
        )


class IsComplaintOwnerOrOfficer(BasePermission):
    """Allow complaint owner, relevant officers, or admin."""
    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.is_staff:
            return True
        if obj.citizen == user:
            return True
        if user.is_officer:
            # Officer can only access complaints at their level
            level = user.jurisdiction_level
            if level == 'national':
                return True
            if level == 'region' and obj.region == user.region:
                return True
            if level == 'district' and obj.district == user.district:
                return True
            if level == 'ward' and obj.ward == user.ward:
                return True
            if level == 'mtaa' and obj.mtaa == user.mtaa:
                return True
        return False


class IsOfficerForLevel(BasePermission):
    """Only officers managing the complaint's current level."""
    def has_object_permission(self, request, view, obj):
        user = request.user
        if user.is_staff:
            return True
        if not user.is_officer:
            return False
        level = user.jurisdiction_level
        current = obj.current_level
        if level == 'national':
            return True
        if level == current:
            location_map = {
                'region': (obj.region, user.region),
                'district': (obj.district, user.district),
                'ward': (obj.ward, user.ward),
                'mtaa': (obj.mtaa, user.mtaa),
            }
            complaint_loc, officer_loc = location_map.get(level, (None, None))
            return complaint_loc == officer_loc
        return False


class ReadOnly(BasePermission):
    def has_permission(self, request, view):
        return request.method in SAFE_METHODS
