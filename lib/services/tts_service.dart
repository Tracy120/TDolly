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
  int _errorCount = 0;
  bool _webInteractionUnlocked = !kIsWeb;
  String _lang = 'en';
  String _activeLocale = 'en-US';
  Completer<void>? _nativeSpeakCompleter;
  int _speakSessionId = 0;
  bool _handlersWired = false;
  static const Duration _opTimeout = Duration(milliseconds: 1200);
  static const Duration _initTimeout = Duration(seconds: 2);
  static const int _maxSpeechChunkChars = 170;
  static const int _maxEnglishSpeechChunkChars = 130;

  TtsService() {
    if (!kIsWeb) {
      _tts = FlutterTts();
    }
  }

  Future<void> init({required String lang}) async {
    _lang = lang;
    _ready = false;
    _enabled = true;
    _errorCount = 0;
    _webInteractionUnlocked = !kIsWeb;
    _speakSessionId++;
    _completeNativeSpeak();

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
    await _safeCall(() => _tts.awaitSpeakCompletion(false),
        timeout: _opTimeout);

    // Keep English calm and clear without dragging; overly slow playback
    // caused some engines to time out and cut off words.
    final speechRate = _lang == 'fr' ? 0.28 : 0.38;
    final pitch = _lang == 'fr' ? 0.95 : 0.96;
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
    if (_handlersWired) {
      return;
    }
    _handlersWired = true;
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {
      _errorCount = 0;
      _completeNativeSpeak();
    });
    _tts.setCancelHandler(() {
      _completeNativeSpeak();
    });
    _tts.setErrorHandler((msg) {
      _errorCount++;
      _completeNativeSpeak(error: StateError(msg));
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
      debugPrint('TTS op timeout after ${timeout.inMilliseconds}ms');
    } catch (_) {
      // ignore safely
    }
  }

  void _completeNativeSpeak({Object? error}) {
    final completer = _nativeSpeakCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (error != null) {
      completer.completeError(error);
      return;
    }
    completer.complete();
  }

  Duration _speechTimeoutFor(String text) {
    final normalized = _normalizeText(text);
    final wordCount = RegExp(r'\S+').allMatches(normalized).length;
    final isFrench = _lang == 'fr';
    var timeoutMs = isFrench
        ? 2200 + (wordCount * 430)
        : 5500 + (wordCount * 780);
    timeoutMs += normalized.length * (isFrench ? 18 : 18);
    if (timeoutMs < (isFrench ? 2400 : 6500)) {
      timeoutMs = isFrench ? 2400 : 6500;
    }
    if (timeoutMs > (isFrench ? 14000 : 32000)) {
      timeoutMs = isFrench ? 14000 : 32000;
    }
    return Duration(milliseconds: timeoutMs);
  }

  Duration _pauseAfterPart(String part) {
    final endsSentence =
        part.endsWith('.') || part.endsWith('!') || part.endsWith('?');
    if (_lang == 'fr') {
      return endsSentence
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 80);
    }
    return endsSentence
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 200);
  }

  Future<void> _stopCurrentPlayback({bool cancelSession = true}) async {
    if (cancelSession) {
      _speakSessionId++;
    }
    _completeNativeSpeak();
    if (!_ready) return;
    try {
      if (kIsWeb) {
        await _safeCall(() => _webTts.stop(), timeout: _opTimeout);
        return;
      }
      await _safeCall(() => _tts.stop(), timeout: _opTimeout);
    } catch (_) {}
  }

  Future<void> _speakNativePart(String part) async {
    final completer = Completer<void>();
    _nativeSpeakCompleter = completer;
    await _tts.speak(part);
    await completer.future.timeout(_speechTimeoutFor(part), onTimeout: () {
      _completeNativeSpeak();
    });
  }

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _splitTextForPunctuation(String text) {
    // Split text only at sentence endings for natural pauses
    final parts = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);
      // Only split at sentence endings, not every punctuation mark
      if (char == '.' || char == '!' || char == '?') {
        parts.add(buffer.toString().trim());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }
    return parts.where((p) => p.isNotEmpty).toList();
  }

  List<String> _splitLongPart(String text) {
    final trimmed = text.trim();
    final maxChunkChars =
        _lang == 'en' ? _maxEnglishSpeechChunkChars : _maxSpeechChunkChars;
    if (trimmed.isEmpty) return const [];
    if (trimmed.length <= maxChunkChars) {
      return [trimmed];
    }

    final chunks = <String>[];
    var remaining = trimmed;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxChunkChars) {
        chunks.add(remaining.trim());
        break;
      }

      var splitAt = remaining.lastIndexOf(', ', maxChunkChars);
      splitAt =
          splitAt < 0 ? remaining.lastIndexOf('; ', maxChunkChars) : splitAt;
      splitAt =
          splitAt < 0 ? remaining.lastIndexOf(': ', maxChunkChars) : splitAt;
      splitAt =
          splitAt < 0 ? remaining.lastIndexOf(' ', maxChunkChars) : splitAt;

      if (splitAt < 0 || splitAt < (maxChunkChars ~/ 2)) {
        final nextWordBreak = remaining.indexOf(' ', maxChunkChars);
        splitAt = nextWordBreak > 0 ? nextWordBreak : maxChunkChars;
      }

      final chunk = remaining.substring(0, splitAt).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }
      remaining = remaining.substring(splitAt).trim();
    }
    return chunks;
  }

  List<String> _speechChunks(String text) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) return const [];

    final punctuated = _splitTextForPunctuation(normalized);
    if (punctuated.isEmpty) {
      return _splitLongPart(normalized);
    }

    final chunks = <String>[];
    for (final part in punctuated) {
      chunks.addAll(_splitLongPart(part));
    }
    return chunks.where((chunk) => chunk.isNotEmpty).toList();
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

  Map<String, dynamic>? _pickBestNativeVoice(
      List<Map<String, dynamic>> voices) {
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
            'karen',
            'moira',
            'natasha',
            'sonia',
            'nancy',
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
            'microsoft libby',
            'microsoft sonia',
            'microsoft nancy',
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
    const roboticHints = [
      'default',
      'google us english',
      'robot',
      'compact',
    ];

    var score = 0;
    if (locale.startsWith(targetPrefix)) score += 50;
    if (locale.startsWith(_activeLocale.toLowerCase())) score += 30;
    if (preferredNames.any(name.contains)) score += 90;
    if (qualityHints.any(name.contains)) score += 15;
    if (roboticHints.any(name.contains)) score -= 35;
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
    final parts = _speechChunks(text);
    if (parts.isEmpty) return;
    if (kIsWeb && !_webInteractionUnlocked) {
      // Browser blocks speech before user interaction; skip quietly.
      return;
    }
    final sessionId = ++_speakSessionId;
    try {
      await _stopCurrentPlayback(cancelSession: false);
      for (int i = 0; i < parts.length; i++) {
        if (sessionId != _speakSessionId) {
          return;
        }
        final part = parts[i];
        if (kIsWeb) {
          try {
            await _webTts.speak(part).timeout(_speechTimeoutFor(part));
          } catch (e) {
            debugPrint('Web TTS speak error: $e');
            _errorCount++;
          }
        } else {
          await _speakNativePart(part);
        }
        if (sessionId != _speakSessionId) {
          return;
        }
        // Add pause after sentence ending
        if (i < parts.length - 1) {
          final pauseDuration = _pauseAfterPart(part);
          await Future.delayed(pauseDuration);
          if (sessionId != _speakSessionId) {
            return;
          }
        }
      }
    } catch (e) {
      _errorCount++;
      debugPrint('TTS speak exception: $e');
      if (_errorCount >= 5) {
        _enabled = false;
      }
    }
  }

  Future<void> stop() async {
    await _stopCurrentPlayback();
  }
}
