// storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyNsfwMode = 'nsfw_mode';
  static const String _keyActiveModel = 'active_model';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  Future<void> saveNsfwMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNsfwMode, enabled);
  }

  Future<bool> getNsfwMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNsfwMode) ?? false;
  }

  Future<void> saveActiveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveModel, model);
  }

  Future<String?> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveModel);
  }

  Future<void> saveCustomPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_prompt', prompt);
  }

  Future<String?> getCustomPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_prompt');
  }

  Future<void> saveDirectHistory(String userId, String historyJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('direct_history_$userId', historyJson);
  }

  Future<String?> getDirectHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('direct_history_$userId');
  }

  Future<void> saveIsAmoled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_amoled', enabled);
  }

  Future<bool> getIsAmoled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_amoled') ?? false;
  }

  Future<void> saveEnterToSend(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enter_to_send', enabled);
  }

  Future<bool> getEnterToSend() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enter_to_send') ?? false;
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') ?? 'dark';
  }

  Future<void> saveFavorites(List<String> userIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_users', userIds);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favorite_users') ?? [];
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
