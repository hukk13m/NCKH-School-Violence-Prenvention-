import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import get_user_model
from .models import Role

User = get_user_model()

@csrf_exempt
def register_api(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        data = json.loads(request.body)
        email = data.get('email', '').strip()
        password = data.get('password', '')
        full_name = data.get('fullName', '').strip()
        role_str = str(data.get('role', 'student')).lower()

        if not email or not password:
            return JsonResponse({'error': 'Email and password are required'}, status=400)

        if User.objects.filter(username=email).exists() or User.objects.filter(email=email).exists():
            return JsonResponse({'error': 'Email already registered'}, status=400)

        # Match Role in DB ('Student' or 'Teacher')
        db_role_name = 'Teacher' if 'teacher' in role_str else 'Student'
        role_obj, _ = Role.objects.get_or_create(role_name=db_role_name)

        name_parts = full_name.split(' ', 1)
        first_name = name_parts[0] if name_parts else ''
        last_name = name_parts[1] if len(name_parts) > 1 else ''

        user = User.objects.create_user(
            username=email,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            role=role_obj
        )

        return JsonResponse({
            'status': 'success',
            'userId': str(user.id),
            'requiresEmailVerification': False
        }, status=201)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def login_api(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)

    try:
        data = json.loads(request.body)
        email = data.get('email', '').strip()
        password = data.get('password', '')

        if not email or not password:
            return JsonResponse({'error': 'Email and password are required'}, status=400)

        user = User.objects.filter(email=email).first() or User.objects.filter(username=email).first()

        if user is None or not user.check_password(password):
            return JsonResponse({'error': 'Invalid email or password'}, status=400)

        user_role = 'student'
        if user.role and 'teacher' in user.role.role_name.lower():
            user_role = 'teacher'

        return JsonResponse({
            'status': 'success',
            'userId': str(user.id),
            'fullName': user.get_full_name() or user.username,
            'email': user.email or email,
            'role': user_role,
            'accessToken': f'token_{user.id}',
            'refreshToken': f'refresh_{user.id}'
        })

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
