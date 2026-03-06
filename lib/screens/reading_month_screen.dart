import 'package:flutter/material.dart';

import '../services/lesson_repository.dart';
import '../widgets/ui.dart';
import 'story_reader_screen.dart';

class ReadingMonthScreen extends StatefulWidget {
  final String lang;
  const ReadingMonthScreen({super.key, required this.lang});

  @override
  State<ReadingMonthScreen> createState() => _ReadingMonthScreenState();
}

class _ReadingMonthScreenState extends State<ReadingMonthScreen> {
  final repo = LessonRepository();
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = repo.loadReadingMonth(widget.lang, 'reading_month_pack.json');
  }

  IconData _iconFromName(String raw, {IconData fallback = Icons.menu_book}) {
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
      case 'favorite':
        return Icons.favorite_rounded;
      case 'sort_by_alpha':
        return Icons.sort_by_alpha_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'numbers':
        return Icons.numbers_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'extension':
        return Icons.extension_rounded;
      default:
        return fallback;
    }
  }

  Widget _animatedBadge(IconData icon) {
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
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final months = (data['months'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        final rawStories = (data['stories'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        final seenStoryIds = <String>{};
        final stories = rawStories.where((story) {
          final id = (story['id'] ?? '').toString();
          if (id.isEmpty) return true;
          return seenStoryIds.add(id);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.lang == 'fr' ? 'Histoires courtes' : 'Short Stories',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.lang == 'fr'
                  ? 'Ouvre une histoire: elle est courte, amusante, et peut etre lue a voix haute.'
                  : 'Open a story: each one is short, fun, and can be read aloud.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (stories.isEmpty)
              DollyCard(
                child: Text(widget.lang == 'fr'
                    ? 'Aucune histoire disponible.'
                    : 'No stories available.'),
              ),
            ...stories.map((story) {
              final title = (story['title'] ?? '').toString();
              final summary = (story['summary'] ?? '').toString();
              final iconName = (story['icon'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DollyCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryReaderScreen(
                          lang: widget.lang,
                          story: story,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _animatedBadge(
                        _iconFromName(iconName, fallback: Icons.menu_book_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (summary.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(summary, style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              widget.lang == 'fr' ? 'Calendrier lecture' : 'Reading Calendar',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...months.map((m) {
              final books = (m['books'] as List? ?? const [])
                  .map((e) => e.toString())
                  .toList();
              final monthTitle = (m['title'] ?? '').toString();
              final monthIcon = _iconFromName(
                (m['icon'] ?? '').toString(),
                fallback: Icons.calendar_month_rounded,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DollyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _animatedBadge(monthIcon),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              monthTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (m['goal'] ?? '').toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (books.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.lang == 'fr'
                              ? 'Livres suggeres:'
                              : 'Suggested books:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...books.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "- $b",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
