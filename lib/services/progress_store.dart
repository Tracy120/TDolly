import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  static const _kLang = 'lang';
  static const _kVoiceOn = 'voiceOn';
  static const _kUnlocked = 'unlocked'; // set of lesson ids

  Future<String> getLanguage() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLang) ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLang, lang);
  }

  Future<bool> getVoiceOn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kVoiceOn) ?? true;
  }

  Future<void> setVoiceOn(bool on) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kVoiceOn, on);
  }

  Future<Set<String>> getUnlocked() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList(_kUnlocked) ?? const <String>[]).toSet();
  }

  Future<void> unlock(String lessonId) async {
    final sp = await SharedPreferences.getInstance();
    final current = (sp.getStringList(_kUnlocked) ?? const <String>[]).toSet();
    current.add(lessonId);
    await sp.setStringList(_kUnlocked, current.toList());
  }
}
