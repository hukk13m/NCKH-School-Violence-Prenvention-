from django.db import models
from django.contrib.auth.models import AbstractUser

class Role(models.Model):
    role_name = models.CharField(max_length=50, unique=True)
    class Meta:
        verbose_name_plural = "Roles"
    def __str__(self): return self.role_name

class Department(models.Model):
    department_name = models.CharField(max_length=100)
    class Meta:
        verbose_name_plural = "​Departments"
    def __str__(self): return self.department_name

class Class(models.Model):
    class_name = models.CharField(max_length=50)
    class Meta:
        verbose_name_plural = "​​Class"
    def __str__(self): return self.class_name

class User(AbstractUser):
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, blank=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True)
    student_class = models.ForeignKey(Class, on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=20, default='active')
    class Meta:
        verbose_name_plural = "​​​Users"
    def __str__(self): return f"{self.username} ({self.get_full_name()})"
