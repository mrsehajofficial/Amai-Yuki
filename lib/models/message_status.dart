// message_status.dart

/// Represents the delivery and read status of a message.
enum MessageStatus {
  /// The message is currently being sent (network transmission in progress).
  sending,

  /// The message has successfully reached the server.
  sent,

  /// The message has been delivered to the recipient's device.
  received,

  /// The message has been viewed/read by the recipient.
  seen,
}
