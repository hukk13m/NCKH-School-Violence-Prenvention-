from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register_api, name='api_register'),
    path('login/', views.login_api, name='api_login'),
]
