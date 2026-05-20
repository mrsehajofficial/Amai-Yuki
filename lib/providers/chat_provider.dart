// chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/message_status.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final AuthProvider _authProvider;

  ChatProvider(this._chatService, this._authProvider) {
    _authProvider.addListener(_onAuthChange);
  }

  @override
  void dispose() { _authProvider.removeListener(_onAuthChange); super.dispose(); }
  void _onAuthChange() { if (!_authProvider.isAuthenticated) _clearLocalState(); }

  List<MessageModel> _messages = [];
  List<String> _availableModels = [];
  String _activeModel = 'omni';
  bool _isSending = false;
  bool _isHistoryLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreHistory = true;

  List<MessageModel> get messages => _messages;
  List<String> get availableModels => _availableModels;
  String get activeModel => _activeModel;
  bool get isSending => _isSending;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get error => _error;
  bool get hasMoreHistory => _hasMoreHistory;

  void _clearLocalState() { _messages.clear(); _currentPage = 1; _hasMoreHistory = true; _error = null; notifyListeners(); }
  void _setError(String message) { _error = message; notifyListeners(); }

  Future<void> initChat() async {
    if (!_authProvider.isAuthenticated) return;
    if (_authProvider.user?.activeModel != null) _activeModel = _authProvider.user!.activeModel!;
    await Future.wait([_loadModels(), loadHistory(refresh: true)]);
  }

  Future<void> _loadModels() async {
    final token = _authProvider.token; if (token == null) return;
    final res = await _chatService.getModels(token);
    if (res.success && res.data != null) {
      _availableModels = res.data!;
      if (_availableModels.isNotEmpty && !_availableModels.contains(_activeModel)) _activeModel = _availableModels.first;
      notifyListeners();
    }
  }

  void setActiveModel(String model) { if (_availableModels.contains(model)) { _activeModel = model; notifyListeners(); } }

  Future<void> loadHistory({bool refresh = false}) async {
    final token = _authProvider.token; if (token == null) return;
    if (refresh) { _currentPage = 1; _hasMoreHistory = true; _messages.clear(); }
    if (!_hasMoreHistory || _isHistoryLoading) return;
    _isHistoryLoading = true; _error = null; notifyListeners();
    final res = await _chatService.getHistory(token: token, page: _currentPage);
    if (res.success && res.data != null) {
      final newMessages = res.data!;
      if (newMessages.isEmpty) { _hasMoreHistory = false; } else {
        _messages.addAll(newMessages);
        _messages.sort((a, b) {
          final cmp = b.createdAt.compareTo(a.createdAt);
          if (cmp != 0) return cmp;
          // Tie-break with ID to ensure stable ordering for simultaneous messages
          return b.id.compareTo(a.id);
        });
        _currentPage++;
      }
    } else {
      if (res.errorMessage.contains('expired')) _authProvider.forceLogout(); else _setError(res.errorMessage);
    }
    _isHistoryLoading = false; notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    final token = _authProvider.token; final user = _authProvider.user;
    if (token == null || user == null || content.trim().isEmpty) return;
    _error = null;
    
    // Fetch custom prompt from local storage
    final customPrompt = await _authProvider.getCustomPrompt();

    final tempUserId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempUserMsg = MessageModel(
      id: tempUserId,
      role: MessageRole.user,
      content: content.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.insert(0, tempUserMsg);
    _isSending = true;
    notifyListeners();
    
    final timezone = _getTimezoneOffset();
    final res = await _chatService.sendMessage(
      token: token, 
      content: content.trim(), 
      model: _activeModel, 
      nsfwMode: user.nsfwMode,
      systemPrompt: customPrompt,
      timezone: timezone,
    );
    _isSending = false;
    if (res.success && res.data != null) {
      // Find the user's sent message and mark it as seen now that the AI has processed and replied to it.
      final index = _messages.indexWhere((m) => m.id == tempUserId);
      if (index != -1) {
        _messages[index] = MessageModel(
          id: _messages[index].id,
          role: _messages[index].role,
          content: _messages[index].content,
          createdAt: _messages[index].createdAt,
          status: MessageStatus.seen,
        );
      }
      _messages.insert(0, res.data!);
      notifyListeners();
    } else {
      _messages.removeWhere((m) => m.id == tempUserId);
      if (res.errorMessage.contains('expired')) _authProvider.forceLogout(); else _setError(res.errorMessage);
      notifyListeners();
    }
  }

  Future<bool> clearHistory() async {
    final token = _authProvider.token; if (token == null) return false;
    _isHistoryLoading = true; notifyListeners();
    final res = await _chatService.clearHistory(token);
    if (res.success) { _clearLocalState(); _isHistoryLoading = false; notifyListeners(); return true; } else {
      if (res.errorMessage.contains('expired')) _authProvider.forceLogout(); else _setError(res.errorMessage);
      _isHistoryLoading = false; notifyListeners(); return false;
    }
  }

  Future<bool> togglePinMessage(String messageId) async {
    final token = _authProvider.token; if (token == null) return false;
    final res = await _chatService.togglePinMessage(token: token, messageId: messageId);
    if (res.success && res.data != null) {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isPinned: res.data!);
        notifyListeners();
      }
      return res.data!;
    } else {
      if (res.errorMessage.contains('expired')) _authProvider.forceLogout(); else _setError(res.errorMessage);
      return false;
    }
  }

  String _getTimezoneOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$sign$hours:$minutes';
  }
}
