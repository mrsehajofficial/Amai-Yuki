// api_response_model.dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromData) {
    final bool ok = json['success'] == true;
    return ApiResponse(
      success: ok,
      data: ok && json['data'] != null ? fromData(json['data']) : null,
      error: json['error']?.toString(),
    );
  }

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);
  factory ApiResponse.failure(String message) => ApiResponse(success: false, error: message);

  String get errorMessage => error ?? 'Something went wrong. Try again.';
}
