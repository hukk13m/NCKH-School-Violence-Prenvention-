import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CaseModel {
  final int id;
  final String reportType;
  final String incidentType;
  final String priority;
  final String location;
  final String description;
  final String status;
  final String createdAt;
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
    required this.evidences,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as int? ?? 0,
      reportType: json['report_type'] as String? ?? 'Report',
      incidentType: json['incident_type'] as String? ?? 'General',
      priority: json['priority'] as String? ?? 'Normal',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'New',
      createdAt: json['created_at'] as String? ?? '',
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
      : baseUrl = baseUrl ?? 'http://localhost:8000/api/cases';

  Future<CaseModel> submitReport({
    required String description,
    required String location,
    required String reportType,
    required String priority,
    String? userId,
    List<UploadedFile> files = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/create/');
    final request = http.MultipartRequest('POST', uri);

    request.fields['description'] = description;
    request.fields['location'] = location;
    request.fields['report_type'] = reportType;
    request.fields['priority'] = priority;
    if (userId != null) {
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

  Future<List<CaseModel>> fetchCases({String? userId}) async {
    final query = userId != null ? '?user_id=$userId' : '';
    final uri = Uri.parse('$baseUrl/list/$query');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['cases'] as List<dynamic>? ?? [];
      return list.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Không thể tải danh sách báo cáo');
    }
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
