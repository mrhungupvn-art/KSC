import 'package:flutter/material.dart';

import 'core/session_manager.dart';
import 'screens/job_list_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KscApp());
}

class KscApp extends StatelessWidget {
  const KscApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GFC | KSC — App Nhân viên',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const _SplashGate(),
    );
  }
}

/// Kiểm tra đã có token đăng nhập lưu sẵn hay chưa để vào thẳng danh sách công việc,
/// tránh bắt nhân viên đăng nhập lại mỗi lần mở app.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionManager.instance.isLoggedIn(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data! ? const JobListScreen() : const LoginScreen();
      },
    );
  }
}
