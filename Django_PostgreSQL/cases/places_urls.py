from django.urls import path

from .places import autocomplete, detail, reverse

urlpatterns = [
    path('autocomplete', autocomplete, name='places_autocomplete'),
    path('detail', detail, name='places_detail'),
    path('reverse', reverse, name='places_reverse'),
]
