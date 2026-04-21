import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the current user's session data (token, profile info).
/// Data is persisted with SharedPreferences so it survives app restarts.
class UserSession {
  static const String _keyToken = 'user_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserProvider = 'user_provider';
  static const String _keyUserCreatedAt = 'user_created_at';

  // In-memory cache so we don't hit disk on every read
  static String? _token;
  static int? _userId;
  static String? _userName;
  static String? _userEmail;
  static String? _userRole;
  static String? _userProvider;
  static String? _userCreatedAt;

  /// Save session after a successful login / register response.
  /// Expected [data] shape from backend:
  /// ```json
  /// {
  ///   "access_token": "...",
  ///   "user": { "id": 1, "name": "...", "email": "...", ... }
  /// }
  /// ```
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    _token = (data['access_token'] ?? data['token'] ?? data['accessToken'] ?? data['jwt'] ?? data['auth_token']) as String?;
    if (_token == null) {
       // Coba cari key yang berbau 'token' di dalam map
       for (final key in data.keys) {
         if (key.toLowerCase().contains('token')) {
           _token = data[key] as String?;
           break;
         }
       }
    }

    if (_token != null) {
      await prefs.setString(_keyToken, _token!);
    }

    // Check if user data is nested under 'user' key, else assume flat structure
    final user = data['user'] as Map<String, dynamic>? ?? data;
    
    // Some backends return just the token here, meaning we should not overwrite user info with nulls
    // So we only update if we find an email or id in the payload.
    if (user['email'] != null || user['id'] != null) {
      _userId = user['id'] as int?;
      _userName = user['name'] as String?;
      _userEmail = user['email'] as String?;
      _userRole = user['role'] as String?;
      _userProvider = user['provider'] as String?;
      _userCreatedAt = user['created_at'] as String?;


      if (_userId != null) await prefs.setInt(_keyUserId, _userId!);
      if (_userName != null) await prefs.setString(_keyUserName, _userName!);
      if (_userEmail != null) await prefs.setString(_keyUserEmail, _userEmail!);
      if (_userRole != null) await prefs.setString(_keyUserRole, _userRole!);
      if (_userProvider != null) await prefs.setString(_keyUserProvider, _userProvider!);
      if (_userCreatedAt != null) await prefs.setString(_keyUserCreatedAt, _userCreatedAt!);
    }
  }

  /// Load session from disk into memory (call once at app start or on screen init).
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _userId = prefs.getInt(_keyUserId);
    _userName = prefs.getString(_keyUserName);
    _userEmail = prefs.getString(_keyUserEmail);
    _userRole = prefs.getString(_keyUserRole);
    _userProvider = prefs.getString(_keyUserProvider);
    _userCreatedAt = prefs.getString(_keyUserCreatedAt);
  }

  /// Clear session data (logout).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserProvider);
    await prefs.remove(_keyUserCreatedAt);

    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    _userProvider = null;
    _userCreatedAt = null;
  }

  // ---------- Getters ----------

  static String? get token => _token;
  static int? get userId => _userId;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static String? get userRole => _userRole;
  static String? get userProvider => _userProvider;
  static String? get userCreatedAt => _userCreatedAt;

  static bool get isLoggedIn => _token != null && _userId != null;

  /// Convenience: returns the Authorization header value.
  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Update the cached user name (e.g. after editing profile).
  static Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }
}
