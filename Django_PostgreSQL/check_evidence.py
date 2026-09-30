import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection
from cases.models import Evidence

with connection.cursor() as cursor:
    cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'cases_evidence';")
    print('cases_evidence columns:', [row[0] for row in cursor.fetchall()])

print('Current count of evidence in DB:', Evidence.objects.count())
