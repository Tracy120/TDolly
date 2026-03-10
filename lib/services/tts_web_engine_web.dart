// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebTtsEngine {
  String _lang = 'en';
  String _activeLocale = 'en-US';
  html.SpeechSynthesisVoice? _voice;
  Completer<void>? _activeSpeakCompleter;

  bool get supported => html.window.speechSynthesis != null;

  Future<void> init({required String lang}) async {
    _lang = lang;
    _activeLocale = _lang == 'fr' ? 'fr-FR' : 'en-US';
    if (!supported) return;
    _voice = await _pickVoice();
  }

  Future<html.SpeechSynthesisVoice?> _pickVoice() async {
    final synth = html.window.speechSynthesis;
    if (synth == null) return null;

    var voices = synth.getVoices();
    for (int attempt = 0; attempt < 6 && voices.isEmpty; attempt++) {
      // Browsers can populate voices asynchronously after first access.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      voices = synth.getVoices();
    }
    if (voices.isEmpty) return null;

    final langPrefix = _lang == 'fr' ? 'fr' : 'en';
    final preferred = _lang == 'fr'
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
            'google uk english female',
            'microsoft aria',
            'microsoft zira',
            'libby',
            'serena',
            'zira',
            'hazel',
            'susan',
            'female',
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

    final langVoices = voices.where((v) {
      final vLang = (v.lang ?? '').toLowerCase();
      return vLang.startsWith(langPrefix);
    }).toList();
    final candidates = langVoices.isEmpty ? voices : langVoices;

    int scoreVoice(html.SpeechSynthesisVoice v) {
      final name = (v.name ?? '').toLowerCase();
      final vLang = (v.lang ?? '').toLowerCase();
      var score = 0;
      if (vLang.startsWith(langPrefix)) score += 50;
      if (vLang.startsWith(_activeLocale.toLowerCase())) score += 30;
      if (preferred.any(name.contains)) score += 90;
      if (qualityHints.any(name.contains)) score += 15;
      if (roboticHints.any(name.contains)) score -= 35;
      if (maleHints.any(name.contains)) score -= 120;
      return score;
    }

    html.SpeechSynthesisVoice best = candidates.first;
    var bestScore = -999999;
    for (final v in candidates) {
      final score = scoreVoice(v);
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    return best;
  }

  Duration _utteranceTimeout(String text) {
    final clean = text.trim();
    final wordCount = RegExp(r'\S+').allMatches(clean).length;
    var timeoutMs = 5000 + (wordCount * (_lang == 'fr' ? 850 : 720));
    timeoutMs += clean.length * (_lang == 'fr' ? 22 : 18);
    if (timeoutMs < 6000) {
      timeoutMs = 6000;
    }
    if (timeoutMs > 32000) {
      timeoutMs = 32000;
    }
    return Duration(milliseconds: timeoutMs);
  }

  Future<void> speak(String text) async {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    final completer = Completer<void>();
    _activeSpeakCompleter = completer;

    try {
      final utterance = html.SpeechSynthesisUtterance(clean)
        ..lang = (_voice?.lang ?? _activeLocale)
        ..rate = _lang == 'fr' ? 0.76 : 0.84
        ..pitch = _lang == 'fr' ? 0.96 : 0.95
        ..volume = 0.88;
      if (_voice != null) {
        utterance.voice = _voice;
      }
      utterance.onEnd.first.then((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      utterance.onError.first.then((event) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Web speech synthesis error'),
          );
        }
      });
      synth.speak(utterance);
      await completer.future.timeout(_utteranceTimeout(clean));
    } catch (e) {
      debugPrint('Web TTS utterance error: $e');
      rethrow;
    } finally {
      if (identical(_activeSpeakCompleter, completer)) {
        _activeSpeakCompleter = null;
      }
    }
  }

  Future<void> stop() async {
    final completer = _activeSpeakCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _activeSpeakCompleter = null;
    html.window.speechSynthesis?.cancel();
  }
}

WebTtsEngine createWebTtsEngine() => WebTtsEngine();
