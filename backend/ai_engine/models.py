from django.db import models
from cases.models import Case
from users.models import User

class AIResult(models.Model):
    case = models.OneToOneField(Case, on_delete=models.CASCADE, related_name='ai_result')
    risk_score = models.FloatField()
    recommendation = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self): return f"AI Result for Case #{self.case.id}"

class Audit(models.Model):
    ai_result = models.ForeignKey(AIResult, on_delete=models.CASCADE, related_name='audits')
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    reviewed_at = models.DateTimeField(auto_now_add=True)
    audit_result = models.CharField(max_length=50)
    comment = models.TextField(blank=True, null=True)
    def __str__(self): return f"Audit for AIResult #{self.ai_result.id}"
