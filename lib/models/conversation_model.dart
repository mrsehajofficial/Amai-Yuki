// conversation_model.dart
import 'user_model.dart';
import '../core/utils/date_formatter.dart';

class ConversationModel {
  final String otherUserId;
  final String otherUsername;
  final String? otherUserFullName;
  final String? otherUserEmail;
  final bool otherUserIsOnline;
  final String? otherUserProfilePic;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String? lastMessageReaction; // Added - SV

  const ConversationModel({
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserFullName,
    this.otherUserEmail,
    required this.otherUserIsOnline,
    this.otherUserProfilePic,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.lastMessageReaction, // Added - SV
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      otherUserId: (json['other_user_id'] ?? json['user_id'])?.toString() ?? '',
      otherUsername: (json['other_username'] ?? json['username'])?.toString() ?? '',
      otherUserFullName: json['full_name']?.toString(),
      otherUserEmail: json['email']?.toString(),
      otherUserIsOnline: json['other_user_is_online'] == 1 || json['other_user_is_online'] == true || json['is_online'] == true,
      otherUserProfilePic: json['other_user_profile_pic']?.toString() ?? json['profile_pic']?.toString(),
      lastMessage: json['last_message']?.toString() ?? '',
      timestamp: DateFormatter.parseApiTimestamp(json['timestamp']?.toString()),
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageReaction: json['last_message_reaction']?.toString() ?? json['reaction']?.toString(), // Added - SV
    );
  }
}
