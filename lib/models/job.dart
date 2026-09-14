class Job {
  final int id;
  final String jobNo;
  final int customerId;
  final String customerName;
  final String? customerAddress;
  final String? customerPhone;
  final String jobType;
  final String scheduledDate;
  final String? scheduledTime;
  final String status; // PENDING, IN_PROGRESS, DONE, OVERDUE, CANCELLED
  final String? notes;
  final String? acceptedAt;
  final String? startedAt;
  final String? checkedAt;
  final String? recordedAt;
  final String? photographedAt;
  final String? customerConfirmedAt;
  final String? completedAt;
  final double? gpsLat;
  final double? gpsLng;

  Job({
    required this.id,
    required this.jobNo,
    required this.customerId,
    required this.customerName,
    this.customerAddress,
    this.customerPhone,
    required this.jobType,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.notes,
    this.acceptedAt,
    this.startedAt,
    this.checkedAt,
    this.recordedAt,
    this.photographedAt,
    this.customerConfirmedAt,
    this.completedAt,
    this.gpsLat,
    this.gpsLng,
  });

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
        jobNo: j['job_no']?.toString() ?? '',
        customerId: j['customer_id'] is int ? j['customer_id'] as int : int.parse(j['customer_id'].toString()),
        customerName: j['customer_name']?.toString() ?? '',
        customerAddress: j['customer_address']?.toString(),
        customerPhone: j['customer_phone']?.toString(),
        jobType: j['job_type']?.toString() ?? '',
        scheduledDate: j['scheduled_date']?.toString() ?? '',
        scheduledTime: j['scheduled_time']?.toString(),
        status: j['status']?.toString() ?? 'PENDING',
        notes: j['notes']?.toString(),
        acceptedAt: j['accepted_at']?.toString(),
        startedAt: j['started_at']?.toString(),
        checkedAt: j['checked_at']?.toString(),
        recordedAt: j['recorded_at']?.toString(),
        photographedAt: j['photographed_at']?.toString(),
        customerConfirmedAt: j['customer_confirmed_at']?.toString(),
        completedAt: j['completed_at']?.toString(),
        gpsLat: j['gps_lat'] == null ? null : double.tryParse(j['gps_lat'].toString()),
        gpsLng: j['gps_lng'] == null ? null : double.tryParse(j['gps_lng'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_no': jobNo,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_address': customerAddress,
        'customer_phone': customerPhone,
        'job_type': jobType,
        'scheduled_date': scheduledDate,
        'scheduled_time': scheduledTime,
        'status': status,
        'notes': notes,
        'accepted_at': acceptedAt,
        'started_at': startedAt,
        'checked_at': checkedAt,
        'recorded_at': recordedAt,
        'photographed_at': photographedAt,
        'customer_confirmed_at': customerConfirmedAt,
        'completed_at': completedAt,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
      };

  static const statusLabels = {
    'PENDING': 'Chưa thực hiện',
    'IN_PROGRESS': 'Đang thực hiện',
    'DONE': 'Hoàn thành',
    'OVERDUE': 'Quá hạn',
    'CANCELLED': 'Đã huỷ',
  };
}

class Zone {
  final int id;
  final String name;
  Zone({required this.id, required this.name});
  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
      );
}
