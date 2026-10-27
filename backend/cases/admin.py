from django.contrib import admin
from .models import Case, Evidence, CaseHistory, Assignment

class EvidenceInline(admin.TabularInline):
    model = Evidence
    extra = 1

@admin.register(Case)
class CaseAdmin(admin.ModelAdmin):
    list_display = ('id', 'incident_type', 'priority', 'status', 'created_at', 'report_id')
    list_filter = ('status', 'priority', 'incident_type')
    search_fields = ('description', 'incident_type', 'location')
    date_hierarchy = 'created_at'
    inlines = [EvidenceInline]

admin.site.register(CaseHistory)
admin.site.register(Assignment)
