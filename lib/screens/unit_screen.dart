import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../services/lesson_repository.dart';
import '../widgets/ui.dart';
import 'lesson_path_screen.dart';

class UnitScreen extends StatefulWidget {
  final String lang;
  final WorldRef worldRef;

  const UnitScreen({
    super.key,
    required this.lang,
    required this.worldRef,
  });

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final repo = LessonRepository();
  late Future<World> future;

  @override
  void initState() {
    super.initState();
    future = repo.loadWorld(widget.lang, widget.worldRef.file);
  }

  Unit _dedupeLessons(Unit unit) {
    final seenIds = <String>{};
    final seenFiles = <String>{};
    final unique = <LessonRef>[];
    for (final lesson in unit.lessons) {
      final isNewId = seenIds.add(lesson.id);
      final isNewFile = seenFiles.add(lesson.file);
      if (isNewId && isNewFile) {
        unique.add(lesson);
      }
    }
    return Unit(
      id: unit.id,
      title: unit.title,
      subject: unit.subject,
      lessons: unique,
    );
  }

  Unit _ensureMinimumLessons(Unit unit) {
    final hasPathLessons =
        unit.lessons.any((l) => l.file.startsWith('generated_path:'));
    final targetCount = hasPathLessons ? 20 : 10;
    if (unit.lessons.length >= targetCount) return unit;

    final lessons = List<LessonRef>.from(unit.lessons);
    final seenIds = lessons.map((e) => e.id).toSet();
    final seenFiles = lessons.map((e) => e.file).toSet();
    final subject = unit.subject.toLowerCase();
    final level = _preferredLevel(unit);
    final chapter = _preferredChapter(unit);
    var nextPathNo = 1;
    if (hasPathLessons) {
      final existingPathNos = unit.lessons
          .where((l) => l.file.startsWith('generated_path:'))
          .map((l) => l.file.split(':'))
          .where((parts) => parts.length >= 3)
          .map((parts) => int.tryParse(parts[2]))
          .whereType<int>()
          .toList();
      if (existingPathNos.isNotEmpty) {
        existingPathNos.sort();
        nextPathNo = existingPathNos.last + 1;
      }
    }
    const gameThemes = [
      'letter_hunt',
      'rhyme_race',
      'pattern_dash',
      'kindness_pick',
      'science_flash',
      'word_family',
      'color_match',
      'math_story',
      'shape_count',
      'time_measure',
    ];

    int i = 1;
    while (lessons.length < targetCount && i <= 400) {
      LessonRef candidate;
      if (subject.contains('music')) {
        final songNo = ((i - 1) % 10) + 1;
        candidate = LessonRef(
          id: '${unit.id}_song_${songNo.toString().padLeft(2, '0')}',
          title: widget.lang == 'fr' ? 'Chanson $songNo' : 'Song $songNo',
          type: 'lesson',
          file: 'generated_song:$songNo',
        );
      } else if (subject.contains('game')) {
        final theme = gameThemes[(i - 1) % gameThemes.length];
        candidate = LessonRef(
          id: '${unit.id}_game_${i.toString().padLeft(2, '0')}',
          title: widget.lang == 'fr' ? 'Jeu $i' : 'Game $i',
          type: 'game',
          file: 'generated_game:$theme:$i',
        );
      } else {
        final pathNo = nextPathNo + (i - 1);
        candidate = LessonRef(
          id: '${unit.id}_practice_${pathNo.toString().padLeft(2, '0')}',
          title: widget.lang == 'fr'
              ? 'Pratique $pathNo'
              : 'Practice $pathNo',
          type: 'lesson',
          file: 'generated_path:$chapter:$pathNo:$level',
        );
      }
      if (seenIds.add(candidate.id) && seenFiles.add(candidate.file)) {
        lessons.add(candidate);
      }
      i++;
    }

    return Unit(
      id: unit.id,
      title: unit.title,
      subject: unit.subject,
      lessons: lessons,
    );
  }

  String _preferredLevel(Unit unit) {
    final id = unit.id.toLowerCase();
    if (id.startsWith('k_') || id.contains('_k_')) return 'K';
    return 'Pre-K';
  }

  String _preferredChapter(Unit unit) {
    for (final lesson in unit.lessons) {
      if (lesson.file.startsWith('generated_path:')) {
        final parts = lesson.file.split(':');
        if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
          return parts[1];
        }
      }
    }
    final subject = unit.subject.toLowerCase();
    final title = unit.title.toLowerCase();
    if (subject.contains('math')) {
      if (title.contains('shape') || title.contains('pattern')) {
        return 'shapes_patterns';
      }
      if (title.contains('measure') || title.contains('time')) {
        return 'measurement_time';
      }
      return 'numbers_foundations';
    }
    if (subject.contains('literacy') || title.contains('read')) {
      if (title.contains('blend') || title.contains('phonic')) {
        return 'phonics_sounds';
      }
      if (title.contains('sound')) {
        return 'phonics_sounds';
      }
      return 'reading_comprehension';
    }
    if (subject.contains('writing')) return 'writing_tracing';
    if (subject.contains('science')) return 'science_nature';
    if (subject.contains('sel') || title.contains('kind')) {
      return 'social_emotional';
    }
    if (subject.contains('art')) return 'shapes_patterns';
    return 'problem_solving';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<World>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final world = snap.data!;
        return Scaffold(
          appBar: AppBar(title: Text(world.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(world.description,
                  style: const TextStyle(fontSize: 14, height: 1.3)),
              const SizedBox(height: 14),
              ...world.units.map((u) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DollyCard(
                    onTap: () async {
                      final unit = _ensureMinimumLessons(
                        _dedupeLessons(
                          await repo.loadUnit(widget.lang, u.file),
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonPathScreen(
                            lang: widget.lang,
                            worldTitle: world.title,
                            unit: unit,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.layers),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              DollyChip(u.subject),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
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
