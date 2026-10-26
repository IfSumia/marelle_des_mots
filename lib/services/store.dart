import 'package:shared_preferences/shared_preferences.dart';

import '../logic/deck_settings.dart';

/// What the phone remembers between sessions: best streak and word selection.
class Store {
  Store(this._prefs);

  final SharedPreferences _prefs;

  static Future<Store> open() async => Store(await SharedPreferences.getInstance());

  int get best => _prefs.getInt('best') ?? 0;
  Future<void> saveBest(int value) => _prefs.setInt('best', value);

  bool get musicOn => _prefs.getBool('music') ?? true;
  Future<void> saveMusicOn(bool value) => _prefs.setBool('music', value);

  DeckSettings get settings {
    final raw = _prefs.getString('settings');
    return raw == null ? const DeckSettings() : DeckSettings.fromJson(raw);
  }

  Future<void> saveSettings(DeckSettings s) => _prefs.setString('settings', s.toJson());
}
