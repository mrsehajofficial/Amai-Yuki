// chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/api_response_model.dart';
import '../models/message_model.dart';

class ChatService {
  Uri _url(String path) => Uri.parse('${ApiConstants.baseUrl}$path');
  Map<String, String> _authHeaders(String token) => {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'};

  ApiResponse<T> _parseResponse<T>(http.Response res, T Function(dynamic) fromData) {
    try {
      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 401) return ApiResponse.failure('Session expired.');
      return ApiResponse.fromJson(body, fromData);
    } catch (_) { return ApiResponse.failure('Unexpected server response.'); }
  }

  Future<ApiResponse<MessageModel>> sendMessage({
    required String token, 
    required String content, 
    required String model, 
    required bool nsfwMode, 
    String? systemPrompt,
    String? timezone,
  }) async {
    try {
      final body = {
        'message': content, 
        'model': model, 
        'nsfw': nsfwMode,
        if (systemPrompt != null && systemPrompt.isNotEmpty) 'system_prompt': systemPrompt,
        if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
      };
      final res = await http.post(_url(ApiConstants.chatSend), headers: _authHeaders(token), body: jsonEncode(body));
      return _parseResponse(res, (d) => MessageModel.fromJson(d));
    } catch (_) { return ApiResponse.failure('Message send failed.'); }
  }

  Future<ApiResponse<List<MessageModel>>> getHistory({required String token, int page = 1, int pageSize = 20}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatHistory}').replace(queryParameters: {'page': page.toString(), 'limit': pageSize.toString()});
      final res = await http.get(uri, headers: _authHeaders(token));
      return _parseResponse(res, (d) {
        final messages = d['messages'] as List;
        return messages.map((e) => MessageModel.fromJson(e)).toList();
      });
    } catch (_) { return ApiResponse.failure('History load failed.'); }
  }

  Future<ApiResponse<void>> clearHistory(String token) async {
    try {
      final res = await http.delete(_url(ApiConstants.chatClear), headers: _authHeaders(token));
      return _parseResponse(res, (_) {});
    } catch (_) { return ApiResponse.failure('Clear failed.'); }
  }

  Future<ApiResponse<bool>> togglePinMessage({required String token, required String messageId}) async {
    try {
      final res = await http.post(_url('/chat/messages/$messageId/pin'), headers: _authHeaders(token));
      return _parseResponse(res, (d) => d['is_pinned'] == true || d['is_pinned'] == 1);
    } catch (_) { return ApiResponse.failure('Pin toggle failed.'); }
  }

  Future<ApiResponse<List<String>>> getModels(String token) async {
    try {
      final res = await http.get(_url(ApiConstants.chatModels), headers: _authHeaders(token));
      return _parseResponse(res, (d) {
        // The backend returns a response with 'data' field containing a map like:
        // {'models': [...], 'default': '...'}
        // We unpack the 'models' array from the map, or fallback directly to list/raw map data.
        final rawModels = d is Map ? (d['models'] ?? d) : d;
        if (rawModels is List) {
          return rawModels.map((e) => e is String ? e : (e['name']?.toString() ?? e.toString())).toList().cast<String>();
        }
        return <String>[];
      });
    } catch (_) { return ApiResponse.failure('Models load failed.'); }
  }
}
