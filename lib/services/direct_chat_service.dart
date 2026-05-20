// direct_chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/api_response_model.dart';
import '../models/conversation_model.dart';
import '../models/direct_message_model.dart';
import '../models/user_model.dart';

class DirectChatService {
  Uri _url(String path) => Uri.parse('${ApiConstants.baseUrl}$path');
  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json', 'Accept': 'application/json'};
  Map<String, String> _authHeaders(String token) => {..._jsonHeaders, 'Authorization': 'Bearer $token'};

  ApiResponse<T> _parseResponse<T>(http.Response res, T Function(dynamic) fromData) {
    try {
      print('DEBUG: Raw Response (${res.statusCode}): ${res.body}');
      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 401) return ApiResponse.failure('Session expired.');
      return ApiResponse.fromJson(body, fromData);
    } catch (e) {
      print('DEBUG: Parsing Error: $e');
      return ApiResponse.failure('Unexpected server response.');
    }
  }

  Future<ApiResponse<List<UserModel>>> getUsers(String token) async {
    try {
      final res = await http.get(_url(ApiConstants.usersList), headers: _authHeaders(token));
      return _parseResponse(res, (d) => (d['users'] as List).map((u) => UserModel.fromJson(u)).toList());
    } catch (_) { return ApiResponse.failure('Failed to load users.'); }
  }

  Future<ApiResponse<List<ConversationModel>>> getConversations(String token) async {
    try {
      final res = await http.get(_url(ApiConstants.directConversations), headers: _authHeaders(token));
      return _parseResponse(res, (d) => (d['conversations'] as List).map((c) => ConversationModel.fromJson(c)).toList());
    } catch (_) { return ApiResponse.failure('Failed to load conversations.'); }
  }

  Future<ApiResponse<List<DirectMessageModel>>> getHistory(String token, String otherUserId) async {
    try {
      final res = await http.get(_url('${ApiConstants.directHistory}$otherUserId'), headers: _authHeaders(token));
      return _parseResponse(res, (d) => (d['messages'] as List).map((m) => DirectMessageModel.fromJson(m)).toList().reversed.toList());
    } catch (_) { return ApiResponse.failure('Failed to load chat history.'); }
  }

  Future<ApiResponse<DirectMessageModel>> sendMessage(String token, String receiverId, String content) async {
    try {
      final res = await http.post(
        _url(ApiConstants.directSend),
        headers: _authHeaders(token),
        body: jsonEncode({'receiver_id': receiverId, 'content': content}),
      );
      return _parseResponse(res, (d) => DirectMessageModel.fromJson(d));
    } catch (_) { return ApiResponse.failure('Failed to send message.'); }
  }

  Future<ApiResponse<void>> clearChat(String token, String otherUserId) async {
    try {
      final res = await http.delete(_url('${ApiConstants.directClear}$otherUserId'), headers: _authHeaders(token));
      return _parseResponse(res, (_) {});
    } catch (_) { return ApiResponse.failure('Failed to clear chat.'); }
  }

  Future<void> heartbeat(String token) async {
    try {
      await http.post(_url(ApiConstants.heartbeat), headers: _authHeaders(token));
    } catch (_) {}
  }

  Future<ApiResponse<void>> reactToMessage(String token, String messageId, String? reaction) async {
    try {
      final res = await http.post(
        _url('/direct/react'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'message_id': int.tryParse(messageId) ?? messageId, 
          'reaction': reaction
        }),
      );
      return _parseResponse(res, (_) {});
    } catch (_) { return ApiResponse.failure('Failed to react to message.'); }
  }
}
