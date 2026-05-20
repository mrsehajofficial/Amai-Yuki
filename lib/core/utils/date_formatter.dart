// date_formatter.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

abstract final class DateFormatter {
  static const String _serverOffset = 'Z'; // Server database timestamps are stored and returned in UTC! - SV
  static String? _clientOffset;             // Dynamic client offset from IP lookup - SV
  static bool _isInitialized = false;

  /// Fetches client timezone offset dynamically via IP lookup.
  /// This bypasses emulator clock/timezone misconfigurations. - SV
  static Future<void> initializeTimezonesFromIp() async {
    if (_isInitialized) return;
    try {
      // Fetch client timezone offset dynamically using client's IP - SV
      final clientRes = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (clientRes.statusCode == 200) {
        final data = jsonDecode(clientRes.body);
        final String? offset = data['utc_offset']?.toString(); // e.g. "+0530" or "-0400"
        if (offset != null) {
          // Format from "+0530" to "+05:30"
          if (offset.length == 5) {
            _clientOffset = '${offset.substring(0, 3)}:${offset.substring(3, 5)}';
          } else {
            _clientOffset = offset;
          }
        }
      }
      _isInitialized = true;
    } catch (_) {
      // Catch silently, fallback to standard local timezone calculations - SV
    }
  }

  /// Converts any DateTime to the client's IP-based local timezone context, 
  /// correcting for any device or emulator clock/timezone discrepancies. - SV
  static DateTime _toIpContext(DateTime dt) {
    if (_clientOffset == null) return dt.toLocal();
    try {
      final clean = _clientOffset!.replaceAll(':', '');
      final sign = clean.startsWith('-') ? -1 : 1;
      final hours = int.parse(clean.substring(1, 3));
      final minutes = int.parse(clean.substring(3, 5));
      final offsetDuration = Duration(hours: hours, minutes: minutes) * sign;
      
      // Shift UTC time to the IP-based local timezone
      return dt.toUtc().add(offsetDuration);
    } catch (_) {
      return dt.toLocal();
    }
  }

  static String formatMessageTime(DateTime dateTime) {
    final now = _toIpContext(DateTime.now());
    final msgTime = _toIpContext(dateTime);
    final diff = now.difference(msgTime);
    
    if (diff.isNegative || diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(msgTime);
    return DateFormat('MMM d, h:mm a').format(msgTime);
  }

  static String formatRelative(DateTime dateTime) => formatMessageTime(dateTime);

  static String formatHistoryTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(_toIpContext(dateTime));
  }

  /// Parses the raw timestamp string returned by the PythonAnywhere backend.
  /// The database stores all message/conversation times in UTC format. - SV
  static DateTime parseApiTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    try {
      String parseStr = raw.trim();
      
      if (!parseStr.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(parseStr)) {
        final regex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})');
        final match = regex.firstMatch(parseStr);
        if (match != null) {
          // Reconstruct ISO 8601 string as UTC ('Z') - SV
          parseStr = '${match.group(1)}-${match.group(2)}-${match.group(3)}T${match.group(4)}:${match.group(5)}:${match.group(6)}$_serverOffset';
        } else {
          if (parseStr.contains(' ')) {
            parseStr = parseStr.replaceFirst(' ', 'T');
          }
          parseStr = parseStr + _serverOffset;
        }
      }
      return DateTime.parse(parseStr);
    } catch (e, stack) {
      // Output detailed debugging info so we can instantly trace any parsing issues in logs. - SV
      print('ERROR parsing timestamp "$raw": $e\n$stack');
      return DateTime.now();
    }
  }
}
