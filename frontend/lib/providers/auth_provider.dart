import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('current_user');
    if (data != null) {
      _currentUser = User.fromJson(jsonDecode(data));
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    // Demo login logic
    final demoUser = User(
      id: 'demo_user',
      name: 'Amina Hassan',
      phone: phone,
      email: 'amina@example.com',
      role: UserRole.citizen,
      createdAt: DateTime.now(),
      isVerified: true,
      mtaa: 'Kariakoo',
      ward: 'Kariakoo',
      district: 'Ilala',
      region: 'Dar es Salaam',
      totalComplaints: 5,
      resolvedComplaints: 3,
    );

    _currentUser = demoUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(demoUser.toJson()));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    String? nationalId,
    String? mtaa,
    String? ward,
    String? district,
    String? region,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
      nationalId: nationalId,
      createdAt: DateTime.now(),
      mtaa: mtaa,
      ward: ward,
      district: district,
      region: region,
    );

    _currentUser = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(newUser.toJson()));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    notifyListeners();
  }
}

// ─── Locale Provider ──────────────────────────────────────────────────────────

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('sw', 'TZ'); // Default Kiswahili

  Locale get locale => _locale;
  bool get isSwahili => _locale.languageCode == 'sw';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'sw';
    _locale = Locale(code, code == 'sw' ? 'TZ' : 'US');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    if (_locale.languageCode == 'sw') {
      setLocale(const Locale('en', 'US'));
    } else {
      setLocale(const Locale('sw', 'TZ'));
    }
  }
}

// ─── Theme Provider ───────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
