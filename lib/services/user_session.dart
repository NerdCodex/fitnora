import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fitnora/services/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages the current user session and provides per-user scoping.
/// All local data paths (DB, images, Hive settings) use [userScope]
/// to isolate data between accounts.
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? _userScope;

  /// The per-user folder/box suffix derived from user email.
  /// Example: "u_a1b2c3d4"
  String get userScope {
    if (_userScope == null) {
      // Try to load from auth box
      final box = Hive.box('auth');
      final email = box.get('user_email') as String?;
      if (email != null) {
        _userScope = _emailToScope(email);
      } else {
        throw StateError('UserSession not initialized. Call init() after login.');
      }
    }
    return _userScope!;
  }

  /// Whether a user session is active.
  bool get isActive => _userScope != null || _tryLoadFromBox();

  bool _tryLoadFromBox() {
    final box = Hive.box('auth');
    final email = box.get('user_email') as String?;
    if (email != null) {
      _userScope = _emailToScope(email);
      return true;
    }
    return false;
  }

  /// Initialize the session after login/signup.
  /// Stores the email in auth box and derives the scope.
  Future<void> init(String email) async {
    final box = Hive.box('auth');
    await box.put('user_email', email.trim().toLowerCase());
    _userScope = _emailToScope(email);
  }

  /// Clear the session on logout.
  void clear() {
    _userScope = null;
  }

  /// Per-user Hive box name for settings.
  String get settingsBoxName => 'settings_$userScope';

  /// Open the per-user settings box.
  Future<Box> openSettingsBox() async {
    final boxName = settingsBoxName;
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Per-user images directory path segment (relative to app documents dir).
  /// E.g. "images/u_a1b2c3d4"
  String get imagesPath => '$local_images/$userScope';

  /// Derive a short, filesystem-safe scope string from email.
  String _emailToScope(String email) {
    final normalized = email.trim().toLowerCase();
    final hash = md5.convert(utf8.encode(normalized)).toString();
    return 'u_${hash.substring(0, 8)}';
  }
}
