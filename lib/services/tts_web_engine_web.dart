// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class WebTtsEngine {
  String _lang = 'en';
  String _activeLocale = 'en-US';
  html.SpeechSynthesisVoice? _voice;

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
    if (voices.isEmpty) {
      // Some browsers populate voices asynchronously after first access.
      await Future<void>.delayed(const Duration(milliseconds: 250));
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

  Future<void> speak(String text) async {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;
    final clean = text.trim();
    if (clean.isEmpty) return;

    final utterance = html.SpeechSynthesisUtterance(clean)
      ..lang = (_voice?.lang ?? _activeLocale)
      ..rate = _lang == 'fr' ? 0.76 : 0.78
      ..pitch = _lang == 'fr' ? 0.96 : 0.97
      ..volume = 0.88;
    if (_voice != null) {
      utterance.voice = _voice;
    }
    synth.cancel();
    synth.speak(utterance);
  }

  Future<void> stop() async {
    html.window.speechSynthesis?.cancel();
  }
}

WebTtsEngine createWebTtsEngine() => WebTtsEngine();
