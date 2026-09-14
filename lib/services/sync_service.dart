import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/api_client.dart';
import '../core/local_db.dart';

/// Chạy nền trong suốt vòng đời app: hễ thiết bị có mạng trở lại là gửi bù
/// tuần tự các thao tác đang nằm trong hàng đợi pending_actions.
/// Gửi TUẦN TỰ theo created_at để không bị đảo thứ tự (vd accept phải trước start).
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  void start() {
    _sub ??= _connectivity.onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) syncNow();
    });
    // Thử đồng bộ ngay lúc khởi động app, phòng trường hợp có mạng sẵn từ trước.
    syncNow();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final actions = await LocalDb.instance.pendingActions();
      for (final row in actions) {
        final id = row['id'] as String;
        final jobId = row['job_id'] as int;
        final action = row['action'] as String;
        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        final photoPath = row['photo_path'] as String?;

        try {
          if (action == 'upload_photo' && photoPath != null) {
            await ApiClient.instance.postMultipart(
              '/jobs.php',
              {'action': 'upload_photo', 'job_id': jobId, 'job_point_id': payload['job_point_id']},
              photoPath,
            );
          } else {
            await ApiClient.instance.postJson('/jobs.php', payload);
          }
          await LocalDb.instance.removePending(id);
          _statusController.add('Đã đồng bộ 1 thao tác đang chờ.');
        } on Object catch (e) {
          if (isNetworkError(e)) {
            // vẫn chưa có mạng thật sự (hoặc mạng chập chờn) -> dừng lại, thử lại ở lần sau
            break;
          }
          // Lỗi do server từ chối (vd dữ liệu không còn hợp lệ) -> bỏ qua thao tác này,
          // xoá khỏi hàng đợi để không bị kẹt mãi, các thao tác sau vẫn tiếp tục.
          await LocalDb.instance.removePending(id);
          _statusController.add('Bỏ qua 1 thao tác lỗi: $e');
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
