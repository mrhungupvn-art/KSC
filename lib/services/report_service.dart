import '../core/api_client.dart';
import '../models/employee_report.dart';

class ReportService {
  Future<EmployeeReport> getMonthlyReport(String month) async {
    final data = await ApiClient.instance.get(
      '/employee_report.php',
      query: {'month': month},
    );
    return EmployeeReport.fromJson(data);
  }
}
