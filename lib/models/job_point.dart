/// Một điểm kiểm soát thuộc 1 khu vực của khách hàng,
/// kèm kết quả và lần ghé hiện trường của công việc hiện tại.
class JobPoint {
  final int id; // control_points.id
  final int pointNumber;
  final String name;
  final String? trapType;
  final int zoneId;
  final String zoneName;
  final String? qrCode;
  final int? visitId;
  final PointVisit? visit;
  final PointResult? result;

  JobPoint({
    required this.id,
    required this.pointNumber,
    required this.name,
    this.trapType,
    required this.zoneId,
    required this.zoneName,
    this.qrCode,
    this.visitId,
    this.visit,
    this.result,
  });

  factory JobPoint.fromJson(Map<String, dynamic> j) => JobPoint(
        id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
        pointNumber: j['point_number'] is int
            ? j['point_number'] as int
            : int.tryParse(j['point_number'].toString()) ?? 0,
        name: j['name']?.toString() ?? '',
        trapType: j['trap_type']?.toString(),
        zoneId: j['zone_id'] is int ? j['zone_id'] as int : int.parse(j['zone_id'].toString()),
        zoneName: j['zone_name']?.toString() ?? '',
        qrCode: j['qr_code']?.toString(),
        visitId: j['visit_id'] != null
            ? int.tryParse(j['visit_id'].toString())
            : (j['visit'] is Map ? int.tryParse((j['visit']['id']).toString()) : null),
        visit: j['visit'] is Map ? PointVisit.fromJson((j['visit'] as Map).cast<String, dynamic>()) : null,
        result: j['result'] == null ? null : PointResult.fromJson((j['result'] as Map).cast<String, dynamic>()),
      );
}

class PointVisit {
  final int id;
  final String? scannedAt;
  final String? startedAt;
  final String? completedAt;
  final double? gpsLat;
  final double? gpsLng;
  final String status;

  PointVisit({
    required this.id,
    this.scannedAt,
    this.startedAt,
    this.completedAt,
    this.gpsLat,
    this.gpsLng,
    this.status = 'SCANNED',
  });

  factory PointVisit.fromJson(Map<String, dynamic> j) => PointVisit(
        id: int.parse(j['id'].toString()),
        scannedAt: j['scanned_at']?.toString(),
        startedAt: j['started_at']?.toString(),
        completedAt: j['completed_at']?.toString(),
        gpsLat: j['gps_lat'] == null ? null : double.tryParse(j['gps_lat'].toString()),
        gpsLng: j['gps_lng'] == null ? null : double.tryParse(j['gps_lng'].toString()),
        status: j['status']?.toString() ?? 'SCANNED',
      );
}

class PointResult {
  final String result;
  final int mouseCaughtCount;
  final int otherPestCount;
  final int baitPlacedCount;
  final int baitEatenCount;
  final int baitOtherSignCount;
  final int baitReplacedCount;
  final String? actionTaken;
  final String? notes;
  final List<String> photos;

  PointResult({
    required this.result,
    this.mouseCaughtCount = 0,
    this.otherPestCount = 0,
    this.baitPlacedCount = 0,
    this.baitEatenCount = 0,
    this.baitOtherSignCount = 0,
    this.baitReplacedCount = 0,
    this.actionTaken,
    this.notes,
    this.photos = const [],
  });

  factory PointResult.fromJson(Map<String, dynamic> j) => PointResult(
        result: j['result']?.toString() ?? 'NONE',
        mouseCaughtCount: _toInt(j['mouse_caught_count']),
        otherPestCount: _toInt(j['other_pest_count']),
        baitPlacedCount: _toInt(j['bait_placed_count']),
        baitEatenCount: _toInt(j['bait_eaten_count']),
        baitOtherSignCount: _toInt(j['bait_other_sign_count']),
        baitReplacedCount: _toInt(j['bait_replaced_count']),
        actionTaken: j['action_taken']?.toString(),
        notes: j['notes']?.toString(),
        photos: (j['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  static int _toInt(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  static const labels = {
    'NONE': 'Không phát hiện',
    'SIGN_DETECTED': 'Có dấu hiệu',
    'HANDLED': 'Đã xử lý',
    'MONITOR': 'Cần theo dõi',
  };
}
