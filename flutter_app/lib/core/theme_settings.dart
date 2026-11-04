import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings extends ChangeNotifier {
  static const _brightnessKey = 'theme.brightness';
  static const _primaryKey = 'theme.primary';
  static const _secondaryKey = 'theme.secondary';
  static const _backgroundKey = 'theme.background';
  static const _surfaceKey = 'theme.surface';
  static const _errorKey = 'theme.error';

  ThemeMode mode = ThemeMode.light;
  Color primary = Colors.indigo;
  Color secondary = Colors.teal;
  Color background = const Color(0xfff8f9ff);
  Color surface = Colors.white;
  Color error = Colors.red;

  ThemeData get lightTheme => _theme(Brightness.light);
  ThemeData get darkTheme => _theme(Brightness.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString(_brightnessKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    primary = _readColor(prefs, _primaryKey, primary);
    secondary = _readColor(prefs, _secondaryKey, secondary);
    background = _readColor(prefs, _backgroundKey, background);
    surface = _readColor(prefs, _surfaceKey, surface);
    error = _readColor(prefs, _errorKey, error);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    await _save();
    notifyListeners();
  }

  Future<void> setColor(String name, Color value) async {
    switch (name) {
      case 'primary':
        primary = value;
      case 'secondary':
        secondary = value;
      case 'background':
        background = value;
      case 'surface':
        surface = value;
      case 'error':
        error = value;
    }

    await _save();
    notifyListeners();
  }

  Future<void> clearForDeletedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _brightnessKey,
      _primaryKey,
      _secondaryKey,
      _backgroundKey,
      _surfaceKey,
      _errorKey,
    ]) {
      await prefs.remove(key);
    }
    mode = ThemeMode.light;
    primary = Colors.indigo;
    secondary = Colors.teal;
    background = const Color(0xfff8f9ff);
    surface = Colors.white;
    error = Colors.red;
    notifyListeners();
  }

  void applyLightPreset() {
    mode = ThemeMode.light;
    primary = Colors.indigo;
    secondary = Colors.teal;
    background = const Color(0xfff8f9ff);
    surface = Colors.white;
    error = Colors.red;
    _saveAndNotify();
  }

  void applyDarkPreset() {
    mode = ThemeMode.dark;
    primary = Colors.indigoAccent;
    secondary = Colors.tealAccent;
    background = const Color(0xff101114);
    surface = const Color(0xff1b1c20);
    error = Colors.redAccent;
    _saveAndNotify();
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      surfaceContainerHighest: background,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );
  }

  Color _readColor(SharedPreferences prefs, String key, Color fallback) {
    final value = prefs.getInt(key);
    return value == null ? fallback : Color(value);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _brightnessKey, mode == ThemeMode.dark ? 'dark' : 'light');
    await prefs.setInt(_primaryKey, primary.toARGB32());
    await prefs.setInt(_secondaryKey, secondary.toARGB32());
    await prefs.setInt(_backgroundKey, background.toARGB32());
    await prefs.setInt(_surfaceKey, surface.toARGB32());
    await prefs.setInt(_errorKey, error.toARGB32());
  }

  void _saveAndNotify() {
    _save();
    notifyListeners();
  }
}
