/// Một điểm kiểm soát (trạm bẫy/trạm mồi) thuộc 1 khu vực của khách hàng,
/// kèm kết quả nhân viên đã ghi cho công việc hiện tại (nếu có).
class JobPoint {
  final int id; // control_points.id
  final int pointNumber;
  final String name;
  final String? trapType;
  final int zoneId;
  final String zoneName;
  final String? qrCode; // Mã QR dán trên hộp bẫy — dùng để kiểm soát nhân viên đúng vị trí.
  final PointResult? result;

  JobPoint({
    required this.id,
    required this.pointNumber,
    required this.name,
    this.trapType,
    required this.zoneId,
    required this.zoneName,
    this.qrCode,
    this.result,
  });

  factory JobPoint.fromJson(Map<String, dynamic> j) => JobPoint(
        id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
        pointNumber: j['point_number'] is int ? j['point_number'] as int : int.tryParse(j['point_number'].toString()) ?? 0,
        name: j['name']?.toString() ?? '',
        trapType: j['trap_type']?.toString(),
        zoneId: j['zone_id'] is int ? j['zone_id'] as int : int.parse(j['zone_id'].toString()),
        zoneName: j['zone_name']?.toString() ?? '',
        qrCode: j['qr_code']?.toString(),
        result: j['result'] == null ? null : PointResult.fromJson(j['result'] as Map<String, dynamic>),
      );
}

class PointResult {
  final String result; // NONE, SIGN_DETECTED, HANDLED, MONITOR
  final String? actionTaken;
  final String? notes;
  final List<String> photos; // URL tuyệt đối đã ghép sẵn từ UPLOAD_URL

  PointResult({required this.result, this.actionTaken, this.notes, this.photos = const []});

  factory PointResult.fromJson(Map<String, dynamic> j) => PointResult(
        result: j['result']?.toString() ?? 'NONE',
        actionTaken: j['action_taken']?.toString(),
        notes: j['notes']?.toString(),
        photos: (j['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  static const labels = {
    'NONE': 'Không phát hiện',
    'SIGN_DETECTED': 'Có dấu hiệu',
    'HANDLED': 'Đã xử lý',
    'MONITOR': 'Cần theo dõi',
  };
}
