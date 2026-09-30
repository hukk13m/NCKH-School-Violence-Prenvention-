from django.db import models
from cases.models import Case
from users.models import User

class Notification(models.Model):
    case = models.ForeignKey(Case, on_delete=models.CASCADE, related_name='notifications', null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=50)
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self): return f"Notification for {self.user.username}"

class ChatRoom(models.Model):
    case = models.OneToOneField(Case, on_delete=models.CASCADE, related_name='chat_room')
    room_name = models.CharField(max_length=255)
    room_type = models.CharField(max_length=50)
    status = models.CharField(max_length=50, default='Active')
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self): return self.room_name

class ChatRoomMember(models.Model):
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='chat_rooms')
    joined_at = models.DateTimeField(auto_now_add=True)
    left_at = models.DateTimeField(null=True, blank=True)

class Message(models.Model):
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    content = models.TextField()
    attachment_url = models.FileField(upload_to='chat_attachments/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    edited_at = models.DateTimeField(null=True, blank=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    def __str__(self): return f"Message from {self.sender} in {self.chat_room}"
