import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../services/tts_service.dart';
import '../widgets/ui.dart';

class StoryReaderScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> story;

  const StoryReaderScreen({
    super.key,
    required this.lang,
    required this.story,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final tts = TtsService();
  final store = ProgressStore();
  bool voiceOn = true;
  bool speaking = false;
  int _speakRunId = 0;

  String get _title => (widget.story['title'] ?? '').toString();
  String get _summary => (widget.story['summary'] ?? '').toString();
  String get _text => (widget.story['text'] ?? '').toString();
  String get _iconName => (widget.story['icon'] ?? '').toString();

  IconData _iconFromName(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'palette':
        return Icons.palette_rounded;
      case 'bubble_chart':
        return Icons.bubble_chart_rounded;
      case 'umbrella':
        return Icons.umbrella_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'calculate':
        return Icons.calculate_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'cookie':
        return Icons.cookie_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'groups':
        return Icons.groups_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  Widget _animatedHeaderIcon(IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.teal.shade700, size: 22),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      voiceOn = await store.getVoiceOn();
    } catch (e) {
      debugPrint('Story voice preference load error: $e');
      voiceOn = true;
    }
    try {
      await tts.init(lang: widget.lang);
    } catch (e) {
      debugPrint('Story TTS init error: $e');
      voiceOn = false;
    }
    if (!mounted) return;
    setState(() {});
    if (voiceOn && !kIsWeb) {
      await _speakStory(fromUserAction: true);
    }
  }

  Future<void> _speakStory({bool fromUserAction = false}) async {
    final runId = ++_speakRunId;
    if (!voiceOn) {
      if (mounted) {
        setState(() => speaking = false);
      }
      return;
    }
    setState(() => speaking = true);
    try {
      await tts.stop();
      final sections = <String>[
        if (_title.isNotEmpty) '$_title.',
        if (_summary.isNotEmpty) _summary,
        if (_text.isNotEmpty) _text,
      ];
      for (int i = 0; i < sections.length; i++) {
        if (!mounted || runId != _speakRunId || !voiceOn) {
          return;
        }
        await tts.speak(sections[i], fromUserAction: fromUserAction || i == 0);
        if (i < sections.length - 1) {
          if (!mounted || runId != _speakRunId || !voiceOn) {
            return;
          }
          await Future.delayed(const Duration(milliseconds: 350));
        }
      }
    } catch (e) {
      debugPrint('Story speak error: $e');
    }
    if (!mounted || runId != _speakRunId) return;
    setState(() => speaking = false);
  }

  Future<void> _stopStory() async {
    _speakRunId++;
    await tts.stop();
    if (!mounted) return;
    setState(() => speaking = false);
  }

  Future<void> _setVoice(bool enabled, {bool speakNow = false}) async {
    setState(() => voiceOn = enabled);
    try {
      await store.setVoiceOn(enabled);
    } catch (e) {
      debugPrint('Story voice preference save error: $e');
    }
    if (!enabled) {
      await _stopStory();
      return;
    }
    if (speakNow) {
      await _speakStory(fromUserAction: true);
    }
  }

  @override
  void deactivate() {
    _speakRunId++;
    tts.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _speakRunId++;
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lang == 'fr' ? 'Lecture' : 'Story Time'),
        actions: [
          IconButton(
            tooltip: widget.lang == 'fr' ? 'Voix' : 'Voice',
            onPressed: () async {
              await _setVoice(!voiceOn, speakNow: true);
            },
            icon: Icon(voiceOn ? Icons.volume_up : Icons.volume_off),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DollyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _animatedHeaderIcon(_iconFromName(_iconName)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_summary, style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          DollyCard(
            child: Text(
              _text,
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (!voiceOn) {
                      await _setVoice(true);
                    }
                    await _speakStory(fromUserAction: true);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(widget.lang == 'fr' ? 'Lire histoire' : 'Read Aloud'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setVoice(!voiceOn),
                  icon: Icon(voiceOn ? Icons.volume_off : Icons.volume_up),
                  label: Text(
                    widget.lang == 'fr'
                        ? (voiceOn ? 'Couper son' : 'Activer son')
                        : (voiceOn ? 'Mute Voice' : 'Enable Voice'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: speaking ? _stopStory : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
