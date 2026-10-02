import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DB cục bộ trên máy nhân viên. Hai nhóm bảng:
/// - *_cache: lưu bản sao dữ liệu mới nhất tải từ server, để đọc được khi mất mạng.
/// - pending_actions: hàng đợi các thao tác chưa gửi lên được server do mất mạng,
///   sẽ được SyncService gửi bù lại theo đúng thứ tự khi có mạng trở lại.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'ksc_app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jobs_list_cache (
            cache_key TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE job_detail_cache (
            job_id INTEGER PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_actions (
            id TEXT PRIMARY KEY,
            job_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            photo_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- jobs list cache ----------------

  Future<void> saveJobsList(String cacheKey, String json) async {
    final d = await db;
    await d.insert(
      'jobs_list_cache',
      {'cache_key': cacheKey, 'json': json, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readJobsList(String cacheKey) async {
    final d = await db;
    final rows = await d.query('jobs_list_cache', where: 'cache_key=?', whereArgs: [cacheKey]);
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  // ---------------- job detail cache ----------------

  Future<void> saveJobDetail(int jobId, String json) async {
    final d = await db;
    await d.insert(
      'job_detail_cache',
      {'job_id': jobId, 'json': json, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readJobDetail(int jobId) async {
    final d = await db;
    final rows = await d.query('job_detail_cache', where: 'job_id=?', whereArgs: [jobId]);
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  // ---------------- hàng đợi đồng bộ ----------------

  Future<void> enqueue({
    required String id,
    required int jobId,
    required String action,
    required String payloadJson,
    String? photoPath,
  }) async {
    final d = await db;
    await d.insert('pending_actions', {
      'id': id,
      'job_id': jobId,
      'action': action,
      'payload': payloadJson,
      'photo_path': photoPath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> pendingActions() async {
    final d = await db;
    return d.query('pending_actions', orderBy: 'created_at ASC');
  }

  Future<int> pendingCount() async {
    final d = await db;
    final r = Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM pending_actions'));
    return r ?? 0;
  }

  Future<void> removePending(String id) async {
    final d = await db;
    await d.delete('pending_actions', where: 'id=?', whereArgs: [id]);
  }
}
