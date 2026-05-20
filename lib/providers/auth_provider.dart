// auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../core/theme/app_colors.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthProvider(this._authService, this._storageService);

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool _enterToSend = false;
  bool _isAmoled = false;
  ThemeMode _themeMode = ThemeMode.system;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get enterToSend => _enterToSend;
  bool get isAmoled => _isAmoled;
  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _token != null && _user != null;

  void _setLoading(bool value) { _isLoading = value; if (value) _error = null; notifyListeners(); }
  void _setError(String message) { _error = message; _isLoading = false; notifyListeners(); }

  Future<bool> init() async {
    if (_isInitialized) return isAuthenticated;
    _setLoading(true);
    _enterToSend = await _storageService.getEnterToSend();
    _isAmoled = await _storageService.getIsAmoled();
    final storedTheme = await _storageService.getThemeMode();
    _themeMode = _parseThemeMode(storedTheme);
    
    final storedToken = await _storageService.getToken();
    
    // If no token exists, we're definitely not authenticated.
    if (storedToken == null) {
      _isInitialized = true;
      _setLoading(false);
      return false;
    }

    final res = await _authService.getMe(storedToken);
    
    if (res.success && res.data != null) {
      _token = storedToken;
      _user = res.data;
      
      // Sync local preferences with server data
      await _storageService.saveNsfwMode(_user!.nsfwMode);
      if (_user!.activeModel != null) {
        await _storageService.saveActiveModel(_user!.activeModel!);
      }
      
      _isInitialized = true;
      _setLoading(false);
      return true;
    } else {
      // CRITICAL: We only clear the token if the server explicitly tells us it's invalid.
      // If it's a network error, we keep the token so the user can try again later
      // without being forced to log in from scratch.
      final isAuthError = res.error?.contains('NETWORK_ERROR') == false;
      
      if (isAuthError) {
        // Only wipe if it's a legitimate "Unauthorized" or "Invalid" response.
        await _storageService.clearToken();
        _token = null;
        _user = null;
      }
      
      _isInitialized = true;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    final res = await _authService.login(email: email, password: password);
    if (res.success && res.data != null) {
      final newToken = res.data!['token'] as String;
      await _storageService.saveToken(newToken); _token = newToken;
      final profileRes = await _authService.getMe(newToken);
      if (profileRes.success && profileRes.data != null) {
        _user = profileRes.data; await _storageService.saveNsfwMode(_user!.nsfwMode);
        _isInitialized = true;
        _setLoading(false); return true;
      } else { _setError('Profile load failed.'); return false; }
    } else { _setError(res.errorMessage); return false; }
  }

  Future<bool> register({required String username, required String email, required String password, required String primaryApiKey, String? fallbackApiKey}) async {
    _setLoading(true);
    final res = await _authService.register(username: username, email: email, password: password, primaryApiKey: primaryApiKey, fallbackApiKey: fallbackApiKey);
    if (res.success) { _setLoading(false); return login(email, password); } else { _setError(res.errorMessage); return false; }
  }

  Future<void> logout() async {
    final oldToken = _token;
    
    // Clear local state immediately for instant UI response
    _token = null;
    _user = null;
    _isInitialized = true;
    notifyListeners();

    try {
      if (oldToken != null) await _authService.logout(oldToken);
    } catch (_) {}
    
    await _storageService.clearAll();
  }

  void forceLogout() { _storageService.clearAll(); _token = null; _user = null; notifyListeners(); }

  Future<bool> updateSettings({
    String? fallbackApiKey,
    bool? nsfwMode,
    String? activeModel,
    String? fullName,
    String? profilePic,
  }) async {
    if (_token == null || _user == null) return false;

    // Cache the previous user state in case we need to roll back - SV
    final previousUser = _user;
    final previousNsfwMode = _user!.nsfwMode;
    final previousActiveModel = _user!.activeModel;

    // 1. Optimistic Update: Immediately apply switches and notify UI so toggles slide with zero lag - SV
    if (nsfwMode != null) {
      _user = _user!.copyWith(nsfwMode: nsfwMode);
      await _storageService.saveNsfwMode(nsfwMode);
      notifyListeners();
    }
    if (activeModel != null) {
      _user = _user!.copyWith(activeModel: activeModel);
      await _storageService.saveActiveModel(activeModel);
      notifyListeners();
    }
    if (fullName != null || profilePic != null) {
      _user = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        profilePic: profilePic ?? _user!.profilePic,
      );
      notifyListeners();
    }

    try {
      final res = await _authService.updateSettings(
        token: _token!,
        fallbackApiKey: fallbackApiKey,
        nsfwMode: nsfwMode,
        activeModel: activeModel,
        fullName: fullName,
        profilePic: profilePic,
      );

      if (res.success) {
        // Sync final server profile state with local memory - SV
        final profileRes = await _authService.getMe(_token!);
        if (profileRes.success && profileRes.data != null) {
          _user = profileRes.data;
          notifyListeners();
          return true;
        }
      }
      throw Exception(res.errorMessage ?? 'Server rejected settings update');
    } catch (e) {
      // 2. Rollback: Restore previous local state immediately if backend sync failed - SV
      _user = previousUser;
      if (nsfwMode != null) {
        await _storageService.saveNsfwMode(previousNsfwMode);
      }
      if (activeModel != null && previousActiveModel != null) {
        await _storageService.saveActiveModel(previousActiveModel);
      }
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> saveCustomPrompt(String prompt) async {
    await _storageService.saveCustomPrompt(prompt);
    notifyListeners();
  }

  Future<String?> getCustomPrompt() => _storageService.getCustomPrompt();

  Future<void> setEnterToSend(bool value) async {
    _enterToSend = value;
    await _storageService.saveEnterToSend(value);
    notifyListeners();
  }

  Future<void> setIsAmoled(bool value) async {
    _isAmoled = value;
    await _storageService.saveIsAmoled(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storageService.saveThemeMode(mode.name);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.system;
    }
  }

  Future<String?> generateYukiImpression() async {
    if (_token == null || _user == null) return null;
    _setLoading(true);
    final res = await _authService.generateYukiImpression(_token!);
    if (res.success && res.data != null) {
      _user = _user!.copyWith(yukiImpression: res.data);
      _setLoading(false);
      return res.data;
    }
    _setError(res.errorMessage);
    return null;
  }
}
