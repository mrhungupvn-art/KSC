import 'package:dio/dio.dart';

import 'api_config.dart';
import 'session_manager.dart';

/// Bọc quanh api/*.php: mọi response API trả JSON dạng
/// {"ok": true, "data": {...}}  hoặc  {"ok": false, "error": "..."}
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true, // tự xử lý mã lỗi, không để Dio ném exception theo status code
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionManager.instance.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

  Dio get raw => _dio;

  /// GET trả về data['data'] khi ok=true, ném ApiException khi ok=false hoặc lỗi mạng.
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _unwrap(res);
    } on DioException catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        options: Options(contentType: 'application/json'),
      );
      return _unwrap(res);
    } on DioException catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  /// Upload ảnh dạng multipart/form-data (action=upload_photo).
  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, dynamic> fields,
    String filePath, {
    String fileField = 'photo',
  }) async {
    try {
      final form = FormData.fromMap({
        ...fields,
        fileField: await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(path, data: form);
      return _unwrap(res);
    } on DioException catch (e) {
      throw ApiException(_networkErrorMessage(e));
    }
  }

  Map<String, dynamic> _unwrap(Response res) {
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException('Phản hồi không hợp lệ từ máy chủ.', statusCode: res.statusCode);
    }
    if (data['ok'] == true) {
      return (data['data'] as Map?)?.cast<String, dynamic>() ?? {};
    }
    throw ApiException(
      (data['error'] as String?) ?? 'Có lỗi xảy ra.',
      statusCode: res.statusCode,
    );
  }

  String _networkErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Không có kết nối mạng.';
    }
    return e.message ?? 'Lỗi kết nối không xác định.';
  }
}

/// Dùng để phân biệt "lỗi do server trả về" (hiện ngay cho người dùng)
/// với "lỗi do mất mạng" (nên đưa vào hàng đợi đồng bộ thay vì báo lỗi).
bool isNetworkError(Object e) {
  if (e is ApiException) return e.message == 'Không có kết nối mạng.';
  return false;
}
