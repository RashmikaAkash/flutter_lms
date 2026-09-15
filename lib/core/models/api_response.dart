class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, {
        T Function(dynamic data)? fromData,
      }) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: fromData != null && json.containsKey('data')
          ? fromData(json['data'])
          : json['data'] as T?,
    );
  }
}