class AppConfig {
  AppConfig._();

  static const String baseUrl = 'http://10.0.2.2:5000';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}