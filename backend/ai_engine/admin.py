from django.contrib import admin
from .models import AIResult, Audit

@admin.register(AIResult)
class AIResultAdmin(admin.ModelAdmin):
    list_display = ('case', 'risk_score', 'created_at')
    list_filter = ('risk_score',)

@admin.register(Audit)
class AuditAdmin(admin.ModelAdmin):
    list_display = ('ai_result', 'user', 'audit_result', 'reviewed_at')
    list_filter = ('audit_result',)
