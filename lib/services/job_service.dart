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
    String? qrCode,
  }) =>
      _doAction(jobId, 'record_point', {
        'control_point_id': controlPointId,
        'result': result,
        'action_taken': actionTaken ?? '',
        'notes': notes ?? '',
        if (qrCode != null && qrCode.isNotEmpty) 'qr_code': qrCode,
      });

  /// Tra cứu điểm kiểm soát theo mã QR vừa quét, giới hạn trong phạm vi
  /// công việc hiện tại. Ném ApiException nếu mã không thuộc công việc này.
  Future<JobPoint> lookupByQr(int jobId, String qrCode, {double? lat, double? lng}) async {
    final data = await ApiClient.instance.postJson('/jobs.php', {
      'action': 'scan_qr',
      'job_id': jobId,
      'qr_code': qrCode,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final point = (data['point'] as Map).cast<String, dynamic>();
    if (data['visit_id'] != null) point['visit_id'] = data['visit_id'];
    return JobPoint.fromJson(point);
  }

  /// Ghi toàn bộ dữ liệu hiện trường của một điểm trong một request.
  /// Nếu có ảnh, ảnh được gửi cùng kết quả; nếu mất mạng, cả dữ liệu + ảnh
  /// được đưa vào hàng đợi để đồng bộ lại sau.
  Future<bool> savePointResult(
    int jobId,
    int controlPointId,
    String result, {
    int? visitId,
    int mouseCaughtCount = 0,
    int otherPestCount = 0,
    int baitPlacedCount = 0,
    int baitEatenCount = 0,
    int baitOtherSignCount = 0,
    int baitReplacedCount = 0,
    String? actionTaken,
    String? notes,
    String? qrCode,
    String? photoPath,
    String photoType = 'LOCATION',
  }) async {
    final fields = <String, dynamic>{
      'action': 'save_point_result',
      'job_id': jobId,
      'control_point_id': controlPointId,
      'result': result,
      if (visitId != null) 'visit_id': visitId,
      'mouse_caught_count': mouseCaughtCount,
      'other_pest_count': otherPestCount,
      'bait_placed_count': baitPlacedCount,
      'bait_eaten_count': baitEatenCount,
      'bait_other_sign_count': baitOtherSignCount,
      'bait_replaced_count': baitReplacedCount,
      'action_taken': actionTaken ?? '',
      'notes': notes ?? '',
      if (qrCode != null && qrCode.isNotEmpty) 'qr_code': qrCode,
      'photo_type': photoType,
    };
    try {
      if (photoPath != null && photoPath.isNotEmpty) {
        await ApiClient.instance.postMultipart('/jobs.php', fields, photoPath);
      } else {
        await ApiClient.instance.postJson('/jobs.php', fields);
      }
      return true;
    } catch (e) {
      if (isNetworkError(e)) {
        await LocalDb.instance.enqueue(
          id: _uuid.v4(),
          jobId: jobId,
          action: 'save_point_result',
          payloadJson: jsonEncode(fields),
          photoPath: photoPath,
        );
        return false;
      }
      rethrow;
    }
  }

  Future<bool> completePoint(int jobId, int controlPointId, int visitId) =>
      _doAction(jobId, 'complete_point', {
        'control_point_id': controlPointId,
        'visit_id': visitId,
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
  Future<bool> uploadPhoto(
    int jobId,
    int jobPointId,
    String filePath, {
    String photoType = 'EVIDENCE',
  }) async {
    try {
      await ApiClient.instance.postMultipart(
        '/jobs.php',
        {
          'action': 'upload_photo',
          'job_id': jobId,
          'job_point_id': jobPointId,
          'photo_type': photoType,
        },
        filePath,
      );
      return true;
    } catch (e) {
      if (isNetworkError(e)) {
        await LocalDb.instance.enqueue(
          id: _uuid.v4(),
          jobId: jobId,
          action: 'upload_photo',
          payloadJson: jsonEncode({'job_point_id': jobPointId, 'photo_type': photoType}),
          photoPath: filePath,
        );
        return false;
      }
      rethrow;
    }
  }

  Future<int> pendingCount() => LocalDb.instance.pendingCount();
}
