class DashboardSummary {
  final int totalCases;
  final int newCases;
  final int inProgress;
  final int resolved;
  final int closed;

  DashboardSummary({
    required this.totalCases,
    required this.newCases,
    required this.inProgress,
    required this.resolved,
    required this.closed,
  });

  factory DashboardSummary.fromJson(
      Map<String, dynamic> json,
      ) {
    return DashboardSummary(
      totalCases: json['totalCases'] ?? json['total_cases'] ?? json['total'] ?? json['count'] ?? 0,
      newCases: json['newCases'] ?? json['new_cases'] ?? json['new'] ?? 0,
      inProgress: json['inProgress'] ?? json['in_progress'] ?? json['in_progress_cases'] ?? 0,
      resolved: json['resolved'] ?? json['resolved_cases'] ?? 0,
      closed: json['closed'] ?? json['closed_cases'] ?? 0,
    );
  }
}


class PriorityStatistic {
  final String priority;
  final int total;

  PriorityStatistic({
    required this.priority,
    required this.total,
  });

  factory PriorityStatistic.fromJson(
      Map<String, dynamic> json,
      ) {
    return PriorityStatistic(
      priority: json['priority']?.toString() ?? json['priority_name']?.toString() ?? json['name']?.toString() ?? '',
      total: json['total'] ?? json['count'] ?? json['cases'] ?? json['value'] ?? 0,
    );
  }
}


class StatusStatistic {
  final String status;
  final int total;

  StatusStatistic({
    required this.status,
    required this.total,
  });

  factory StatusStatistic.fromJson(
      Map<String, dynamic> json,
      ) {
    return StatusStatistic(
      status: json['status']?.toString() ?? json['status_name']?.toString() ?? json['name']?.toString() ?? json['statusName']?.toString() ?? '',
      total: json['total'] ?? json['count'] ?? json['cases'] ?? json['value'] ?? 0,
    );
  }
}


class DateStatistic {
  final String date;
  final int total;

  DateStatistic({
    required this.date,
    required this.total,
  });

  factory DateStatistic.fromJson(
      Map<String, dynamic> json,
      ) {
    return DateStatistic(
      date: json['date']?.toString() ?? json['date_str']?.toString() ?? json['day']?.toString() ?? json['created_date']?.toString() ?? json['time']?.toString() ?? '',
      total: json['total'] ?? json['count'] ?? json['cases'] ?? json['value'] ?? 0,
    );
  }
}


class DashboardData {
  final DashboardSummary summary;
  final List<PriorityStatistic> byPriority;
  final List<StatusStatistic> byStatus;
  final List<DateStatistic> byDate;

  DashboardData({
    required this.summary,
    required this.byPriority,
    required this.byStatus,
    required this.byDate,
  });

  factory DashboardData.fromJson(
      Map<String, dynamic> json,
      ) {
    final priorityList = json['byPriority'] ?? json['caseByPriority'] ?? json['casesByPriority'] ?? json['casebyPriority'] ?? json['casebypriority'] ?? json['by_priority'] ?? json['case_by_priority'] ?? [];
    
    final statusList = json['byStatus'] ?? json['caseByStatus'] ?? json['casesByStatus'] ?? json['casebyStatus'] ?? json['casebystatus'] ?? json['casebyStatus'] ?? json['by_status'] ?? json['case_by_status'] ?? [];

    final dateList = json['byDate'] ?? json['caseByDate'] ?? json['casesByDate'] ?? json['casebyDate'] ?? json['casebydate'] ?? json['by_date'] ?? json['case_by_date'] ?? [];

    return DashboardData(
      summary: DashboardSummary.fromJson(
        json['summary'] ?? json['dashboard_summary'] ?? {},
      ),

      byPriority: (priorityList as List? ?? [])
          .map(
            (item) => PriorityStatistic.fromJson(Map<String, dynamic>.from(item)),
      )
          .toList(),

      byStatus: (statusList as List? ?? [])
          .map(
            (item) => StatusStatistic.fromJson(Map<String, dynamic>.from(item)),
      )
          .toList(),

      byDate: (dateList as List? ?? [])
          .map(
            (item) => DateStatistic.fromJson(Map<String, dynamic>.from(item)),
      )
          .toList(),
    );
  }
}
