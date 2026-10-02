import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/session_manager.dart';
import 'screens/job_list_screen.dart';
import 'screens/login_screen.dart';

void main() {
  // Bọc toàn bộ app bằng runZonedGuarded + FlutterError.onError để mọi lỗi
  // (kể cả lỗi async ngoài build()) đều được ghi log thay vì khiến app treo
  // màn hình trắng không rõ nguyên nhân trong bản release.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[KSC] FlutterError: ${details.exceptionAsString()}');
    };
    // Bắt buộc phải gọi trước khi dùng DateFormat(..., 'vi') ở JobListScreen,
    // nếu không sẽ ném LocaleDataException ngay khi build -> app hiện màn
    // hình trắng ngay sau khi đăng nhập (crash không có UI báo lỗi ở release).
    await initializeDateFormatting('vi', null);
    runApp(const KscApp());
  }, (error, stack) {
    debugPrint('[KSC] Uncaught error: $error\n$stack');
  });
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
        // QUAN TRỌNG: trước đây chỉ kiểm tra `!snap.hasData`, nên nếu future này
        // ném lỗi (vd flutter_secure_storage không đọc được dữ liệu cũ sau khi
        // cài đè bản ký khác, hoặc lỗi keystore đặc thù của máy) thì hasData mãi
        // mãi là false -> vòng xoay tải hiện vĩnh viễn, trông như "màn hình trắng
        // cứ load" không bao giờ vào được app. Phải xử lý rõ 3 trạng thái:
        // đang chờ / lỗi / có kết quả.
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          debugPrint('[KSC] Lỗi đọc phiên đăng nhập: ${snap.error}');
          // Phiên cũ có thể đã hỏng (vd cài đè bản ký khác) -> xoá để không kẹt lại
          // ở đây mãi, rồi cho vào màn hình đăng nhập như người dùng mới.
          SessionManager.instance.clear();
          return const LoginScreen();
        }
        return (snap.data ?? false) ? const JobListScreen() : const LoginScreen();
      },
    );
  }
}
