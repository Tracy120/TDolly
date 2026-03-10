import 'package:flutter/material.dart';

import '../services/lesson_repository.dart';
import '../services/progress_store.dart';
import '../widgets/ui.dart';
import 'story_reader_screen.dart';

class ReadingJourneyScreen extends StatefulWidget {
  final String lang;

  const ReadingJourneyScreen({super.key, required this.lang});

  @override
  State<ReadingJourneyScreen> createState() => _ReadingJourneyScreenState();
}

class _ReadingJourneyScreenState extends State<ReadingJourneyScreen> {
  final repo = LessonRepository();
  final store = ProgressStore();

  late Future<void> _loadFuture;
  Map<String, dynamic> _pack = const {};
  Set<String> _unlocked = const {};

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  String _progressKeyFor(String chapterId) {
    return 'reading_journey_${widget.lang}_$chapterId';
  }

  List<Map<String, dynamic>> _chaptersFromPack(Map<String, dynamic> pack) {
    return (pack['chapters'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  Future<void> _load() async {
    final pack = await repo.loadReadingJourney(widget.lang);
    var unlocked = await store.getUnlocked();
    final chapters = _chaptersFromPack(pack);
    if (chapters.isNotEmpty) {
      final firstKey = _progressKeyFor((chapters.first['id'] ?? '').toString());
      if (!unlocked.contains(firstKey)) {
        await store.unlock(firstKey);
        unlocked = await store.getUnlocked();
      }
    }
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _unlocked = unlocked;
    });
  }

  bool _isUnlocked(Map<String, dynamic> chapter) {
    final id = (chapter['id'] ?? '').toString();
    return _unlocked.contains(_progressKeyFor(id));
  }

  Future<void> _openChapter(Map<String, dynamic> chapter, int index) async {
    if (!_isUnlocked(chapter)) return;
    final chapters = _chaptersFromPack(_pack);
    final currentId = (chapter['id'] ?? '').toString();
    if (currentId.isNotEmpty) {
      await store.unlock(_progressKeyFor(currentId));
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryReaderScreen(
          lang: widget.lang,
          story: chapter,
        ),
      ),
    );
    if (index + 1 < chapters.length) {
      final nextId = (chapters[index + 1]['id'] ?? '').toString();
      if (nextId.isNotEmpty) {
        await store.unlock(_progressKeyFor(nextId));
      }
    }
    final refreshed = await store.getUnlocked();
    if (!mounted) return;
    setState(() => _unlocked = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && _pack.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chapters = _chaptersFromPack(_pack);
        final unlockedCount = chapters.where(_isUnlocked).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.lang == 'fr' ? 'Monde Lecture' : 'Reading World'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DollyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_pack['title'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (_pack['subtitle'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DollyChip(
                          widget.lang == 'fr'
                              ? '$unlockedCount/${chapters.length} d\u00E9bloqu\u00E9s'
                              : '$unlockedCount/${chapters.length} unlocked',
                        ),
                        DollyChip(
                          widget.lang == 'fr'
                              ? 'Lecture progressive'
                              : 'Step-by-step reading',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (chapters.isEmpty)
                DollyCard(
                  child: Text(
                    widget.lang == 'fr'
                        ? 'Aucun chapitre disponible.'
                        : 'No chapters available.',
                  ),
                ),
              ...chapters.asMap().entries.map((entry) {
                final index = entry.key;
                final chapter = entry.value;
                final unlocked = _isUnlocked(chapter);
                final chapterNo = (chapter['chapterNo'] ?? index + 1).toString();
                final title = (chapter['title'] ?? '').toString();
                final summary = (chapter['summary'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: unlocked ? 1 : 0.62,
                    child: DollyCard(
                      onTap: unlocked ? () => _openChapter(chapter, index) : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: unlocked
                                  ? Colors.teal.withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              unlocked
                                  ? Icons.menu_book_rounded
                                  : Icons.lock_rounded,
                              color: unlocked
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DollyChip(
                                      widget.lang == 'fr'
                                          ? (unlocked ? 'Ouvert' : 'Bloqu\u00E9')
                                          : (unlocked ? 'Open' : 'Locked'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.lang == 'fr'
                                      ? 'Chapitre $chapterNo'
                                      : 'Chapter $chapterNo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            unlocked ? Icons.chevron_right : Icons.lock_outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
