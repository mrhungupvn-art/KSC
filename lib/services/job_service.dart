import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/api_client.dart';
import '../core/local_db.dart';
import '../models/job.dart';
import '../models/job_point.dart';

/// Kết quả 1 job detail: job + danh sách zone + danh sách điểm kiểm soát (kèm kết quả nếu có).
class JobDetail {
  final Job job;
  final List<Zone> zones;
  final List<JobPoint> points;
  final bool fromCache;
  JobDetail({required this.job, required this.zones, required this.points, this.fromCache = false});
}

class JobService {
  final _uuid = const Uuid();

  /// Danh sách công việc của nhân viên đang đăng nhập, ưu tiên gọi API,
  /// nếu mất mạng thì đọc bản cache gần nhất.
  Future<(List<Job> jobs, bool fromCache)> getJobs({String? date, String? status}) async {
    final cacheKey = 'jobs_${date ?? 'all'}_${status ?? 'all'}';
    try {
      final data = await ApiClient.instance.get('/jobs.php', query: {
        if (date != null) 'date': date,
        if (status != null) 'status': status,
      });
      final list = (data['jobs'] as List).cast<Map<String, dynamic>>();
      await LocalDb.instance.saveJobsList(cacheKey, jsonEncode(list));
      return (list.map(Job.fromJson).toList(), false);
    } catch (e) {
      final cached = await LocalDb.instance.readJobsList(cacheKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        return (list.map(Job.fromJson).toList(), true);
      }
      rethrow;
    }
  }

  Future<JobDetail> getJobDetail(int jobId) async {
    try {
      final data = await ApiClient.instance.get('/jobs.php', query: {'id': jobId});
      await LocalDb.instance.saveJobDetail(jobId, jsonEncode(data));
      return _parseDetail(data, fromCache: false);
    } catch (e) {
      final cached = await LocalDb.instance.readJobDetail(jobId);
      if (cached != null) {
        return _parseDetail(jsonDecode(cached) as Map<String, dynamic>, fromCache: true);
      }
      rethrow;
    }
  }

  JobDetail _parseDetail(Map<String, dynamic> data, {required bool fromCache}) {
    final job = Job.fromJson(data['job'] as Map<String, dynamic>);
    final zones = (data['zones'] as List).map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
    final points = (data['points'] as List).map((e) => JobPoint.fromJson(e as Map<String, dynamic>)).toList();
    return JobDetail(job: job, zones: zones, points: points, fromCache: fromCache);
  }

  // ---------------- Các thao tác ghi — tự queue khi mất mạng ----------------

  /// true = đã gửi lên server ngay; false = mất mạng, đã đưa vào hàng đợi đồng bộ sau.
  Future<bool> accept(int jobId) => _doAction(jobId, 'accept', {});

  Future<bool> start(int jobId, {double? lat, double? lng}) =>
      _doAction(jobId, 'start', {'lat': lat, 'lng': lng});

  Future<bool> recordPoint(
    int jobId,
    int controlPointId,
    String result, {
    String? actionTaken,
    String? notes,
  }) =>
      _doAction(jobId, 'record_point', {
        'control_point_id': controlPointId,
        'result': result,
        'action_taken': actionTaken ?? '',
        'notes': notes ?? '',
      });

  Future<bool> customerConfirm(int jobId) => _doAction(jobId, 'customer_confirm', {});

  Future<bool> complete(int jobId) => _doAction(jobId, 'complete', {});

  Future<bool> _doAction(int jobId, String action, Map<String, dynamic> payload) async {
    final body = {'action': action, 'job_id': jobId, ...payload};
    try {
      await ApiClient.instance.postJson('/jobs.php', body);
      return true;
    } catch (e) {
      if (isNetworkError(e)) {
        await LocalDb.instance.enqueue(
          id: _uuid.v4(),
          jobId: jobId,
          action: action,
          payloadJson: jsonEncode(body),
        );
        return false;
      }
      rethrow; // lỗi do server trả về (vd dữ liệu không hợp lệ) -> hiện luôn cho người dùng
    }
  }

  /// Tải ảnh bằng chứng cho 1 điểm kiểm soát. Trả về true nếu gửi lên ngay thành công,
  /// false nếu mất mạng và đã đưa vào hàng đợi (giữ nguyên file để gửi bù sau).
  Future<bool> uploadPhoto(int jobId, int jobPointId, String filePath) async {
    try {
      await ApiClient.instance.postMultipart(
        '/jobs.php',
        {'action': 'upload_photo', 'job_id': jobId, 'job_point_id': jobPointId},
        filePath,
      );
      return true;
    } catch (e) {
      if (isNetworkError(e)) {
        await LocalDb.instance.enqueue(
          id: _uuid.v4(),
          jobId: jobId,
          action: 'upload_photo',
          payloadJson: jsonEncode({'job_point_id': jobPointId}),
          photoPath: filePath,
        );
        return false;
      }
      rethrow;
    }
  }

  Future<int> pendingCount() => LocalDb.instance.pendingCount();
}
