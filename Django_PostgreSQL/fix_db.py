import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'cases_case';
    """)
    columns = [row[0] for row in cursor.fetchall()]
    print('Columns in cases_case:', columns)

    if 'reporter_id' not in columns:
        print('Adding missing column reporter_id to cases_case...')
        cursor.execute("""
            ALTER TABLE cases_case
            ADD COLUMN reporter_id bigint NULL REFERENCES users_user(id) ON DELETE SET NULL;
        """)
        print('Column reporter_id successfully added!')
    else:
        print('reporter_id already exists!')
