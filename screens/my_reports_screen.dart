import 'package:flutter/material.dart';
import '../models/report.dart';
import 'home_screen.dart' show HomeScreenState;
import 'home_screen.dart' show StatusBadge, ReportDetailDialog;
import 'package:flutter/material.dart';
import 'home_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng static list của HomeScreenState — cần đổi class state thành public
    final reports = HomeScreenState.reports;

    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Bạn chưa gửi báo cáo nào.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (ctx, i) {
        final r = reports[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(r.incidentType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.location),
                if (r.latitude != null && r.longitude != null)
                  Text(
                    '📍 ${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                StatusBadge(status: r.status),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: ctx,
                builder: (_) => ReportDetailDialog(report: r),
              );
            },
          ),
        );
      },
    );
  }
}