import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../services/progress_store.dart';
import '../widgets/ui.dart';
import 'lesson_screen.dart';

class LessonPathScreen extends StatefulWidget {
  final String lang;
  final String worldTitle;
  final Unit unit;

  const LessonPathScreen({
    super.key,
    required this.lang,
    required this.worldTitle,
    required this.unit,
  });

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  final store = ProgressStore();
  Set<String> unlocked = <String>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    final progress = await store.getUnlocked();
    if (!mounted) return;
    setState(() {
      unlocked = progress;
      loading = false;
    });
  }

  String _progressKeyFor(String lessonId) => '${widget.unit.id}:$lessonId';

  bool _isLessonUnlocked(int index) {
    if (index == 0) return true;
    return unlocked.contains(_progressKeyFor(widget.unit.lessons[index].id));
  }

  bool _isLessonCompleted(int index) {
    return unlocked.contains(_progressKeyFor(widget.unit.lessons[index].id));
  }

  Future<void> _openLesson(int index) async {
    if (!_isLessonUnlocked(index)) return;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lang: widget.lang,
          worldTitle: widget.worldTitle,
          unit: widget.unit,
          initialLessonIndex: index,
          stopAfterLesson: true,
        ),
      ),
    );
    if (done == true) {
      await _refreshProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = widget.unit.lessons.length;
    final completed = widget.unit.lessons
        .where((ref) => unlocked.contains(_progressKeyFor(ref.id)))
        .length
        .clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      appBar: AppBar(title: Text(widget.unit.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DollyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'fr'
                      ? 'Aventure: ${widget.worldTitle}'
                      : 'Adventure: ${widget.worldTitle}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lang == 'fr'
                      ? 'Suis le chemin des lecons dans l ordre. Chaque lecon reussie debloque la suivante.'
                      : 'Follow the lesson path in order. Each completed lesson unlocks the next one.',
                ),
                const SizedBox(height: 10),
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
                  widget.lang == 'fr'
                      ? 'Progression: $completed / $total'
                      : 'Progress: $completed / $total',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.unit.lessons.length, (index) {
            final ref = widget.unit.lessons[index];
            final unlockedNow = _isLessonUnlocked(index);
            final completedNow = _isLessonCompleted(index);
            final delayMs = (index * 45).clamp(0, 450);
            final icon = completedNow
                ? Icons.check_circle
                : (unlockedNow ? Icons.play_circle_fill : Icons.lock);
            final color = completedNow
                ? const Color(0xFF2E9E62)
                : (unlockedNow ? const Color(0xFF4A74E8) : Colors.grey.shade400);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1.0),
              duration: Duration(milliseconds: 380 + delayMs),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.55)),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        if (index < widget.unit.lessons.length - 1)
                          Container(
                            width: 2,
                            height: 36,
                            color: (completedNow
                                    ? const Color(0xFF2E9E62)
                                    : const Color(0xFFB4C2E0))
                                .withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DollyCard(
                        onTap: unlockedNow ? () => _openLesson(index) : null,
                        child: Opacity(
                          opacity: unlockedNow ? 1 : 0.68,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ref.title,
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unlockedNow
                                          ? (completedNow
                                              ? (widget.lang == 'fr'
                                                  ? 'Terminee'
                                                  : 'Completed')
                                              : (widget.lang == 'fr'
                                                  ? 'Pret a jouer'
                                                  : 'Ready to start'))
                                          : (widget.lang == 'fr'
                                              ? 'Verrouillee - termine la precedente'
                                              : 'Locked - finish the previous lesson'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
