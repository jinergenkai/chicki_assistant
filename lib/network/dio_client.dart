import 'package:chicki_buddy/utils/device_utils.dart';
import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/core/logger.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  String? _jwt;

  Future<void> setJwt(String jwt) async {
    _jwt = jwt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', jwt);
  }

  Future<void> loadJwt() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('jwt');
  }

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {"Accept": "application/json"},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_jwt == null) await loadJwt();
          if (_jwt != null) {
            options.headers['Authorization'] = 'Bearer $_jwt';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Nếu lỗi 401 thì thử lấy JWT guest mới và retry
          logger.warning('Request error: ${error.response?.statusCode} ${error.message}');
          if (error.response?.statusCode == 401) {
            final jwt = await fetchGuestJwt();
            if (jwt != null) {
              await setJwt(jwt);
              error.requestOptions.headers['Authorization'] = 'Bearer $jwt';
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );
              final cloneReq = await dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            }
          }
          return handler.next(error);
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(responseBody: true, logPrint: (obj) => print(obj.toString())));
  }

// Hàm gọi API guest/init để lấy JWT guest
  Future<String?> fetchGuestJwt() async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      final userAgent = await DeviceUtils.getUserAgent();
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      // TODO: Lấy IP thực tế nếu cần, tạm để 0.0.0.0
      final payload = {
        "device_id": deviceId,
        "ip_address": "0.0.0.0",
        "user_agent": userAgent,
        "device_info": deviceInfo,
      };
      final response = await dio.post(
        "/guest/init",
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        // Giả sử JWT trả về ở response.data['jwt']
        return response.data['guest_token'] as String?;
      }
    } catch (e) {
      print("fetchGuestJwt error: $e");
    }
    return null;
  }
}
