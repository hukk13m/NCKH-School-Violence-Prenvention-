import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState
    extends State<DashboardScreen> {

  final DashboardService dashboardService =
  DashboardService();

  DashboardData? dashboard;

  bool isLoading = true;
  String? errorMessage;


  @override
  void initState() {
    super.initState();

    loadDashboard();
  }


  Future<void> loadDashboard() async {
    try {
      final data =
      await dashboardService.getDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = data;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: buildContent(),
    );
  }

  /// Format ISO date -> "dd/MM"
  String _formatDateLabel(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      if (raw.length >= 10) return raw.substring(0, 10);
      return raw;
    }
  }

  Widget buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }


    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),

            const SizedBox(height: 16),

            Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }


    if (dashboard == null) {
      return const Center(
        child: Text('Không có dữ liệu'),
      );
    }


    return RefreshIndicator(
      onRefresh: loadDashboard,

      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            buildHeader(),

            const SizedBox(height: 24),

            buildSummaryCards(),

            const SizedBox(height: 32),

            buildPriorityChart(),

            const SizedBox(height: 32),

            buildDateChart(),

            const SizedBox(height: 32),

            buildStatusChart(),
          ],
        ),
      ),
    );
  }


  Widget buildHeader() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Overview of school violence cases',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  Widget buildSummaryCards() {
    final summary =
        dashboard!.summary;

    return Wrap(
      spacing: 16,
      runSpacing: 16,

      children: [
        buildSummaryCard(
          title: 'Total Cases',
          value: summary.totalCases,
          icon: Icons.assignment,
        ),

        buildSummaryCard(
          title: 'New',
          value: summary.newCases,
          icon: Icons.fiber_new,
        ),

        buildSummaryCard(
          title: 'In Progress',
          value: summary.inProgress,
          icon: Icons.pending_actions,
        ),

        buildSummaryCard(
          title: 'Resolved',
          value: summary.resolved,
          icon: Icons.check_circle,
        ),

        buildSummaryCard(
          title: 'Closed',
          value: summary.closed,
          icon: Icons.lock,
        ),
      ],
    );
  }


  Widget buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 210,

      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      overflow:
                      TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      value.toString(),

                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildPriorityChart() {
    final data =
        dashboard!.byPriority;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              'Cases by Priority',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 280,

              child: BarChart(
                BarChartData(
                  maxY: (data.map((e) => e.total).reduce((a, b) => a > b ? a : b) * 1.3)
                      .clamp(1, double.infinity)
                      .toDouble(),
                  barGroups: List.generate(
                    data.length,
                        (index) {
                      return BarChartGroupData(
                        x: index,

                        barRods: [
                          BarChartRodData(
                            toY:
                            data[index].total.toDouble(),

                            width: 32,

                            borderRadius:
                            BorderRadius.circular(4),
                          ),
                        ],
                      );
                    },
                  ),

                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),

                    rightTitles:
                    const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),

                    topTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),

                    bottomTitles:
                    AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: true,

                        getTitlesWidget:
                            (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox();
                          }

                          return Text(
                            data[index].priority,
                          );
                        },
                      ),
                    ),
                  ),

                  borderData:
                  FlBorderData(
                    show: false,
                  ),

                  gridData:
                  const FlGridData(
                    show: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildDateChart() {
    final data = dashboard!.byDate;

    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Chưa có đủ dữ liệu theo ngày để vẽ biểu đồ.')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Cases by Date',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 280,

              child: LineChart(
                LineChartData(
                  minX: -0.3,
                  maxX: (data.length - 1).toDouble() + 0.3,
                  minY: 0,
                  maxY: (data.map((e) => e.total).reduce((a, b) => a > b ? a : b) * 1.2)
                      .clamp(1, double.infinity)
                      .toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                            (index) {
                          return FlSpot(
                            index.toDouble(),
                            data[index].total.toDouble(),
                          );
                        },
                      ),

                      isCurved: data.length > 2,

                      barWidth: 3,

                      dotData: const FlDotData(show: true),
                    ),
                  ],

                  titlesData: FlTitlesData(
                    leftTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),

                    rightTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),

                    topTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: false,
                      ),
                    ),

                    bottomTitles:
                    AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles: true,

                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _formatDateLabel(data[index].date),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  borderData:
                  FlBorderData(
                    show: false,
                  ),

                  gridData:
                  const FlGridData(
                    show: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildStatusChart() {
    final data = dashboard!.byStatus;

    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Chưa có dữ liệu theo trạng thái.')),
        ),
      );
    }

    // Hàm tự động gán màu cho các trạng thái
    Color getStatusColor(String status) {
      switch (status) {
        case 'New':
          return Colors.blue;
        case 'In Progress':
          return Colors.orange;
        case 'Resolved':
          return Colors.green;
        case 'Closed':
          return Colors.grey;
        default:
          return Colors.indigo;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              'Cases by Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            ...data.map(
                  (item) {
                return ListTile(
                  contentPadding:
                  EdgeInsets.zero,

                  title: Text(item.status),

                  trailing: Text(
                    item.total.toString(),

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}