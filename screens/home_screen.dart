import 'package:flutter/material.dart';
import '../models/report.dart';
import '../models/picked_location.dart';
import '../services/report_service.dart';
import 'location_picker_screen.dart';

// =====================================================
// HOME PAGE
// =====================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {

  // Danh sách các report đã gửi
  static final List<IncidentReport> reports = [];

  // ===================================================
  // OPEN REPORT FORM
  // ===================================================

  void showReportForm() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ReportDialog(
          onSubmitted: (report) {
            setState(() {
              reports.add(report);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Report submitted successfully.",
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================================================
  // OPEN REPORT LIST
  // ===================================================

  void showMyReports() {
    showDialog(
      context: context,
      builder: (context) {
        return ReportListDialog(
          reports: reports,
        );
      },
    );
  }

  // ===================================================
  // UI
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // REPORT INCIDENT BUTTON
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: showReportForm,
                icon: const Icon(
                  Icons.report_problem_outlined,
                ),
                label: const Text(
                  "Report Incident",
                ),
              ),
            ),

            const SizedBox(height: 15),

            // MY REPORTS BUTTON
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: showMyReports,
                icon: const Icon(
                  Icons.track_changes,
                ),
                label: const Text(
                  "My Reports",
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "${reports.length} report(s) submitted",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// REPORT DIALOG
// =====================================================

class ReportDialog extends StatefulWidget {
  final Function(IncidentReport) onSubmitted;

  const ReportDialog({
    super.key,
    required this.onSubmitted,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();

  String incidentType = "Physical Violence";
  bool anonymous = false;
  bool _submitting = false;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Lưu toạ độ nếu user chọn từ bản đồ
  double? _pickedLat;
  double? _pickedLng;

  @override
  void dispose() {
    descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Mở bản đồ chọn vị trí
  Future<void> _openLocationPicker() async {
    final initial = PickedLocation(
      addressText: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      latitude: _pickedLat,
      longitude: _pickedLng,
    );

    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: initial),
      ),
    );

    if (result != null) {
      setState(() {
        _locationController.text = result.addressText ?? '';
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
      });
    }
  }

  // Submit
  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final locationText = _locationController.text.trim();
    if (locationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc chọn vị trí sự việc.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final ok = await ReportService().createReport(
      incidentType: incidentType,
      description: descriptionController.text,
      anonymous: anonymous,
      locationText: locationText,
      latitude: _pickedLat,
      longitude: _pickedLng,
      addressText: locationText,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi báo cáo thất bại!')),
      );
      return;
    }

    final report = IncidentReport(
      id: "RPT-${DateTime.now().millisecondsSinceEpoch}",
      incidentType: incidentType,
      location: locationText,
      latitude: _pickedLat,
      longitude: _pickedLng,
      description: descriptionController.text,
      anonymous: anonymous,
    );

    widget.onSubmitted(report);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Report Incident"),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 350,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // INCIDENT TYPE
                DropdownButtonFormField<String>(
                  initialValue: incidentType,
                  decoration: const InputDecoration(labelText: "Incident Type"),
                  items: const [
                    DropdownMenuItem(value: "Physical Violence", child: Text("Physical Violence")),
                    DropdownMenuItem(value: "Verbal Abuse", child: Text("Verbal Abuse")),
                    DropdownMenuItem(value: "Cyberbullying", child: Text("Cyberbullying")),
                    DropdownMenuItem(value: "Threat", child: Text("Threat")),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => incidentType = value);
                  },
                ),

                const SizedBox(height: 15),

                // ✅ LOCATION — TextField + icon bản đồ
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Location",
                    hintText: "Nhập địa chỉ hoặc chọn trên bản đồ",
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      _pickedLat != null ? Icons.location_on : Icons.location_off_outlined,
                      color: _pickedLat != null ? Colors.green : Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Chọn vị trí trên bản đồ',
                      icon: const Icon(Icons.map_outlined),
                      onPressed: _openLocationPicker,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter location";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // DESCRIPTION
                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter description";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // ANONYMOUS
                CheckboxListTile(
                  title: const Text("Submit Anonymously"),
                  value: anonymous,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => anonymous = value ?? false);
                  },
                ),

                const SizedBox(height: 15),

                // EVIDENCE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text("Upload Evidence"),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Accepted formats: JPG, PNG, PDF, mp4\nMax size: 10MB",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : submitReport,
          child: _submitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Submit"),
        ),
      ],
    );
  }
}

// =====================================================
// REPORT LIST DIALOG
// =====================================================

class ReportListDialog extends StatelessWidget {

  final List<IncidentReport> reports;

  const ReportListDialog({
    super.key,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: const Text(
        "My Reports",
      ),

      content: SizedBox(

        width: 400,

        child: reports.isEmpty

            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "No reports submitted yet.",
            ),
          ),
        )

            : ListView.builder(

          shrinkWrap: true,

          itemCount: reports.length,

          itemBuilder: (context, index) {

            final report = reports[index];

            return Card(

              margin: const EdgeInsets.only(
                bottom: 10,
              ),

              child: ListTile(

                leading: CircleAvatar(
                  child: Text(
                    "${index + 1}",
                  ),
                ),

                title: Text(
                  report.incidentType,
                ),

                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      report.location,
                    ),

                    const SizedBox(height: 5),

                    StatusBadge(
                      status: report.status,
                    ),
                  ],
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                onTap: () {

                  showDialog(

                    context: context,

                    builder: (context) {

                      return ReportDetailDialog(
                        report: report,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),

      actions: [

        TextButton(

          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text(
            "Close",
          ),
        ),
      ],
    );
  }
}

// =====================================================
// REPORT DETAIL
// =====================================================

class ReportDetailDialog extends StatelessWidget {

  final IncidentReport report;

  const ReportDetailDialog({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: Text(
        "Report ${report.id}",
      ),

      content: SingleChildScrollView(

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Incident Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              report.incidentType,
            ),

            const SizedBox(height: 15),

            const Text(
              "Location",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              report.location,
            ),

            const SizedBox(height: 15),

            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              report.description,
            ),

            const SizedBox(height: 15),

            const Text(
              "Submission Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              report.anonymous
                  ? "Anonymous"
                  : "Identified",
            ),

            const SizedBox(height: 20),

            const Text(
              "Current Status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            StatusBadge(
              status: report.status,
            ),

            const SizedBox(height: 20),

            // PROGRESS
            ReportProgress(
              status: report.status,
            ),
          ],
        ),
      ),

      actions: [

        TextButton(

          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text(
            "Close",
          ),
        ),
      ],
    );
  }
}

// =====================================================
// STATUS BADGE
// =====================================================

class StatusBadge extends StatelessWidget {

  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(

        color: Colors.indigo.shade50,

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          color: Colors.indigo.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// =====================================================
// REPORT PROGRESS
// =====================================================

class ReportProgress extends StatelessWidget {

  final String status;

  const ReportProgress({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    int currentStep = 1;

    if (status == "In Progress") {
      currentStep = 2;
    }

    if (status == "Resolved") {
      currentStep = 3;
    }

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(
          "Report Progress",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(

          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

          children: [

            ProgressStep(
              label: "Submitted",
              active: currentStep >= 0,
            ),

            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey.shade300,
              ),
            ),

            ProgressStep(
              label: "Under Review",
              active: currentStep >= 1,
            ),

            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey.shade300,
              ),
            ),

            ProgressStep(
              label: "Resolved",
              active: currentStep >= 3,
            ),
          ],
        ),
      ],
    );
  }
}

// =====================================================
// PROGRESS STEP
// =====================================================

class ProgressStep extends StatelessWidget {

  final String label;
  final bool active;

  const ProgressStep({
    super.key,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {

    return Column(

      children: [

        CircleAvatar(

          radius: 12,

          backgroundColor:
          active
              ? Colors.indigo
              : Colors.grey.shade300,

          child: active
              ? const Icon(
            Icons.check,
            size: 14,
            color: Colors.white,
          )
              : null,
        ),

        const SizedBox(height: 5),

        SizedBox(

          width: 75,

          child: Text(
            label,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}