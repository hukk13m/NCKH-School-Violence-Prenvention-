from rest_framework import serializers
from .models import Case, Evidence
from users.models import User

class EvidenceSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Evidence
        fields = ['id', 'file_name', 'file_type', 'file_url']

    def get_file_url(self, obj):
        if obj.file_url:
            return obj.file_url.url
        return ''

class CaseSerializer(serializers.ModelSerializer):
    evidences = EvidenceSerializer(many=True, read_only=True)
    created_at = serializers.DateTimeField(format='%Y-%m-%d %H:%M:%S', read_only=True)
    reporter_name = serializers.SerializerMethodField()
    reporter_id = serializers.SerializerMethodField()
    risk_score = serializers.SerializerMethodField()
    ai_recommendation = serializers.SerializerMethodField()
    is_anonymous = serializers.SerializerMethodField()

    class Meta:
        model = Case
        fields = [
            'id', 'report_type', 'incident_type', 'priority',
            'location', 'description', 'status', 'created_at',
            'reporter_name', 'reporter_id', 'risk_score',
            'ai_recommendation', 'is_anonymous', 'evidences'
        ]

    def get_reporter_name(self, obj):
        if obj.report_id:
            return obj.report_id.full_name or obj.report_id.username
        return 'Ẩn danh'

    def get_reporter_id(self, obj):
        if obj.report_id:
            return obj.report_id.username
        return ''

    def get_risk_score(self, obj):
        if hasattr(obj, 'ai_result') and obj.ai_result and obj.ai_result.risk_score is not None:
            return round(float(obj.ai_result.risk_score), 2)
        priority_map = {'Critical': 0.88, 'High': 0.72, 'Medium': 0.50, 'Low': 0.25}
        return priority_map.get(obj.priority, 0.45)

    def get_ai_recommendation(self, obj):
        if hasattr(obj, 'ai_result') and obj.ai_result and obj.ai_result.recommendation:
            return obj.ai_result.recommendation
        return 'Cần theo dõi và xác minh thông tin sự việc.'

    def get_is_anonymous(self, obj):
        return obj.report_type == 'Anonymous' or not obj.report_id
