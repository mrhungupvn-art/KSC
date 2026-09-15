import '../core/api_client.dart';
import '../core/session_manager.dart';
import '../models/employee.dart';

class AuthService {
  /// [identifier] có thể là mã nhân viên (vd NV001) hoặc số điện thoại — khớp
  /// đúng logic api/auth.php (WHERE code=? OR phone=?).
  Future<Employee> login(String identifier, String password) async {
    final data = await ApiClient.instance.postJson('/auth.php', {
      'username': identifier,
      'password': password,
    });
    final token = data['token'] as String;
    final employee = Employee.fromJson(data['employee'] as Map<String, dynamic>);
    await SessionManager.instance.save(token, employee);
    return employee;
  }

  Future<void> logout() async {
    await SessionManager.instance.clear();
  }
}
