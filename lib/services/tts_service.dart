import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_web_engine_stub.dart'
    if (dart.library.html) 'tts_web_engine_web.dart';

class TtsService {
  late final FlutterTts _tts;
  final WebTtsEngine _webTts = createWebTtsEngine();

  bool _ready = false;
  bool _enabled = true;
  bool _isSpeaking = false;
  int _errorCount = 0;
  bool _webInteractionUnlocked = !kIsWeb;
  String _lang = 'en';
  String _activeLocale = 'en-US';
  static const Duration _opTimeout = Duration(milliseconds: 1200);
  static const Duration _initTimeout = Duration(seconds: 2);
  static const Duration _speakTimeout = Duration(milliseconds: 2200);
  static const int _maxSpeechChars = 280;

  TtsService() {
    if (!kIsWeb) {
      _tts = FlutterTts();
    }
  }

  Future<void> init({required String lang}) async {
    _lang = lang;
    _ready = false;
    _enabled = true;
    _isSpeaking = false;
    _errorCount = 0;
    _webInteractionUnlocked = !kIsWeb;

    if (kIsWeb) {
      try {
        await _webTts.init(lang: lang).timeout(_initTimeout);
        _ready = _webTts.supported;
        _enabled = _webTts.supported;
      } catch (_) {
        _ready = false;
        _enabled = false;
      }
      return;
    }

    _wireHandlers();
    _activeLocale = await _setPreferredLanguage();
    await _safeCall(() => _tts.awaitSpeakCompletion(false), timeout: _opTimeout);

    // Gentle guidance voice profile.
    final speechRate = _lang == 'fr' ? 0.34 : 0.36;
    final pitch = _lang == 'fr' ? 0.96 : 0.97;
    await _safeCall(() => _tts.setSpeechRate(speechRate), timeout: _opTimeout);
    await _safeCall(() => _tts.setPitch(pitch), timeout: _opTimeout);
    await _safeCall(() => _tts.setVolume(0.88), timeout: _opTimeout);

    // Try to pick a gentle female voice for kid-friendly clarity.
    try {
      final voices = await _tts.getVoices.timeout(_initTimeout);
      if (voices is List) {
        final all = voices
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        final pick = _pickBestNativeVoice(all);

        if (pick != null && pick.isNotEmpty) {
          // FlutterTts expects a map of <String, String>
          final voiceMap = pick.map((k, v) => MapEntry(k, v.toString()));
          await _safeCall(() => _tts.setVoice(voiceMap), timeout: _opTimeout);
        }
      }
    } catch (_) {
      // Some platforms don't expose voice metadata; ignore safely.
    }

    _ready = true;
  }

  void registerUserInteraction() {
    if (kIsWeb) {
      _webInteractionUnlocked = true;
    }
  }

  void _wireHandlers() {
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _errorCount = 0;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _errorCount++;
      debugPrint('TTS error: $msg');
      if (_errorCount >= 5) {
        _enabled = false;
        debugPrint('TTS disabled after repeated errors.');
      }
    });
  }

  Future<void> _safeCall(
    Future<dynamic> Function() op, {
    required Duration timeout,
  }) async {
    try {
      await op().timeout(timeout);
    } on TimeoutException {
      _isSpeaking = false;
      debugPrint('TTS op timeout after ${timeout.inMilliseconds}ms');
    } catch (_) {
      // ignore safely
    }
  }

  String _cleanText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= _maxSpeechChars) {
      return normalized;
    }
    final clipped = normalized.substring(0, _maxSpeechChars);
    final cut = clipped.lastIndexOf(' ');
    return cut >= 120 ? clipped.substring(0, cut) : clipped;
  }

  Future<String> _setPreferredLanguage() async {
    final candidates = _lang == 'fr'
        ? const ['fr-FR', 'fr-CA', 'fr']
        : const ['en-US', 'en-GB', 'en'];
    for (final locale in candidates) {
      try {
        await _tts.setLanguage(locale).timeout(_opTimeout);
        return locale;
      } catch (_) {
        // try next fallback locale
      }
    }
    return _lang == 'fr' ? 'fr-FR' : 'en-US';
  }

  bool _voiceMatchesLang(Map<String, dynamic> voice) {
    final locale =
        (voice['locale'] ?? voice['language'] ?? '').toString().toLowerCase();
    if (_lang == 'fr') return locale.contains('fr');
    return locale.contains('en');
  }

  Map<String, dynamic>? _pickBestNativeVoice(List<Map<String, dynamic>> voices) {
    if (voices.isEmpty) {
      return null;
    }
    final langMatches = voices.where(_voiceMatchesLang).toList();
    final candidates = langMatches.isEmpty ? voices : langMatches;

    Map<String, dynamic>? best;
    int bestScore = -999999;
    for (final voice in candidates) {
      final score = _nativeVoiceScore(voice);
      if (score > bestScore) {
        bestScore = score;
        best = voice;
      }
    }
    return best;
  }

  int _nativeVoiceScore(Map<String, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale =
        (voice['locale'] ?? voice['language'] ?? '').toString().toLowerCase();
    final gender = (voice['gender'] ?? '').toString().toLowerCase();
    final targetPrefix = _lang == 'fr' ? 'fr' : 'en';
    final preferredNames = _lang == 'fr'
        ? const [
            'amelie',
            'audrey',
            'celine',
            'marie',
            'chantal',
            'helene',
            'lea',
            'julie',
            'denise',
            'claire',
            'google francais',
            'microsoft denise',
            'female',
          ]
        : const [
            'rachel',
            'samantha',
            'ava',
            'aria',
            'allison',
            'jenny',
            'libby',
            'serena',
            'zira',
            'hazel',
            'susan',
            'female',
            'google uk english female',
            'microsoft aria',
            'microsoft zira',
          ];
    const maleHints = [
      'male',
      'man',
      'david',
      'mark',
      'george',
      'thomas',
      'paul',
      'daniel',
      'james',
      'john',
      'michael',
      'pierre',
      'louis',
      'antoine',
      'francois',
    ];
    const qualityHints = [
      'neural',
      'natural',
      'premium',
      'wavenet',
      'enhanced',
      'online',
    ];

    var score = 0;
    if (locale.startsWith(targetPrefix)) score += 50;
    if (locale.startsWith(_activeLocale.toLowerCase())) score += 30;
    if (preferredNames.any(name.contains)) score += 90;
    if (qualityHints.any(name.contains)) score += 15;
    if (gender.contains('female')) score += 80;
    if (gender.contains('male')) score -= 120;
    if (maleHints.any(name.contains)) score -= 120;
    return score;
  }

  Future<void> speak(String text, {bool fromUserAction = false}) async {
    if (fromUserAction) {
      registerUserInteraction();
    }
    if (!_ready) return;
    if (!_enabled) return;
    final clean = _cleanText(text);
    if (clean.isEmpty) return;
    if (kIsWeb && !_webInteractionUnlocked) {
      // Browser blocks speech before user interaction; skip quietly.
      return;
    }
    try {
      if (kIsWeb) {
        await _safeCall(
          () => _webTts.speak(clean),
          timeout: _speakTimeout,
        );
        return;
      }
      if (_isSpeaking) {
        await _safeCall(() => _tts.stop(), timeout: _opTimeout);
        _isSpeaking = false;
      }
      await _safeCall(() => _tts.speak(clean), timeout: _speakTimeout);
    } catch (e) {
      _errorCount++;
      debugPrint('TTS speak exception: $e');
      if (_errorCount >= 5) {
        _enabled = false;
      }
    }
  }

  Future<void> stop() async {
    if (!_ready) return;
    try {
      if (kIsWeb) {
        await _safeCall(() => _webTts.stop(), timeout: _opTimeout);
        return;
      }
      await _safeCall(() => _tts.stop(), timeout: _opTimeout);
      _isSpeaking = false;
    } catch (_) {}
  }
}
