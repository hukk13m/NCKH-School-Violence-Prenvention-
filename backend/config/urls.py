"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
"""
from django.contrib import admin
from django.urls import path, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render
from django.views.static import serve
from cases.views import dashboard_stats, api_create_case, api_list_cases, api_update_case_status
from users.views import api_login, api_register

FLUTTER_WEB_DIR = settings.BASE_DIR.parent / 'front-end' / 'build' / 'web'

def serve_flutter_web(request, path=''):
    file_path = FLUTTER_WEB_DIR / path
    if path and file_path.exists() and file_path.is_file():
        response = serve(request, path, document_root=FLUTTER_WEB_DIR)
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'
        return response
    response = render(request, 'index.html')
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'
    return response

# Override default pagination for all tables
admin.ModelAdmin.list_per_page = 50

from django.views.generic.base import RedirectView

urlpatterns = [
    # Tự động chuyển hướng /admin sang /admin/
    path('admin', RedirectView.as_view(url='/admin/', permanent=False)),
    path('admin/dashboard_stats/', dashboard_stats, name='dashboard_stats'),
    path('admin/', admin.site.urls),
    
    # REST API endpoints kết nối với Flutter client
    path('api/users/login/', api_login, name='api_login'),
    path('api/users/register/', api_register, name='api_register'),
    path('api/cases/create/', api_create_case, name='api_create_case'),
    path('api/cases/list/', api_list_cases, name='api_list_cases'),
    path('api/cases/<int:case_id>/status/', api_update_case_status, name='api_update_case_status'),

    # Phục vụ mọi file tĩnh của Flutter Web và fallback về index.html (loại trừ admin và api)
    re_path(r'^(?!(admin|api))(?P<path>.*)$', serve_flutter_web, name='flutter_web'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
