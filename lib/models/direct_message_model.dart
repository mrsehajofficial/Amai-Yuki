// direct_message_model.dart
import '../core/utils/date_formatter.dart';
import 'message_status.dart';

class DirectMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  
  // Tracks if the recipient has read this message.
  final bool isRead;

  // Custom status override used primarily for optimistic UI transitions.
  final MessageStatus? customStatus;

  // Stores the active emoji reaction for this message.
  final String? reaction;

  const DirectMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.customStatus,
    this.reaction,
  });

  /// Computes the active delivery/read status of the message.
  MessageStatus get status {
    if (customStatus != null) return customStatus!;
    if (id.startsWith('temp_')) return MessageStatus.sending;
    return isRead ? MessageStatus.seen : MessageStatus.received;
  }

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    return DirectMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: DateFormatter.parseApiTimestamp(json['timestamp']?.toString()),
      // Parse the standard is_read flag from the backend
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      // Parse the nullable emoji reaction string
      reaction: json['reaction']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'reaction': reaction,
    };
  }

  DirectMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageStatus? customStatus,
    String? reaction,
  }) {
    return DirectMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      customStatus: customStatus ?? this.customStatus,
      reaction: reaction ?? this.reaction,
    );
  }

  bool isMe(String currentUserId) => senderId == currentUserId;
}
