import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/employee.dart';

/// Quản lý phiên đăng nhập: lưu token + thông tin nhân viên vào secure storage,
/// đọc lại khi mở app, và xoá khi đăng xuất.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  final _storage = const FlutterSecureStorage();

  static const _kToken = 'ksc_token';
  static const _kEmployee = 'ksc_employee';

  String? _cachedToken;
  Employee? _cachedEmployee;

  Future<void> save(String token, Employee employee) async {
    _cachedToken = token;
    _cachedEmployee = employee;
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kEmployee, value: jsonEncode(employee.toJson()));
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _kToken);
    return _cachedToken;
  }

  Future<Employee?> getEmployee() async {
    if (_cachedEmployee != null) return _cachedEmployee;
    final raw = await _storage.read(key: _kEmployee);
    if (raw == null) return null;
    _cachedEmployee = Employee.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cachedEmployee;
  }

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  Future<void> clear() async {
    _cachedToken = null;
    _cachedEmployee = null;
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kEmployee);
  }
}
