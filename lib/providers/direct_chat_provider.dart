// direct_chat_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/constants/api_constants.dart';
import '../models/conversation_model.dart';
import '../models/direct_message_model.dart';
import '../models/user_model.dart';
import '../services/direct_chat_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class DirectChatProvider with ChangeNotifier, WidgetsBindingObserver {
  final DirectChatService _service;
  final AuthProvider _auth;
  final StorageService _storage;

  List<UserModel> _users = [];
  List<UserModel> _searchResults = [];
  List<ConversationModel> _conversations = [];
  List<DirectMessageModel> _currentHistory = [];
  final Set<String> _unseenReactionUserIds = {}; // Tracks conversations with unseen message reactions - SV
  bool _isLoadingUsers = false;
  bool _isLoadingConversations = false;
  bool _isLoadingHistory = false;
  bool _isSending = false;
  bool _isSearching = false;

  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  String? _activeChatUserId;
  List<String> _favoriteUserIds = [];
  int _pollCount = 0; // Tracks polling cycles to refresh users list periodically - SV

  // Tracks whether the application is running in the foreground to prevent showing 
  // duplicate status-bar notifications when the user is actively viewing a chat, 
  // while ensuring we alert them immediately if the app is minimized/backgrounded! - SV
  bool _isInForeground = true;

  DirectChatProvider(this._service, this._auth, this._storage) {
    _loadFavorites();

    // Bind life-cycle observer to native app state transitions. - SV
    WidgetsBinding.instance.addObserver(this);

    if (_auth.isAuthenticated) {
      _startHeartbeat();
      _startPolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep track of whether the user is actively engaged in the app. - SV
    _isInForeground = state == AppLifecycleState.resumed;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    _favoriteUserIds = await _storage.getFavorites();
    notifyListeners();
  }

  List<String> get favoriteUserIds => _favoriteUserIds;

  List<UserModel> get favoriteUsers {
    final favs = _users.where((u) => _favoriteUserIds.contains(u.id)).toList();
    favs.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return 0;
    });
    return favs;
  }

  bool isFavorite(String userId) => _favoriteUserIds.contains(userId);

  Future<void> toggleFavorite(String userId) async {
    if (_favoriteUserIds.contains(userId)) {
      _favoriteUserIds.remove(userId);
    } else {
      _favoriteUserIds.add(userId);
    }
    await _storage.saveFavorites(_favoriteUserIds);
    notifyListeners();
  }

  List<UserModel> get users => _users;
  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  void searchUsers(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _users.where((u) => u.username.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }
  List<ConversationModel> get conversations => _conversations;
  List<DirectMessageModel> get currentHistory => _currentHistory;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSending => _isSending;

  /// Check if a specific conversation has a new, unseen message reaction - SV
  bool hasUnseenReaction(String userId) => _unseenReactionUserIds.contains(userId);

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_auth.isAuthenticated) {
        _service.heartbeat(_auth.token!);
      }
    });
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_auth.isAuthenticated) {
        refreshConversations();
        
        _pollCount++;
        // Periodically refresh the entire users cache silently every 15 seconds (3 ticks) 
        // to sync live profile picture changes and real-time online status - SV
        if (_pollCount % 3 == 0) {
          _fetchUsersSilently();
        }
        
        if (_activeChatUserId != null) {
          _fetchHistorySilently(_activeChatUserId!);
        }
      }
    });
  }

  Future<void> fetchUsers() async {
    if (!_auth.isAuthenticated) return;
    _isLoadingUsers = true; notifyListeners();
    print('DEBUG: Fetching users from ${ApiConstants.usersList}');
    final res = await _service.getUsers(_auth.token!);
    if (res.success) {
      print('DEBUG: Successfully fetched ${res.data?.length} users');
      _users = res.data ?? [];
    } else {
      print('DEBUG: Failed to fetch users: ${res.error}');
    }
    _isLoadingUsers = false; notifyListeners();
  }

  // Refreshes the entire users cache in the background without triggering loading shimmers - SV
  Future<void> _fetchUsersSilently() async {
    if (!_auth.isAuthenticated) return;
    final res = await _service.getUsers(_auth.token!);
    if (res.success && res.data != null) {
      final newUsers = res.data!;
      bool hasChanges = false;

      if (newUsers.length != _users.length) {
        _users = newUsers;
        hasChanges = true;
      } else {
        for (int i = 0; i < _users.length; i++) {
          final oldUser = _users[i];
          final newUser = newUsers.firstWhere(
            (u) => u.id == oldUser.id,
            orElse: () => oldUser,
          );
          if (newUser.profilePic != oldUser.profilePic ||
              newUser.isOnline != oldUser.isOnline ||
              newUser.fullName != oldUser.fullName ||
              newUser.username != oldUser.username ||
              newUser.yukiImpression != oldUser.yukiImpression) {
            _users[i] = newUser;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        notifyListeners();
      }
    }
  }

  Future<void> refreshConversations() async {
    if (!_auth.isAuthenticated) return;
    final res = await _service.getConversations(_auth.token!);
    if (res.success && res.data != null) {
      final newConvos = res.data!;
      
      // Check for new messages and reactions in conversations we are NOT currently viewing
      if (_conversations.isNotEmpty) {
        for (var newConvo in newConvos) {
          final oldConvo = _conversations.cast<ConversationModel?>().firstWhere(
            (c) => c?.otherUserId == newConvo.otherUserId, 
            orElse: () => null
          );
          
          // If the app is minimized or backgrounded, we must show notifications even for the 
          // active chat, since the user is not currently viewing the foreground screen! - SV
          if (!_isInForeground || newConvo.otherUserId != _activeChatUserId) {
            // If the unread count increased, or it's a completely new conversation with unread messages
            if ((oldConvo == null && newConvo.unreadCount > 0) || 
                (oldConvo != null && newConvo.unreadCount > oldConvo.unreadCount)) {
              
              // Standard payload encoding containing receiver keys to trigger deep linking when tapped. - SV
              final payload = jsonEncode({
                'otherUserId': newConvo.otherUserId,
                'otherUsername': newConvo.otherUsername,
                'otherUserFullName': newConvo.otherUserFullName,
              });

              NotificationService().showNotification(
                id: newConvo.otherUserId.hashCode,
                title: newConvo.otherUserFullName ?? newConvo.otherUsername,
                body: newConvo.lastMessage,
                payload: payload,
              );
            }
          }

          // Check for incoming reactions in real-time - SV
          if (newConvo.lastMessageReaction != null && newConvo.lastMessageReaction!.isNotEmpty) {
            final oldReaction = oldConvo?.lastMessageReaction;
            if (oldReaction != newConvo.lastMessageReaction) {
              if (_activeChatUserId != newConvo.otherUserId) {
                // Track this conversation as having an unseen reaction
                _unseenReactionUserIds.add(newConvo.otherUserId);
                
                // Show notification if app is in background or we are not currently viewing this chat
                if (!_isInForeground || newConvo.otherUserId != _activeChatUserId) {
                  NotificationService().showNotification(
                    id: newConvo.otherUserId.hashCode + 1, // Unique ID offset for reaction notifications
                    title: newConvo.otherUserFullName ?? newConvo.otherUsername,
                    body: '${newConvo.lastMessageReaction} Reacted to your message',
                    payload: jsonEncode({
                      'otherUserId': newConvo.otherUserId,
                      'otherUsername': newConvo.otherUsername,
                      'otherUserFullName': newConvo.otherUserFullName,
                    }),
                  );
                }
              }
            }
          }
        }
      }

      // Verify if the conversation list has actual structural changes, updated last messages, or 
      // changed state flags before invoking notifyListeners() to prevent redundant widget rebuilds 
      // and layout list animations from re-triggering unnecessarily. - SV
      bool listChanged = false;
      if (newConvos.length != _conversations.length) {
        listChanged = true;
      } else {
        for (int i = 0; i < newConvos.length; i++) {
          final n = newConvos[i];
          final o = _conversations[i];
          if (n.otherUserId != o.otherUserId ||
              n.lastMessage != o.lastMessage ||
              n.timestamp.millisecondsSinceEpoch != o.timestamp.millisecondsSinceEpoch ||
              n.unreadCount != o.unreadCount ||
              n.otherUserIsOnline != o.otherUserIsOnline ||
              n.otherUserProfilePic != o.otherUserProfilePic ||
              n.lastMessageReaction != o.lastMessageReaction) {
            listChanged = true;
            break;
          }
        }
      }

      if (listChanged) {
        _conversations = newConvos;
        notifyListeners();
      }
    }
  }

  Future<void> setActiveChat(String? userId) async {
    _activeChatUserId = userId;
    if (userId != null) {
      // Clear the local notification for this user immediately upon entering the chat. 
      // This solves the 'notification should disappear on opening chat' requirement perfectly. - SV
      NotificationService().cancelNotification(userId.hashCode);
      NotificationService().cancelNotification(userId.hashCode + 1); // Also cancel reaction notifications - SV

      // Clear the unseen reaction flag as the user is now viewing the chat! - SV
      _unseenReactionUserIds.remove(userId);

      _isLoadingHistory = true; notifyListeners();
      await _fetchHistorySilently(userId);
      _isLoadingHistory = false; notifyListeners();
    } else {
      _currentHistory = [];
      notifyListeners();
    }
  }

  Future<void> _fetchHistorySilently(String userId) async {
    if (!_auth.isAuthenticated) return;

    // Load from cache first for instant UI response
    final cachedHistory = await _storage.getDirectHistory(userId);
    if (cachedHistory != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedHistory);
        _currentHistory = decoded.map((m) => DirectMessageModel.fromJson(m)).toList();
        notifyListeners();
      } catch (_) {}
    }

    final res = await _service.getHistory(_auth.token!, userId);
    if (res.success) {
      _currentHistory = res.data ?? [];
      
      // Save to cache
      final encodedHistory = jsonEncode(_currentHistory.map((m) => m.toJson()).toList());
      await _storage.saveDirectHistory(userId, encodedHistory);
      
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String receiverId, String content) async {
    if (!_auth.isAuthenticated || _auth.user == null) return false;
    
    // 1. Optimistic UI Update: Create a temporary message and show it immediately
    final tempMsgId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = DirectMessageModel(
      id: tempMsgId,
      senderId: _auth.user!.id,
      receiverId: receiverId,
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    
    _currentHistory.insert(0, tempMsg);
    _isSending = true; 
    notifyListeners();

    // 2. Send to backend
    final res = await _service.sendMessage(_auth.token!, receiverId, content.trim());
    _isSending = false;
    
    // 3. Replace temp message with actual data from backend
    _currentHistory.removeWhere((m) => m.id == tempMsgId);
    
    if (res.success && res.data != null) {
      _currentHistory.insert(0, res.data!);
      
      // Update cache
      if (_activeChatUserId != null) {
        final encodedHistory = jsonEncode(_currentHistory.map((m) => m.toJson()).toList());
        await _storage.saveDirectHistory(_activeChatUserId!, encodedHistory);
      }
      notifyListeners();
      return true;
    }
    
    // If failed, the temp message was already removed, just notify to update UI
    notifyListeners();
    return false;
  }

  Future<void> clearChat(String otherUserId) async {
    if (!_auth.isAuthenticated) return;
    final res = await _service.clearChat(_auth.token!, otherUserId);
    if (res.success) {
      _currentHistory = [];
      await _storage.saveDirectHistory(otherUserId, '[]');
      await refreshConversations();
      notifyListeners();
    }
  }

  Future<bool> reactToMessage(String messageId, String? reaction) async {
    if (!_auth.isAuthenticated) return false;

    // 1. Optimistic UI Update: Update the message reaction state locally for zero UI lag
    final index = _currentHistory.indexWhere((m) => m.id == messageId);
    String? oldReaction;
    if (index != -1) {
      oldReaction = _currentHistory[index].reaction;
      _currentHistory[index] = _currentHistory[index].copyWith(reaction: reaction);
      notifyListeners();
    }

    // 2. Execute network request to backend
    final res = await _service.reactToMessage(_auth.token!, messageId, reaction);
    if (res.success) {
      // Persist the updated state to offline cache
      if (_activeChatUserId != null) {
        final encodedHistory = jsonEncode(_currentHistory.map((m) => m.toJson()).toList());
        await _storage.saveDirectHistory(_activeChatUserId!, encodedHistory);
      }
      return true;
    }

    // 3. Fallback Rollback: Revert to previous state if the request fails
    if (index != -1) {
      _currentHistory[index] = _currentHistory[index].copyWith(reaction: oldReaction);
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    // Unbind observer to prevent memory leaks during hot reload or provider destruction. - SV
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
