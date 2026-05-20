import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';
import 'message_status.dart';

enum MessageRole {
  user,
  assistant;

  static MessageRole fromString(String? raw) {
    if (raw == 'assistant') return MessageRole.assistant;
    return MessageRole.user;
  }
}

class MessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  
  // The transmission and read status of this message.
  // Defaults to seen since loaded historical chat messages are already viewed.
  final MessageStatus status;

  const MessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.status = MessageStatus.seen,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? LocalIdGenerator.generate(),
      role: MessageRole.fromString(json['role']?.toString() ?? 'assistant'),
      content: (json['content'] ?? json['reply'])?.toString() ?? '',
      createdAt: DateFormatter.parseApiTimestamp((json['timestamp'] ?? json['created_at'])?.toString()),
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      // Any message successfully pulled from the history has already been read/processed.
      status: MessageStatus.seen,
    );
  }

  MessageModel copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? isPinned,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      status: status ?? this.status,
    );
  }

  bool get isAssistant => role == MessageRole.assistant;
  bool get isUser => role == MessageRole.user;
}

abstract final class LocalIdGenerator {
  static int _counter = 0;
  static String generate() => 'local_${_counter++}';
}
