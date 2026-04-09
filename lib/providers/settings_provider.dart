import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

class SettingsService {
  static const _languageKey = 'language_code';
  static const _notificationsKey = 'notifications_enabled';
  static const _hasSelectedLanguageKey = 'has_selected_language';
  static const _hasPromptedNotificationsKey = 'has_prompted_notifications';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> getLanguageCode() async {
    final p = await prefs;
    return p.getString(_languageKey) ?? 'en';
  }

  Future<void> setLanguageCode(String code) async {
    final p = await prefs;
    await p.setString(_languageKey, code);
  }

  Future<bool> getNotificationsEnabled() async {
    final p = await prefs;
    return p.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_notificationsKey, enabled);
  }

  Future<bool> getHasSelectedLanguage() async {
    final p = await prefs;
    return p.getBool(_hasSelectedLanguageKey) ?? false;
  }

  Future<void> setHasSelectedLanguage(bool value) async {
    final p = await prefs;
    await p.setBool(_hasSelectedLanguageKey, value);
  }

  Future<bool> getHasPromptedNotifications() async {
    final p = await prefs;
    return p.getBool(_hasPromptedNotificationsKey) ?? false;
  }

  Future<void> setHasPromptedNotifications(bool value) async {
    final p = await prefs;
    await p.setBool(_hasPromptedNotificationsKey, value);
  }
}

final currentLanguageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(settingsServiceProvider));
});

class LanguageNotifier extends StateNotifier<String> {
  final SettingsService _service;

  LanguageNotifier(this._service) : super('en') {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getLanguageCode();
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await _service.setLanguageCode(code);
  }
}

final currentLocaleProvider = Provider<Locale>((ref) {
  final code = ref.watch(currentLanguageProvider);
  return Locale(code);
});

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref.watch(settingsServiceProvider));
});

class NotificationsNotifier extends StateNotifier<bool> {
  final SettingsService _service;

  NotificationsNotifier(this._service) : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getNotificationsEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _service.setNotificationsEnabled(enabled);
  }
}

final hasSelectedLanguageProvider =
    StateNotifierProvider<HasSelectedLanguageNotifier, bool>((ref) {
  return HasSelectedLanguageNotifier(ref.watch(settingsServiceProvider));
});

class HasSelectedLanguageNotifier extends StateNotifier<bool> {
  final SettingsService _service;

  HasSelectedLanguageNotifier(this._service) : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getHasSelectedLanguage();
  }

  Future<void> markSelected() async {
    state = true;
    await _service.setHasSelectedLanguage(true);
  }
}

final hasPromptedNotificationsProvider =
    StateNotifierProvider<HasPromptedNotificationsNotifier, bool>((ref) {
  return HasPromptedNotificationsNotifier(ref.watch(settingsServiceProvider));
});

class HasPromptedNotificationsNotifier extends StateNotifier<bool> {
  HasPromptedNotificationsNotifier(this._service) : super(false) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    state = await _service.getHasPromptedNotifications();
  }

  Future<void> markPrompted() async {
    state = true;
    await _service.setHasPromptedNotifications(true);
  }
}
