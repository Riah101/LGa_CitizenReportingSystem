import django_filters
from .models import Complaint, ComplaintStatus, ComplaintCategory, GovernmentLevel


class ComplaintFilter(django_filters.FilterSet):
    status = django_filters.MultipleChoiceFilter(choices=ComplaintStatus.choices)
    category = django_filters.MultipleChoiceFilter(choices=ComplaintCategory.choices)
    current_level = django_filters.MultipleChoiceFilter(choices=GovernmentLevel.choices)
    region = django_filters.CharFilter(lookup_expr='iexact')
    district = django_filters.CharFilter(lookup_expr='iexact')
    ward = django_filters.CharFilter(lookup_expr='iexact')
    mtaa = django_filters.CharFilter(lookup_expr='icontains')
    is_urgent = django_filters.BooleanFilter()
    is_anonymous = django_filters.BooleanFilter()
    submitted_after = django_filters.DateFilter(field_name='submitted_at', lookup_expr='gte')
    submitted_before = django_filters.DateFilter(field_name='submitted_at', lookup_expr='lte')
    min_upvotes = django_filters.NumberFilter(field_name='upvotes', lookup_expr='gte')

    class Meta:
        model = Complaint
        fields = [
            'status', 'category', 'current_level',
            'region', 'district', 'ward', 'mtaa',
            'is_urgent', 'is_anonymous',
            'submitted_after', 'submitted_before',
            'min_upvotes',
        ]
