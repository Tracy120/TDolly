import 'dart:async';

import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../models/worksheet_models.dart';
import '../services/lesson_repository.dart';
import '../services/progress_store.dart';
import '../services/tts_service.dart';
import '../widgets/lesson_step_widgets.dart';
import '../widgets/ui.dart';
import 'interactive_worksheet_screen.dart';
import 'worksheet_builder_screen.dart';

class LessonScreen extends StatefulWidget {
  final String lang;
  final String worldTitle;
  final Unit unit;
  final int initialLessonIndex;
  final bool stopAfterLesson;

  const LessonScreen({
    super.key,
    required this.lang,
    required this.worldTitle,
    required this.unit,
    this.initialLessonIndex = 0,
    this.stopAfterLesson = false,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final repo = LessonRepository();
  final store = ProgressStore();
  final tts = TtsService();

  late int lessonIndex;
  Lesson? currentLesson;
  int stepIndex = 0;
  int stepAttempt = 0;
  bool voiceOn = true;
  bool loading = true;
  String? loadError;
  String feedback = "";
  bool showRetry = false;

  @override
  void initState() {
    super.initState();
    final maxIndex = (widget.unit.lessons.length - 1).clamp(0, 9999);
    lessonIndex = widget.initialLessonIndex.clamp(0, maxIndex);
    _init();
  }

  Future<void> _init() async {
    await _syncVoicePreference();
    unawaited(_initTtsInBackground());
    await _loadLesson();
  }

  Future<void> _syncVoicePreference() async {
    try {
      final pref = await store
          .getVoiceOn()
          .timeout(const Duration(seconds: 2), onTimeout: () => true);
      if (!mounted) return;
      setState(() => voiceOn = pref);
    } catch (_) {
      if (!mounted) return;
      setState(() => voiceOn = true);
    }
  }

  Future<void> _initTtsInBackground() async {
    if (!voiceOn) return;
    try {
      await tts.init(lang: widget.lang).timeout(const Duration(seconds: 4));
    } catch (_) {
      if (!mounted) return;
      setState(() => voiceOn = false);
      await store.setVoiceOn(false);
    }
  }

  Future<void> _unlockCurrentAndNext({String? generatedLessonId}) async {
    final currentRef = widget.unit.lessons[lessonIndex];
    await store.unlock(_progressKeyFor(currentRef.id));
    if (generatedLessonId != null && generatedLessonId.isNotEmpty) {
      await store.unlock(_progressKeyFor(generatedLessonId));
    }
    if (lessonIndex < widget.unit.lessons.length - 1) {
      await store.unlock(_progressKeyFor(widget.unit.lessons[lessonIndex + 1].id));
    }
  }

  String _progressKeyFor(String lessonId) => '${widget.unit.id}:$lessonId';

  Future<void> _loadLesson() async {
    await tts.stop();
    if (widget.unit.lessons.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = widget.lang == 'fr'
            ? 'Cette unite ne contient aucune lecon.'
            : 'This unit has no lessons.';
      });
      return;
    }

    final ref = widget.unit.lessons[lessonIndex];
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
        feedback = "";
        stepIndex = 0;
        showRetry = false;
        stepAttempt = 0;
        currentLesson = null;
      });
    }

    try {
      if (ref.type == 'worksheet') {
        final route = _isDirectInteractiveWorksheetFile(ref.file)
            ? MaterialPageRoute<bool>(
                builder: (_) => InteractiveWorksheetScreen(
                  lang: widget.lang,
                  worksheetRef: InteractiveWorksheetRef(
                    id: ref.id,
                    title: ref.title,
                    subtitle: ref.title,
                    level: _worksheetLevel(),
                    type: 'worksheet',
                    file: ref.file,
                    accent: '#4A74E8',
                  ),
                  returnToPathOnDone: widget.stopAfterLesson,
                ),
              )
            : MaterialPageRoute<bool>(
                builder: (_) => WorksheetBuilderScreen(
                  lang: widget.lang,
                  launchedFromPath: true,
                ),
              );
        if (!mounted) return;
        final completed = await Navigator.push<bool>(context, route);
        if (!mounted) return;
        if (completed == true) {
          await _unlockCurrentAndNext();
          if (!mounted) return;
          if (widget.stopAfterLesson) {
            Navigator.pop(context, true);
            return;
          }
          if (lessonIndex < widget.unit.lessons.length - 1) {
            setState(() => lessonIndex++);
            await _loadLesson();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          if (widget.stopAfterLesson) {
            Navigator.pop(context, false);
          } else {
            Navigator.pop(context, false);
          }
        }
        return;
      }

      final lesson = await repo
          .loadLesson(widget.lang, ref.file)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => currentLesson = lesson);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = widget.lang == 'fr'
            ? "Lecon indisponible. Reessaie."
            : "Lesson unavailable. Please retry.";
      });
      debugPrint('Lesson load failed: ${ref.file} -> $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _maybeSpeak(String text, {bool fromUserAction = false}) async {
    if (!voiceOn) return;
    await tts.speak(text, fromUserAction: fromUserAction);
  }

  void _onAnswered(bool correct) {
    final step = currentLesson?.steps[stepIndex];
    final hint = (step?.data['hint'] ?? '').toString().trim();
    setState(() {
      feedback = correct
          ? (widget.lang == 'fr' ? "Bravo !" : "Great job!")
          : (widget.lang == 'fr'
              ? "Essaie encore. Utilise l'indice puis reessaie."
              : "Try again. Use the hint and retry.");
      if (!correct && hint.isNotEmpty) {
        feedback = widget.lang == 'fr'
            ? "$feedback\nIndice: $hint"
            : "$feedback\nHint: $hint";
      }
      showRetry = !correct;
    });
    if (correct) {
      _nextStepOrFinish();
    } else {
      _maybeSpeak(feedback, fromUserAction: true);
    }
  }

  Future<void> _nextStepOrFinish() async {
    await tts.stop();
    final lesson = currentLesson!;
    if (stepIndex < lesson.steps.length - 1) {
      setState(() {
        stepIndex++;
        stepAttempt++;
        feedback = "";
        showRetry = false;
      });
      final s = lesson.steps[stepIndex];
      final say = s.kind == 'info'
          ? (s.data['text'] ?? '').toString()
          : (s.data['question'] ?? s.data['prompt'] ?? '').toString();
      _maybeSpeak(say, fromUserAction: true);
      return;
    }

    await _unlockCurrentAndNext(generatedLessonId: lesson.id);
    _maybeSpeak(
      widget.lang == 'fr' ? "Lecon terminee !" : "Lesson completed!",
      fromUserAction: true,
    );
    if (!mounted) return;

    if (widget.stopAfterLesson) {
      Navigator.pop(context, true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.lang == 'fr' ? "Termine" : "Completed"),
        content: Text(widget.lang == 'fr'
            ? "Tu as termine cette lecon. Passe a la suivante."
            : "You finished this lesson. Move to the next one."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (lessonIndex < widget.unit.lessons.length - 1) {
                setState(() => lessonIndex++);
                _loadLesson();
              } else {
                Navigator.pop(context, true);
              }
            },
            child: Text(widget.lang == 'fr' ? "Suivant" : "Next"),
          ),
        ],
      ),
    );
  }

  bool _needsContinueButton(LessonStep step) {
    switch (step.kind) {
      case 'info':
      case 'prompt':
      case 'audio':
      case 'story':
      case 'external':
        return true;
      default:
        return false;
    }
  }

  bool _isDirectInteractiveWorksheetFile(String file) {
    if (file.isEmpty) return false;
    return file == 'trace_dots' ||
        file.startsWith('generated:') ||
        file.endsWith('.json');
  }

  String _worksheetLevel() {
    final id = widget.unit.id.toLowerCase();
    if (id.startsWith('k_') || id.contains('_k_')) {
      return 'K';
    }
    return 'Pre-K';
  }

  void _retryCurrentStep() {
    final lesson = currentLesson;
    if (lesson == null || lesson.steps.isEmpty) return;
    final step = lesson.steps[stepIndex];
    final say = step.kind == 'info'
        ? (step.data['text'] ?? '').toString()
        : (step.data['question'] ?? step.data['prompt'] ?? '').toString();
    setState(() {
      stepAttempt++;
      feedback = "";
      showRetry = false;
    });
    tts.stop().whenComplete(() {
      _maybeSpeak(say, fromUserAction: true);
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = currentLesson;
    final currentStep = (lesson == null || lesson.steps.isEmpty)
        ? null
        : lesson.steps[stepIndex];
    final lessonTotal = widget.unit.lessons.length;
    final lessonProgress =
        lessonTotal == 0 ? 0.0 : (lessonIndex + 1) / lessonTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit.title),
        actions: [
          IconButton(
            tooltip: widget.lang == 'fr' ? "Voix" : "Voice",
            onPressed: () async {
              final newOn = !voiceOn;
              setState(() => voiceOn = newOn);
              await store.setVoiceOn(newOn);
              if (newOn && lesson != null) {
                try {
                  await tts
                      .init(lang: widget.lang)
                      .timeout(const Duration(seconds: 4));
                } catch (_) {
                  if (!mounted) return;
                  setState(() => voiceOn = false);
                  await store.setVoiceOn(false);
                  return;
                }
                _maybeSpeak(lesson.title, fromUserAction: true);
              } else if (!newOn) {
                await tts.stop();
              }
            },
            icon: Icon(voiceOn ? Icons.volume_up : Icons.volume_off),
          ),
        ],
      ),
      body: lesson == null
          ? (loading
              ? const Center(child: CircularProgressIndicator())
              : (loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 32),
                            const SizedBox(height: 10),
                            Text(
                              loadError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: _loadLesson,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                  widget.lang == 'fr' ? 'Reessayer' : 'Retry'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back),
                              label:
                                  Text(widget.lang == 'fr' ? 'Retour' : 'Back'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator())))
          : lesson.steps.isEmpty
              ? Center(
                  child: Text(widget.lang == 'fr'
                      ? "Aucune etape dans cette lecon."
                      : "No steps available in this lesson."),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DollyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lesson.objective,
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: lessonProgress,
                              minHeight: 8,
                              backgroundColor: Colors.blueGrey.shade100,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.lang == 'fr'
                                ? "Lecon ${lessonIndex + 1}/$lessonTotal"
                                : "Lesson ${lessonIndex + 1}/$lessonTotal",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DollyCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey('step_${stepIndex}_$stepAttempt'),
                          child: _buildStep(currentStep!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (feedback.isNotEmpty)
                      DollyCard(
                        child: Row(
                          children: [
                            Icon(feedback.contains("Bravo") ||
                                    feedback.contains("Great")
                                ? Icons.star
                                : Icons.info),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(feedback,
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    if (showRetry)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FilledButton.icon(
                          onPressed: _retryCurrentStep,
                          icon: const Icon(Icons.refresh),
                          label:
                              Text(widget.lang == 'fr' ? "Reessayer" : "Retry"),
                        ),
                      ),
                    if (_needsContinueButton(currentStep))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FilledButton.icon(
                          onPressed: _nextStepOrFinish,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                              widget.lang == 'fr' ? "Continuer" : "Continue"),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildStep(LessonStep step) {
    switch (step.kind) {
      case 'info':
        return InfoStep(text: (step.data['text'] ?? '').toString());
      case 'prompt':
        return PromptStep(
          prompt: (step.data['prompt'] ?? '').toString(),
          hint: (step.data['hint'] ?? '').toString(),
          inputEnabled: step.data['inputEnabled'] == true,
          inputLabel: (step.data['inputLabel'] ?? '').toString(),
          inputHint: (step.data['inputHint'] ?? '').toString(),
          submitLabel: (step.data['submitLabel'] ??
                  (widget.lang == 'fr' ? 'Valider' : 'Enter'))
              .toString(),
          displayPrefix: (step.data['displayPrefix'] ??
                  (widget.lang == 'fr' ? 'Tu as ecrit:' : 'You typed:'))
              .toString(),
          emptyInputMessage: (step.data['emptyInputMessage'] ??
                  (widget.lang == 'fr'
                      ? 'Ecris quelque chose d abord.'
                      : 'Please type something first.'))
              .toString(),
        );
      case 'mcq':
        return McqStep(
          question: (step.data['question'] ?? '').toString(),
          choices:
              (step.data['choices'] as List).map((e) => e.toString()).toList(),
          answerIndex: (step.data['answerIndex'] as num).toInt(),
          visuals: (step.data['visuals'] as List? ?? const [])
              .map((e) => e.toString())
              .toList(),
          onAnswered: _onAnswered,
        );
      case 'match':
        return MatchStep(
          instruction: (step.data['instruction'] ?? '').toString(),
          pairs: (step.data['pairs'] as List)
              .map((e) => (e as Map).cast<String, String>())
              .toList(),
          onAnswered: _onAnswered,
        );
      case 'draw':
        return DrawStep(
          prompt: (step.data['prompt'] ?? '').toString(),
          guide: (step.data['guide'] ?? '').toString(),
          target: (step.data['target'] ?? '').toString(),
          lang: widget.lang,
          onAnswered: _onAnswered,
        );
      case 'audio':
        return AudioStep(
          title: (step.data['title'] ?? '').toString(),
          audioPath: (step.data['audioPath'] ?? '').toString(),
          lang: widget.lang,
          fallbackText: (step.data['fallbackText'] ?? '').toString(),
        );
      case 'story':
        return StoryStep(
          title: (step.data['title'] ?? '').toString(),
          text: (step.data['text'] ?? '').toString(),
          audioPath: step.data['audioPath']?.toString(),
          lang: widget.lang,
        );
      case 'external':
        return ExternalStep(
          title: (step.data['title'] ?? '').toString(),
          url: (step.data['url'] ?? '').toString(),
          description: (step.data['description'] ?? '').toString(),
          lang: widget.lang,
        );
      default:
        return const Text("Unsupported step.");
    }
  }
}
