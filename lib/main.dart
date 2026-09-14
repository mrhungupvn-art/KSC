import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/session_manager.dart';
import 'screens/job_list_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bắt buộc phải gọi trước khi dùng DateFormat(..., 'vi') ở JobListScreen,
  // nếu không sẽ ném LocaleDataException ngay khi build -> app hiện màn
  // hình trắng ngay sau khi đăng nhập (crash không có UI báo lỗi ở release).
  await initializeDateFormatting('vi', null);
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
