from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.views.decorators.csrf import csrf_exempt
from .models import User, Role

@csrf_exempt
@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def api_login(request):
    try:
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')
        
        user = User.objects.filter(email=email).first()
        if not user:
            user = User.objects.filter(username=email).first()
            
        if user and user.check_password(password):
            role_raw = user.role.role_name.lower() if user.role else 'student'
            if 'admin' in role_raw or 'quản trị' in role_raw or user.is_superuser:
                role_out = 'admin'
            elif any(r in role_raw for r in ['teacher', 'giảng viên', 'cố vấn', 'counselor', 'student affairs']):
                role_out = 'teacher'
            else:
                role_out = 'student'

            # Bắt buộc khớp vai trò theo Tab đăng nhập đã chọn
            requested_role = request.data.get('role', '').lower().strip()
            if requested_role == 'teacher' and role_out == 'student':
                return Response({
                    'error': 'Tài khoản này là Sinh viên. Vui lòng chuyển sang tab Sinh viên để đăng nhập.'
                }, status=status.HTTP_403_FORBIDDEN)
            elif requested_role == 'student' and role_out in ['teacher', 'admin']:
                return Response({
                    'error': 'Tài khoản này là Cán bộ / Giảng viên. Vui lòng chuyển sang tab Giảng viên để đăng nhập.'
                }, status=status.HTTP_403_FORBIDDEN)

            dept_name = user.department.department_name if user.department else 'Khoa Công nghệ Thông tin'
            class_name = user.student_class.class_name if user.student_class else ''
            return Response({
                'userId': str(user.id),
                'fullName': user.full_name or f"{user.first_name} {user.last_name}".strip() or user.username,
                'email': user.email or user.username,
                'role': role_out,
                'department': dept_name,
                'studentClass': class_name,
                'accessToken': 'token-12345',
                'refreshToken': 'refresh-12345'
            }, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Tài khoản hoặc mật khẩu không chính xác'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def api_register(request):
    try:
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')
        full_name = request.data.get('fullName', '')
        role_str = request.data.get('role', 'student')
        
        if User.objects.filter(username=email).exists() or User.objects.filter(email=email).exists():
            return Response({'error': 'Email đã tồn tại'}, status=status.HTTP_400_BAD_REQUEST)
        
        role_obj, _ = Role.objects.get_or_create(role_name='Teacher' if role_str == 'teacher' else 'Student')
        
        user = User.objects.create_user(
            username=email,
            email=email,
            password=password,
            full_name=full_name,
            role=role_obj
        )
        
        return Response({
            'userId': str(user.id),
            'message': 'Đăng ký thành công'
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
