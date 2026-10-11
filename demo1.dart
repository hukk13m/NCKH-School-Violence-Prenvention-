import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Violence Detection',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void showReportForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const ReportDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Violence Detection"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showReportForm(context);
          },
          child: const Text("Report Incident"),
        ),
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();

  String incidentType = "Physical Violence";
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool anonymous = false;

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho controller khi đóng Dialog
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
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
                DropdownButtonFormField<String>(
                  initialValue: incidentType,
                  decoration: const InputDecoration(
                    labelText: "Incident Type",
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "Physical Violence",
                      child: Text("Physical Violence"),
                    ),
                    DropdownMenuItem(
                      value: "Verbal Abuse",
                      child: Text("Verbal Abuse"),
                    ),
                    DropdownMenuItem(
                      value: "Cyberbullying",
                      child: Text("Cyberbullying"),
                    ),
                    DropdownMenuItem(
                      value: "Threat",
                      child: Text("Threat"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        incidentType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter location";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter description";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                CheckboxListTile(
                  title: const Text("Submit Anonymously"),
                  value: anonymous,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      anonymous = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 15),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Report submitted successfully.",
                  ),
                ),
              );
            }
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}