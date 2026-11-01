from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0003_alter_assignment_options_alter_case_options_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='case',
            name='location',
            field=models.CharField(blank=True, max_length=500, null=True),
        ),
        migrations.AddField(
            model_name='case',
            name='latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='case',
            name='longitude',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
