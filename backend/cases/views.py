from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Count, Q
from django.contrib.admin.views.decorators import staff_member_required
from django.http import JsonResponse
from .models import Case, Evidence
from .serializers import CaseSerializer, EvidenceSerializer
from users.models import User

@staff_member_required
def dashboard_stats(request):
    start_date = request.GET.get('start')
    end_date = request.GET.get('end')

    qs = Case.objects.all()
    if start_date:
        qs = qs.filter(created_at__gte=start_date)
    if end_date:
        qs = qs.filter(created_at__lte=end_date + " 23:59:59")

    priority_data = list(qs.values('priority').annotate(count=Count('id')))
    status_data = list(qs.values('status').annotate(count=Count('id')))
    
    return JsonResponse({
        'priority': priority_data,
        'status': status_data,
        'total': qs.count()
    })

@csrf_exempt
@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def api_create_case(request):
    try:
        description = request.data.get('description', '')
        location = request.data.get('location', '')
        report_type = request.data.get('report_type', 'Report')
        incident_type = request.data.get('incident_type', 'Vi phạm quy chế')
        priority = request.data.get('priority', 'Normal')
        user_id = request.data.get('user_id')

        user_obj = None
        if user_id:
            if str(user_id).isdigit():
                user_obj = User.objects.filter(id=int(user_id)).first()
            else:
                user_obj = User.objects.filter(username=user_id).first()

        new_case = Case.objects.create(
            report_id=user_obj,
            description=description,
            location=location,
            report_type=report_type,
            incident_type=incident_type,
            priority=priority,
            status='New'
        )

        for file in request.FILES.getlist('files'):
            Evidence.objects.create(
                case=new_case,
                user=user_obj,
                file_name=file.name,
                file_type=file.content_type,
                file_url=file
            )

        serializer = CaseSerializer(new_case)
        return Response({
            'message': 'Báo cáo thành công',
            'case': serializer.data
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def api_list_cases(request):
    try:
        user_id = request.query_params.get('user_id', '').strip()
        role = request.query_params.get('role', '').lower().strip()

        qs = Case.objects.all().select_related('report_id', 'ai_result').prefetch_related('evidences', 'assignments__assignee').order_by('-created_at')

        user_obj = None
        if user_id:
            if str(user_id).isdigit():
                user_obj = User.objects.filter(id=int(user_id)).first()
            if not user_obj:
                user_obj = User.objects.filter(
                    Q(username__iexact=user_id) | Q(email__iexact=user_id)
                ).first()

        # Kiem tra neu user la Admin hoac Superuser -> Xem toan bo 100% case
        is_admin_user = (role == 'admin') or (
            user_obj and (
                user_obj.is_superuser or 
                user_obj.is_staff or 
                (user_obj.role and 'admin' in user_obj.role.role_name.lower())
            )
        )

        if is_admin_user:
            # Admin toan quyen xem toan bo du lieu
            pass
        elif role == 'teacher' or (user_obj and user_obj.role and 'teacher' in user_obj.role.role_name.lower()):
            # Giang vien: Xem case duoc phan cong, ca do minh bao cao, va ca cua lop minh chu nhiem (Advisor)
            if user_obj:
                if user_obj.student_class:
                    qs = qs.filter(
                        Q(assignments__assignee=user_obj) | 
                        Q(report_id=user_obj) |
                        Q(report_id__student_class=user_obj.student_class)
                    ).distinct()
                else:
                    qs = qs.filter(
                        Q(assignments__assignee=user_obj) | 
                        Q(report_id=user_obj)
                    ).distinct()
            elif user_id:
                qs = qs.filter(
                    Q(assignments__assignee__username__iexact=user_id) |
                    Q(assignments__assignee__email__iexact=user_id) |
                    Q(report_id__username__iexact=user_id) |
                    Q(report_id__email__iexact=user_id)
                ).distinct()
        elif role == 'student':
            # Sinh vien: Chi xem case do minh bao cao
            if user_obj:
                qs = qs.filter(report_id=user_obj)
            elif user_id:
                qs = qs.filter(
                    Q(report_id__username__iexact=user_id) |
                    Q(report_id__email__iexact=user_id)
                )
        else:
            if user_obj:
                if user_obj.role and 'teacher' in user_obj.role.role_name.lower():
                    qs = qs.filter(
                        Q(assignments__assignee=user_obj) | Q(report_id=user_obj)
                    ).distinct()
                elif user_obj.role and 'student' in user_obj.role.role_name.lower():
                    qs = qs.filter(report_id=user_obj)
                elif user_obj.is_staff or (user_obj.role and 'admin' in user_obj.role.role_name.lower()):
                    pass
                else:
                    qs = qs.filter(Q(assignments__assignee=user_obj) | Q(report_id=user_obj)).distinct()

        serializer = CaseSerializer(qs, many=True)
        return Response({'cases': serializer.data}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@csrf_exempt
@api_view(['POST', 'PATCH'])
@authentication_classes([])
@permission_classes([AllowAny])
def api_update_case_status(request, case_id):
    try:
        new_status = request.data.get('status')
        if not new_status:
            return Response({'error': 'Trường status là bắt buộc'}, status=status.HTTP_400_BAD_REQUEST)
        
        case = Case.objects.filter(id=case_id).first()
        if not case:
            return Response({'error': 'Không tìm thấy hồ sơ vụ việc'}, status=status.HTTP_404_NOT_FOUND)
            
        case.status = new_status
        case.save(update_fields=['status'])
        return Response({'message': 'Cập nhật trạng thái thành công', 'id': case.id, 'status': case.status}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
