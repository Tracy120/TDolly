import 'package:flutter/material.dart';

import '../models/worksheet_models.dart';
import '../services/lesson_repository.dart';
import '../services/progress_store.dart';
import '../services/tts_service.dart';
import '../widgets/lesson_step_widgets.dart';
import '../widgets/ui.dart';

class InteractiveWorksheetScreen extends StatefulWidget {
  final String lang;
  final InteractiveWorksheetRef worksheetRef;
  final bool returnToPathOnDone;

  const InteractiveWorksheetScreen({
    super.key,
    required this.lang,
    required this.worksheetRef,
    this.returnToPathOnDone = false,
  });

  @override
  State<InteractiveWorksheetScreen> createState() =>
      _InteractiveWorksheetScreenState();
}

class _InteractiveWorksheetScreenState
    extends State<InteractiveWorksheetScreen> {
  final repo = LessonRepository();
  final store = ProgressStore();
  final tts = TtsService();
  late Future<InteractiveWorksheet> future;
  bool voiceOn = true;

  int index = 0;
  int score = 0;
  bool awardedCurrent = false;
  int? selectedChoice;
  String feedback = "";
  bool solvedCurrent = false;
  int lastSpokenIndex = -1;

  @override
  void initState() {
    super.initState();
    future =
        repo.loadInteractiveWorksheet(widget.lang, widget.worksheetRef.file);
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      voiceOn = await store
          .getVoiceOn()
          .timeout(const Duration(seconds: 2), onTimeout: () => true);
    } catch (_) {
      voiceOn = true;
    }
    try {
      await tts.init(lang: widget.lang).timeout(const Duration(seconds: 4));
    } catch (_) {
      voiceOn = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _maybeSpeak(String text, {bool fromUserAction = false}) async {
    if (!voiceOn) return;
    await tts.speak(text, fromUserAction: fromUserAction);
  }

  void _answerChoice(Map<String, dynamic> item, int selected) {
    final answer = (item['answerIndex'] as num?)?.toInt() ?? -1;
    final ok = selected == answer;
    setState(() {
      selectedChoice = selected;
      if (ok) {
        if (!awardedCurrent) {
          score++;
          awardedCurrent = true;
        }
        solvedCurrent = true;
        feedback =
            widget.lang == 'fr' ? "Bravo! Tu as trouve." : "Great! You got it.";
      } else {
        feedback = widget.lang == 'fr'
            ? "Essaie encore, tu peux le faire."
            : "Try again, you can do it.";
      }
    });
    if (!ok) {
      _maybeSpeak(feedback, fromUserAction: true);
    }
  }

  void _next(InteractiveWorksheet worksheet) {
    if (index >= worksheet.items.length - 1) {
      setState(() => index++);
      _maybeSpeak(
          widget.lang == 'fr'
              ? "Fiche terminee. Excellent travail."
              : "Worksheet complete. Excellent work.",
          fromUserAction: true);
      return;
    }
    setState(() {
      index++;
      selectedChoice = null;
      feedback = "";
      solvedCurrent = false;
      awardedCurrent = false;
    });
    _speakCurrentPrompt(worksheet);
  }

  void _speakCurrentPrompt(InteractiveWorksheet worksheet) {
    if (index < 0 || index >= worksheet.items.length) return;
    final item = worksheet.items[index];
    final prompt = (item['prompt'] ?? worksheet.instructions).toString();
    _maybeSpeak(prompt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InteractiveWorksheet>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.worksheetRef.title)),
            body: Center(
              child: Text(widget.lang == 'fr'
                  ? "Impossible de charger cette fiche interactive."
                  : "Could not load this interactive worksheet."),
            ),
          );
        }
        final worksheet = snap.data!;
        if (worksheet.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(worksheet.title)),
            body: Center(
              child: Text(widget.lang == 'fr'
                  ? "Aucune question disponible."
                  : "No questions available."),
            ),
          );
        }
        final finished = index >= worksheet.items.length;
        final progress = finished
            ? 1.0
            : (index + 1) / (worksheet.items.length.clamp(1, 999));
        if (!finished && lastSpokenIndex != index) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _speakCurrentPrompt(worksheet);
          });
          lastSpokenIndex = index;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(worksheet.title),
            actions: [
              IconButton(
                tooltip: widget.lang == 'fr' ? "Voix" : "Voice",
                onPressed: () async {
                  final next = !voiceOn;
                  setState(() => voiceOn = next);
                  await store.setVoiceOn(next);
                  if (next) {
                    tts.registerUserInteraction();
                    _speakCurrentPrompt(worksheet);
                  } else {
                    await tts.stop();
                  }
                },
                icon: Icon(voiceOn ? Icons.volume_up : Icons.volume_off),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEFF5FF), Color(0xFFFFF5F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DollyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worksheet.subtitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        "${widget.lang == 'fr' ? 'Niveau' : 'Level'}: ${worksheet.level}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.blueGrey.shade100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finished
                            ? (widget.lang == 'fr' ? "Termine" : "Finished")
                            : "${widget.lang == 'fr' ? 'Question' : 'Question'} ${index + 1}/${worksheet.items.length}",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!finished)
                  _buildItemCard(worksheet, worksheet.items[index]),
                if (finished) _buildEndCard(worksheet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(
      InteractiveWorksheet worksheet, Map<String, dynamic> item) {
    switch (worksheet.type) {
      case 'circle_count':
        return _buildCircleCount(item, worksheet);
      case 'addition_burst':
        return _buildChoiceMode(item, worksheet, showDots: true);
      case 'sound_detective':
        return _buildChoiceMode(item, worksheet, showDots: false);
      case 'trace_letters':
        return DollyCard(
          child: DrawStep(
            key: ValueKey("trace_$index"),
            prompt: (item['prompt'] ?? '').toString(),
            guide: (item['guide'] ?? '').toString(),
            target: (item['target'] ?? '').toString(),
            onAnswered: (ok) {
              if (ok) {
                if (!awardedCurrent) {
                  setState(() {
                    score++;
                    awardedCurrent = true;
                    solvedCurrent = true;
                    feedback = widget.lang == 'fr'
                        ? "Super trace!"
                        : "Awesome tracing!";
                  });
                }
              } else {
                setState(() {
                  feedback = widget.lang == 'fr'
                      ? "Trace encore un peu puis valide."
                      : "Trace a bit more, then tap done.";
                });
                _maybeSpeak(feedback, fromUserAction: true);
              }
            },
          ),
        );
      default:
        return DollyCard(
          child: Text(widget.lang == 'fr'
              ? "Type non pris en charge."
              : "Unsupported worksheet type."),
        );
    }
  }

  Widget _buildCircleCount(
      Map<String, dynamic> item, InteractiveWorksheet worksheet) {
    final shape = (item['shape'] ?? 'star').toString();
    final count = (item['count'] as num?)?.toInt() ?? 0;
    final choices = (item['choices'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    return DollyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (item['prompt'] ?? worksheet.instructions).toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                count,
                (_) => Icon(_shapeToIcon(shape),
                    size: 30, color: _shapeColor(shape)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(choices.length, (i) {
              final isSel = selectedChoice == i;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _answerChoice(item, i),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSel ? const Color(0xFFDEE8FF) : Colors.white,
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF4A74E8)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    choices[i],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
              );
            }),
          ),
          _buildFeedbackAndNext(worksheet),
        ],
      ),
    );
  }

  Widget _buildChoiceMode(
    Map<String, dynamic> item,
    InteractiveWorksheet worksheet, {
    required bool showDots,
  }) {
    final choices = (item['choices'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    return DollyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (item['prompt'] ?? '').toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          if (showDots) ...[
            const SizedBox(height: 10),
            _buildDotVisual(item),
          ],
          const SizedBox(height: 12),
          ...List.generate(choices.length, (i) {
            final isSel = selectedChoice == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  side: BorderSide(
                      color: isSel
                          ? const Color(0xFF4A74E8)
                          : Colors.grey.shade300,
                      width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor:
                      isSel ? const Color(0xFFEAF0FF) : Colors.white,
                ),
                onPressed: () => _answerChoice(item, i),
                child: Row(
                  children: [
                    Text(
                      choices[i],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (isSel) const Icon(Icons.check_circle),
                  ],
                ),
              ),
            );
          }),
          _buildFeedbackAndNext(worksheet),
        ],
      ),
    );
  }

  Widget _buildDotVisual(Map<String, dynamic> item) {
    final a = (item['a'] as num?)?.toInt();
    final b = (item['b'] as num?)?.toInt();
    final op = (item['op'] ?? '+').toString();
    if (a == null || b == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...List.generate(a, (_) => const _Dot(color: Color(0xFF5B8CFF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            op,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ...List.generate(b, (_) => const _Dot(color: Color(0xFFFF7F6E))),
      ],
    );
  }

  Widget _buildFeedbackAndNext(InteractiveWorksheet worksheet) {
    return Column(
      children: [
        if (feedback.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: solvedCurrent
                  ? const Color(0xFFE9F8EF)
                  : const Color(0xFFFFF3E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: solvedCurrent
                    ? const Color(0xFFB7E4C7)
                    : const Color(0xFFF7D8B3),
              ),
            ),
            child: Text(
              feedback,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (solvedCurrent) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _next(worksheet),
              icon: const Icon(Icons.arrow_forward),
              label: Text(widget.lang == 'fr' ? "Suivant" : "Next"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEndCard(InteractiveWorksheet worksheet) {
    final total = worksheet.items.length;
    final stars = (score * 5 / total).ceil().clamp(1, 5);
    return DollyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lang == 'fr' ? "Fiche terminee!" : "Worksheet complete!",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'fr'
                ? "Score: $score / $total"
                : "Score: $score / $total",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: const Color(0xFFF7B500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.lang == 'fr'
                ? "Recompense: ${worksheet.rewardLabel}"
                : "Reward: ${worksheet.rewardLabel}",
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    index = 0;
                    score = 0;
                    awardedCurrent = false;
                    selectedChoice = null;
                    feedback = "";
                    solvedCurrent = false;
                    lastSpokenIndex = -1;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: Text(widget.lang == 'fr' ? "Rejouer" : "Play again"),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check),
                label: Text(
                  widget.returnToPathOnDone
                      ? (widget.lang == 'fr'
                          ? "Retour au parcours"
                          : "Back to Path")
                      : (widget.lang == 'fr' ? "Terminer" : "Done"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _shapeToIcon(String shape) {
    switch (shape.toLowerCase()) {
      case 'triangle':
        return Icons.change_history;
      case 'square':
        return Icons.crop_square;
      case 'circle':
        return Icons.circle_outlined;
      case 'heart':
        return Icons.favorite;
      default:
        return Icons.star;
    }
  }

  Color _shapeColor(String shape) {
    switch (shape.toLowerCase()) {
      case 'triangle':
        return const Color(0xFF5B8CFF);
      case 'square':
        return const Color(0xFF35B787);
      case 'circle':
        return const Color(0xFFFFA94D);
      case 'heart':
        return const Color(0xFFFF6B7A);
      default:
        return const Color(0xFFF7B500);
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
