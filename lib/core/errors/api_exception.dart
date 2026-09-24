import 'dart:convert';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? code;
  /// The unmodified response body returned by the server, when available.
  final dynamic responseBody;

  String get diagnosticDetails {
    final body = responseBody;
    if (body == null) return message;

    String formattedBody;
    if (body is String) {
      try {
        formattedBody = const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
      } on FormatException {
        formattedBody = body;
      }
    } else {
      try {
        formattedBody = const JsonEncoder.withIndent('  ').convert(body);
      } on JsonUnsupportedObjectError {
        formattedBody = body.toString();
      }
    }

    return 'HTTP ${statusCode ?? 'unknown'}\n$formattedBody';
  }

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  factory ApiException.fromStatusCode({
    required int statusCode,
    String? message,
    dynamic responseBody,
  }) {
    return ApiException(
      statusCode: statusCode,
      message: message ?? _defaultMessage(statusCode),
      responseBody: responseBody,
    );
  }

  static String _defaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Authentication required';
      case 403:
        return 'You do not have permission to perform this action';
      case 404:
        return 'Requested resource was not found';
      case 409:
        return 'The request conflicts with existing data';
      case 422:
        return 'The submitted data is invalid';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return 'Server error. Please try again later';
      case 502:
      case 503:
      case 504:
        return 'Service is temporarily unavailable';
      default:
        return 'Something went wrong';
    }
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }

    return 'ApiException: $message';
  }
}
