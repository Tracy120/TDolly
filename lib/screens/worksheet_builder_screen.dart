import 'package:flutter/material.dart';

import '../models/worksheet_models.dart';
import '../services/lesson_repository.dart';
import '../widgets/ui.dart';
import 'interactive_worksheet_screen.dart';

class WorksheetBuilderScreen extends StatefulWidget {
  final String lang;
  final bool launchedFromPath;
  const WorksheetBuilderScreen({
    super.key,
    required this.lang,
    this.launchedFromPath = false,
  });

  @override
  State<WorksheetBuilderScreen> createState() => _WorksheetBuilderScreenState();
}

class _WorksheetBuilderScreenState extends State<WorksheetBuilderScreen> {
  static const int _lessonsPerChapter = 10;

  final repo = LessonRepository();
  late Future<InteractiveWorksheetManifest> interactiveFuture;
  String levelFilter = "All";

  @override
  void initState() {
    super.initState();
    interactiveFuture = repo.loadInteractiveWorksheetManifest(widget.lang);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.lang;
    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.launchedFromPath) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.arrow_back),
                label: Text(t == 'fr' ? "Retour au parcours" : "Back to Path"),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            t == 'fr' ? "Fiches d'activites" : "Worksheets",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t == 'fr'
                ? "Mode jeu interactif, sans PDF, pour apprendre en s amusant."
                : "Interactive play mode, no PDF, built for fun learning.",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          FutureBuilder<InteractiveWorksheetManifest>(
            future: interactiveFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const DollyCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snap.hasData) {
                return DollyCard(
                  child: Text(
                    t == 'fr'
                        ? "Impossible de charger les fiches interactives."
                        : "Could not load interactive worksheets.",
                  ),
                );
              }

              final expanded = _mergeWorksheetCatalogs(
                snap.data!.worksheets,
                _buildChapterCatalog(),
              );
              final preCount = expanded.where((e) => e.level == 'Pre-K').length;
              final kCount = expanded.where((e) => e.level == 'K').length;

              final levels = <String>['All', 'Pre-K', 'K'];
              final filtered = levelFilter == 'All'
                  ? expanded
                  : expanded.where((e) => e.level == levelFilter).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DollyCard(
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t == 'fr'
                                ? "Bibliotheque: Pre-K $preCount fiches, K $kCount fiches."
                                : "Library: Pre-K $preCount worksheets, K $kCount worksheets.",
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: levels.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final level = levels[i];
                        return ChoiceChip(
                          label: Text(level),
                          selected: levelFilter == level,
                          onSelected: (_) =>
                              setState(() => levelFilter = level),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filtered.map(_worksheetTile),
                  if (filtered.isEmpty)
                    DollyCard(
                      child: Text(t == 'fr'
                          ? "Aucune fiche pour ce niveau."
                          : "No worksheet for this level."),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DollyCard(
            child: Text(
              t == 'fr'
                  ? "Toutes les fiches ici sont jouables directement dans l application."
                  : "All worksheets here are playable directly in the app.",
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _worksheetTile(InteractiveWorksheetRef w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DollyCard(
        onTap: () async {
          final done = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => InteractiveWorksheetScreen(
                lang: widget.lang,
                worksheetRef: w,
                returnToPathOnDone: widget.launchedFromPath,
              ),
            ),
          );
          if (!mounted) return;
          if (widget.launchedFromPath && done == true) {
            Navigator.pop(context, true);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_hexColor(w.accent).withAlpha(56), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _hexColor(w.accent),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.extension, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(w.subtitle, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        DollyChip(w.level),
                        DollyChip(w.type),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  List<InteractiveWorksheetRef> _buildChapterCatalog() {
    final chapters = _chaptersByLevel();
    final refs = <InteractiveWorksheetRef>[];
    final accents = <String>[
      '#FF8FA3',
      '#4A74E8',
      '#35B787',
      '#F4A259',
      '#8C7DFF',
      '#FF6B6B',
      '#00A6A6',
      '#2E86DE',
    ];

    for (final level in chapters.keys) {
      final defs = chapters[level]!;
      for (int c = 0; c < defs.length; c++) {
        final chapter = defs[c];
        for (int l = 1; l <= _lessonsPerChapter; l++) {
          final id = "generated_${_slug(level)}_${chapter.slug}_$l";
          final chapterLabel = widget.lang == 'fr' ? "Chapitre" : "Chapter";
          final activityLabel = widget.lang == 'fr' ? "Activite" : "Activity";
          refs.add(
            InteractiveWorksheetRef(
              id: id,
              title:
                  "${chapter.title} - ${widget.lang == 'fr' ? 'Lecon' : 'Lesson'} $l",
              subtitle: "$chapterLabel ${c + 1} - $activityLabel $l",
              level: level,
              type: chapter.type,
              file:
                  "generated:${chapter.type}:$level:${c + 1}:${chapter.slug}:$l",
              accent: accents[(c + l) % accents.length],
            ),
          );
        }
      }
    }
    return refs;
  }

  List<InteractiveWorksheetRef> _mergeWorksheetCatalogs(
    List<InteractiveWorksheetRef> manifestRefs,
    List<InteractiveWorksheetRef> generatedRefs,
  ) {
    final merged = <InteractiveWorksheetRef>[];
    final seen = <String>{};

    void addRefs(List<InteractiveWorksheetRef> refs) {
      for (final ref in refs) {
        final key = '${ref.id}|${ref.file}';
        if (seen.add(key)) {
          merged.add(ref);
        }
      }
    }

    addRefs(manifestRefs);
    addRefs(generatedRefs);
    return merged;
  }

  Map<String, List<_ChapterDef>> _chaptersByLevel() {
    final fr = widget.lang == 'fr';
    return {
      'Pre-K': [
        _ChapterDef(
            slug: 'numbers_1_10',
            title: fr ? 'Nombres 1 a 10' : 'Numbers 1 to 10',
            type: 'circle_count'),
        _ChapterDef(
            slug: 'shapes',
            title: fr ? 'Formes' : 'Shapes',
            type: 'circle_count'),
        _ChapterDef(
            slug: 'colors',
            title: fr ? 'Couleurs' : 'Colors',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'letters',
            title: fr ? 'Lettres' : 'Letters',
            type: 'trace_letters'),
        _ChapterDef(
            slug: 'beginning_sounds',
            title: fr ? 'Sons initiaux' : 'Beginning Sounds',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'rhymes',
            title: fr ? 'Rimes' : 'Rhymes',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'patterns',
            title: fr ? 'Motifs' : 'Patterns',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'compare_size',
            title: fr ? 'Comparer les tailles' : 'Compare Size',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'nature_animals',
            title: fr ? 'Nature et animaux' : 'Nature and Animals',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'body_parts_senses',
            title: fr ? 'Corps et sens' : 'Body Parts and Senses',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'kindness',
            title: fr ? 'Bienveillance' : 'Kindness',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'world_shape_path',
            title: fr ? 'Forme du monde' : 'Shape of the World',
            type: 'sound_detective'),
      ],
      'K': [
        _ChapterDef(
            slug: 'number_sense_20',
            title: fr ? 'Sens des nombres jusqu a 20' : 'Number Sense to 20',
            type: 'circle_count'),
        _ChapterDef(
            slug: 'addition',
            title: fr ? 'Addition' : 'Addition',
            type: 'addition_burst'),
        _ChapterDef(
            slug: 'subtraction',
            title: fr ? 'Soustraction' : 'Subtraction',
            type: 'addition_burst'),
        _ChapterDef(
            slug: 'phonics',
            title: fr ? 'Phonique' : 'Phonics',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'sight_words',
            title: fr ? 'Mots outils' : 'Sight Words',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'word_families',
            title: fr ? 'Familles de mots' : 'Word Families',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'sentence_reading',
            title: fr ? 'Lecture de phrases' : 'Sentence Reading',
            type: 'trace_letters'),
        _ChapterDef(
            slug: 'measurement_time',
            title: fr ? 'Mesure et temps' : 'Measurement and Time',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'science_world',
            title: fr ? 'Science du monde' : 'Science World',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'animals_ecosystems',
            title: fr ? 'Animaux et ecosystemes' : 'Animals and Ecosystems',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'world_geography',
            title: fr ? 'Geographie du monde' : 'World Geography',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'history_culture',
            title: fr ? 'Histoire et culture' : 'History and Culture',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'arts_creativity',
            title: fr ? 'Arts creatifs' : 'Creative Arts',
            type: 'trace_letters'),
        _ChapterDef(
            slug: 'world_shape_path',
            title: fr ? 'Forme du monde' : 'Shape of the World',
            type: 'sound_detective'),
        _ChapterDef(
            slug: 'story_problem',
            title: fr ? 'Problemes en histoire' : 'Story Problems',
            type: 'addition_burst'),
      ],
    };
  }

  String _slug(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  Color _hexColor(String hex) {
    final value = hex.replaceAll('#', '');
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF7EA5FF);
  }
}

class _ChapterDef {
  final String slug;
  final String title;
  final String type;

  const _ChapterDef({
    required this.slug,
    required this.title,
    required this.type,
  });
}
