import 'package:chicki_buddy/core/constants.dart';
import 'package:chicki_buddy/core/logger.dart';
import 'package:dio/dio.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

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

    dio.interceptors.add(LogInterceptor(
      responseBody: true,
      logPrint: (obj) => print(obj.toString())
    ));
  }
}