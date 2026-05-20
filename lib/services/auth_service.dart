// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/api_response_model.dart';
import '../models/user_model.dart';

class AuthService {
  Uri _url(String path) => Uri.parse('${ApiConstants.baseUrl}$path');
  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json', 'Accept': 'application/json'};
  Map<String, String> _authHeaders(String token) => {..._jsonHeaders, 'Authorization': 'Bearer $token'};

  ApiResponse<T> _parseResponse<T>(http.Response res, T Function(dynamic) fromData) {
    try {
      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 401) return ApiResponse.failure(body['error']?.toString() ?? 'Unauthorized');
      return ApiResponse.fromJson(body, fromData);
    } catch (_) {
      return ApiResponse.failure('Unexpected server response.');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(_url(ApiConstants.health), headers: _jsonHeaders).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<ApiResponse<Map<String, dynamic>>> register({required String username, required String email, required String password, required String primaryApiKey, String? fallbackApiKey}) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        'primary_key': primaryApiKey,
        if (fallbackApiKey != null) 'fallback_key': fallbackApiKey
      };
      final res = await http.post(_url(ApiConstants.register), headers: _jsonHeaders, body: jsonEncode(body));
      return _parseResponse(res, (d) => d as Map<String, dynamic>);
    } catch (_) { return ApiResponse.failure('Connection failed.'); }
  }

  Future<ApiResponse<Map<String, dynamic>>> login({required String email, required String password}) async {
    try {
      final res = await http.post(_url(ApiConstants.login), headers: _jsonHeaders, body: jsonEncode({'email': email, 'password': password}));
      return _parseResponse(res, (d) => d as Map<String, dynamic>);
    } catch (_) { return ApiResponse.failure('Connection failed.'); }
  }

  Future<ApiResponse<void>> logout(String token) async {
    try {
      final res = await http.post(_url(ApiConstants.logout), headers: _authHeaders(token));
      return _parseResponse(res, (_) {});
    } catch (_) { return ApiResponse.success(null); }
  }

  Future<ApiResponse<UserModel>> getMe(String token) async {
    try {
      final res = await http.get(_url(ApiConstants.me), headers: _authHeaders(token)).timeout(const Duration(seconds: 10));
      return _parseResponse(res, (d) => UserModel.fromJson(d));
    } catch (e) {
      // Differentiating network errors from logic errors.
      return ApiResponse.failure('NETWORK_ERROR: Could not connect to Yuki.');
    }
  }

  Future<ApiResponse<UserModel>> updateSettings({
    required String token,
    String? fallbackApiKey,
    bool? nsfwMode,
    String? activeModel,
    String? fullName,
    String? profilePic,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fallbackApiKey != null) body['fallback_key'] = fallbackApiKey;
      if (nsfwMode != null) body['nsfw_mode'] = nsfwMode;
      if (activeModel != null) body['model'] = activeModel;
      if (fullName != null) body['full_name'] = fullName;
      if (profilePic != null) body['profile_pic'] = profilePic;
      final res = await http.patch(_url(ApiConstants.settings), headers: _authHeaders(token), body: jsonEncode(body));
      return _parseResponse(res, (d) => UserModel.fromJson(d));
    } catch (_) { return ApiResponse.failure('Update failed.'); }
  }

  Future<ApiResponse<String>> generateYukiImpression(String token) async {
    try {
      final res = await http.post(_url(ApiConstants.generateImpression), headers: _authHeaders(token));
      return _parseResponse(res, (d) => d['yuki_impression']?.toString() ?? '');
    } catch (_) { return ApiResponse.failure('Failed to refresh Yuki\'s impression.'); }
  }
}
