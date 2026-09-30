import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from users.models import User
from cases.models import Case, Evidence, CaseHistory, Assignment
from ai_engine.models import AIResult
from communications.models import Notification, ChatRoom, ChatRoomMember, Message

print("Clearing old cases to avoid duplicates...")
Case.objects.all().delete()
Notification.objects.all().delete()
ChatRoom.objects.all().delete()

students = list(User.objects.filter(role__role_name='Student'))
teachers = list(User.objects.filter(role__role_name='Teacher'))
admin_user = User.objects.filter(username='admin').first() or User.objects.first()

incident_types = ['Bullying', 'Cyberbullying', 'Verbal Abuse', 'Physical Violence', 'Social Isolation']
priorities = ['Low', 'Medium', 'High', 'Critical']
statuses = ['New', 'In Progress', 'Resolved', 'Closed']
locations = ['School Yard', 'Classroom', 'Cafeteria', 'Parking Lot', 'Social Media', 'Dormitory']

print("Generating 10 new cases with full relational data in English...")
for i in range(1, 11):
    reporter = random.choice(students)
    status = random.choice(statuses)
    priority = random.choice(priorities)
    inc_type = random.choice(incident_types)
    
    # 1. Create Case
    c = Case.objects.create(
        reporter=reporter,
        report_type='Mobile App',
        incident_type=inc_type,
        priority=priority,
        location=random.choice(locations),
        description=f"This is report #{i} regarding an incident of {inc_type.lower()}. The conflict occurred due to a personal misunderstanding.",
        solution="Contacted the homeroom teacher and parents to mediate the situation." if status in ['Resolved', 'Closed'] else "",
        status=status
    )
    
    # 2. Create Evidence
    Evidence.objects.create(
        case=c,
        uploader=reporter,
        file_type='Image',
        file_name=f"evidence_{i}_screenshot.png",
        description="Screenshot of threatening messages" if "cyber" in inc_type.lower() else "Photo of the physical injury"
    )
    
    # 3. Create CaseHistory
    CaseHistory.objects.create(case=c, actor=reporter, action="Created Case", description="User submitted a new report.")
    if status != 'New':
        CaseHistory.objects.create(case=c, actor=admin_user, action=f"Changed status to {status}", description="Admin updated the case status.")
        
    # 4. Create Assignment
    if teachers:
        assignee = random.choice(teachers)
        Assignment.objects.create(
            case=c,
            assignee=assignee,
            assigned_by=admin_user,
            status="Completed" if status in ['Resolved', 'Closed'] else "Pending"
        )
    
    # 5. Create AIResult
    risk = round(random.uniform(0.2, 0.95), 2)
    AIResult.objects.create(
        case=c,
        risk_score=risk,
        recommendation="High priority alert! Immediate intervention from the Student Affairs Office is required." if risk > 0.7 else "Monitor the situation and remind the students."
    )
    
    # 6. Create ChatRoom
    room = ChatRoom.objects.create(
        case=c,
        room_name=f"Discussion Room for Case #{c.id}",
        room_type="Private",
        status="Active"
    )
    
    # 7. Create ChatRoomMembers
    ChatRoomMember.objects.create(chat_room=room, user=reporter)
    if teachers:
        ChatRoomMember.objects.create(chat_room=room, user=assignee)
    
    # 8. Create Messages
    Message.objects.create(chat_room=room, sender=reporter, content="Hello teacher, please help me resolve this issue.")
    if teachers:
        Message.objects.create(chat_room=room, sender=assignee, content="Hello, I have received the information and will process it shortly.")
    
    # 9. Create Notifications
    if teachers:
        Notification.objects.create(
            case=c,
            user=reporter,
            notification_type="System",
            content=f"Your report (Case #{c.id}) has been assigned to teacher {assignee.get_full_name()}."
        )

print("Full mock data translated and generated successfully!")
