class EmployeeReport {
  final String month;
  final Map<String, dynamic> summary;
  final List<ReportDay> daily;
  final List<ReportJob> jobs;

  EmployeeReport({
    required this.month,
    required this.summary,
    this.daily = const [],
    this.jobs = const [],
  });

  factory EmployeeReport.fromJson(Map<String, dynamic> j) => EmployeeReport(
        month: j['month']?.toString() ?? '',
        summary: (j['summary'] as Map?)?.cast<String, dynamic>() ?? {},
        daily: (j['daily'] as List?)
                ?.map((e) => ReportDay.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        jobs: (j['jobs'] as List?)
                ?.map((e) => ReportJob.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  int value(String key) {
    final v = summary[key];
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double percent(String key) {
    final v = summary[key];
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ReportDay {
  final String date;
  final int visits;
  final int points;
  final int mouseCaught;

  ReportDay({
    required this.date,
    required this.visits,
    required this.points,
    required this.mouseCaught,
  });

  factory ReportDay.fromJson(Map<String, dynamic> j) => ReportDay(
        date: j['d']?.toString() ?? '',
        visits: int.tryParse(j['visits']?.toString() ?? '') ?? 0,
        points: int.tryParse(j['points']?.toString() ?? '') ?? 0,
        mouseCaught: int.tryParse(j['mouse_caught']?.toString() ?? '') ?? 0,
      );
}

class ReportJob {
  final String date;
  final String jobNo;
  final String customerName;
  final int visits;
  final int visitedPoints;
  final int checkedPoints;
  final int mouseCaught;
  final int baitEaten;

  ReportJob({
    required this.date,
    required this.jobNo,
    required this.customerName,
    required this.visits,
    required this.visitedPoints,
    required this.checkedPoints,
    required this.mouseCaught,
    required this.baitEaten,
  });

  factory ReportJob.fromJson(Map<String, dynamic> j) => ReportJob(
        date: j['scheduled_date']?.toString() ?? '',
        jobNo: j['job_no']?.toString() ?? '',
        customerName: j['customer_name']?.toString() ?? '',
        visits: int.tryParse(j['visits']?.toString() ?? '') ?? 0,
        visitedPoints: int.tryParse(j['visited_points']?.toString() ?? '') ?? 0,
        checkedPoints: int.tryParse(j['checked_points']?.toString() ?? '') ?? 0,
        mouseCaught: int.tryParse(j['mouse_caught']?.toString() ?? '') ?? 0,
        baitEaten: int.tryParse(j['bait_eaten']?.toString() ?? '') ?? 0,
      );
}
