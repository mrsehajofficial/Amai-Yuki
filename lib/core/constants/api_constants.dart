// api_constants.dart
abstract final class ApiConstants {
  static const String baseUrl = 'https://yukiamai.pythonanywhere.com';
  static const String health = '/health';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String settings = '/auth/settings';
  static const String chatSend = '/chat/send';
  static const String chatHistory = '/chat/history';
  static const String chatClear = '/chat/clear';
  static const String chatModels = '/chat/models';

  // Direct Chat
  static const String usersList = '/users/list';
  static const String directConversations = '/direct/conversations';
  static const String directHistory = '/direct/history/'; // Needs ID appended
  static const String directSend = '/direct/send';
  static const String directClear = '/direct/clear/'; // Needs ID appended
  static const String heartbeat = '/auth/heartbeat';
  static const String generateImpression = '/chat/impression/generate';
}
