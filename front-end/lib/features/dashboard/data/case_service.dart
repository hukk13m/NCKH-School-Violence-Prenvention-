import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';

class CaseModel {
  final int id;
  final String reportType;
  final String incidentType;
  final String priority;
  final String location;
  final String description;
  final String status;
  final String createdAt;
  final String reporterName;
  final String reporterId;
  final double riskScore;
  final String aiRecommendation;
  final bool isAnonymous;
  final List<EvidenceModel> evidences;

  CaseModel({
    required this.id,
    required this.reportType,
    required this.incidentType,
    required this.priority,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reporterName = 'Ẩn danh',
    this.reporterId = '',
    this.riskScore = 0.5,
    this.aiRecommendation = '',
    this.isAnonymous = false,
    required this.evidences,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as int? ?? 0,
      reportType: json['report_type'] as String? ?? 'Report',
      incidentType: json['incident_type'] as String? ?? 'Vi phạm',
      priority: json['priority'] as String? ?? 'Normal',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'New',
      createdAt: json['created_at'] as String? ?? '',
      reporterName: json['reporter_name'] as String? ?? 'Ẩn danh',
      reporterId: json['reporter_id'] as String? ?? '',
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.45,
      aiRecommendation: json['ai_recommendation'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map((e) => EvidenceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EvidenceModel {
  final int id;
  final String fileName;
  final String fileType;
  final String fileUrl;

  EvidenceModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as int? ?? 0,
      fileName: json['file_name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
    );
  }
}

class CaseService {
  final String baseUrl;

  CaseService({String? baseUrl})
      : baseUrl = baseUrl ?? '${ApiEndpoints.baseUrl}/api/cases';

  Future<CaseModel> submitReport({
    required String description,
    required String location,
    required String reportType,
    String incidentType = 'Vi phạm quy chế',
    required String priority,
    String? userId,
    List<UploadedFile> files = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/create/');
    final request = http.MultipartRequest('POST', uri);

    request.fields['description'] = description;
    request.fields['location'] = location;
    request.fields['report_type'] = reportType;
    request.fields['incident_type'] = incidentType;
    request.fields['priority'] = priority;
    if (userId != null && userId.isNotEmpty) {
      request.fields['user_id'] = userId;
    }

    for (final file in files) {
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'files',
          file.path!,
          filename: file.name,
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final caseJson = data['case'] as Map<String, dynamic>;
      return CaseModel.fromJson(caseJson);
    } else {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMsg = data['error'] as String? ?? 'Gửi báo cáo thất bại';
      throw Exception(errorMsg);
    }
  }

  Future<List<CaseModel>> fetchCases({String? userId, String? role}) async {
    final params = <String, String>{};
    if (userId != null && userId.isNotEmpty) params['user_id'] = userId;
    if (role != null && role.isNotEmpty) params['role'] = role;
    final uri = Uri.parse('$baseUrl/list/').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['cases'] as List<dynamic>? ?? [];
      return list.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Không thể tải danh sách báo cáo');
    }
  }

  Future<bool> updateCaseStatus(int caseId, String status) async {
    final uri = Uri.parse('$baseUrl/$caseId/status/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }
}

class UploadedFile {
  final String name;
  final String size;
  final Uint8List? bytes;
  final String? path;
  final bool isAudio;
  final String? blobUrl;

  UploadedFile({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
    this.isAudio = false,
    this.blobUrl,
  });
}
