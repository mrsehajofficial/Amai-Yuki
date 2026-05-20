// avatar_helper.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';

abstract final class AvatarHelper {
  /// Resolves any avatar image source (base64 data URI or HTTP url) into a beautiful ImageProvider.
  /// Bypasses network errors when rendering locally stored base64 gallery picks. - SV
  static ImageProvider getAvatarProvider(String avatarUrl) {
    if (avatarUrl.startsWith('data:image')) {
      try {
        final base64Content = avatarUrl.split(',').last;
        return MemoryImage(base64Decode(base64Content));
      } catch (_) {
        // Fallback to a transparent dummy image if base64 decoding fails - SV
        return const NetworkImage(''); 
      }
    }
    return NetworkImage(avatarUrl);
  }
}
