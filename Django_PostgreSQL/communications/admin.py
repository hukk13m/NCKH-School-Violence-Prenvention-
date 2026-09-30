from django.contrib import admin
from .models import Notification, ChatRoom, ChatRoomMember, Message

admin.site.register(Notification)
admin.site.register(ChatRoom)
admin.site.register(ChatRoomMember)
admin.site.register(Message)
