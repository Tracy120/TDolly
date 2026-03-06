import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/content_models.dart';
import '../models/worksheet_models.dart';

/// Repository for lessons, worksheets, games, etc.  Loads from bundled assets
/// but also lets users add their own files at runtime.  Local content lives in
/// application documents under `lessons/<lang>/` and is preferred over bundle
/// copies when present.
class LessonRepository {
  /// notifies listeners when content has been imported/changed.
  final ValueNotifier<int> contentVersion = ValueNotifier(0);
  final List<Map<String, String>> _songCatalog = const [
    {
      'titleEn': 'Sunny Hello Song',
      'titleFr': 'Chanson Bonjour Soleil',
      'objectiveEn': 'Sing a greeting song while keeping a steady beat.',
      'objectiveFr': 'Chante une chanson de salut avec un rythme regulier.',
      'verseEn': 'Hello sun, hello sky, wave your hands up high.',
      'verseFr': 'Bonjour soleil, bonjour ciel, leve les mains vers le ciel.',
      'beat': 'clap clap pause clap',
      'moveEn': 'Wave, clap twice, pause, then clap once.',
      'moveFr': 'Fais signe, deux claps, pause, puis un clap.',
    },
    {
      'titleEn': 'Jumping Frogs Beat',
      'titleFr': 'Rythme des Grenouilles',
      'objectiveEn': 'Follow a bounce rhythm with body movement.',
      'objectiveFr': 'Suis un rythme qui saute avec ton corps.',
      'verseEn': 'Little frogs jump one two three, splish splash by the tree.',
      'verseFr':
          'Petites grenouilles sautent un deux trois, plouf plouf pres du bois.',
      'beat': 'stomp clap stomp clap',
      'moveEn': 'Stomp on the floor, then clap.',
      'moveFr': 'Tape les pieds puis fais un clap.',
    },
    {
      'titleEn': 'Rain Tap Parade',
      'titleFr': 'Parade de Pluie',
      'objectiveEn': 'Practice soft and loud rhythm control.',
      'objectiveFr': 'Pratique un rythme doux puis fort.',
      'verseEn': 'Raindrops tap, umbrellas pop, puddle feet go hop hop hop.',
      'verseFr':
          'La pluie tape, les parapluies pop, les bottes font hop hop hop.',
      'beat': 'tap tap clap pause',
      'moveEn': 'Tap your knees twice, clap, then freeze.',
      'moveFr': 'Tape deux fois les genoux, clap, puis arrete.',
    },
    {
      'titleEn': 'Rocket Count Song',
      'titleFr': 'Chanson Fusee Compte',
      'objectiveEn': 'Count down with a marching beat.',
      'objectiveFr': 'Compte a rebours avec un rythme de marche.',
      'verseEn': 'Five four three two one, rocket zooming to the sun.',
      'verseFr': 'Cinq quatre trois deux un, la fusee file vers le soleil.',
      'beat': 'clap stomp clap stomp',
      'moveEn': 'Clap and stomp while counting down.',
      'moveFr': 'Clap et tape le pied pendant le compte.',
    },
    {
      'titleEn': 'Color Train Song',
      'titleFr': 'Chanson Train des Couleurs',
      'objectiveEn': 'Name colors in rhythm.',
      'objectiveFr': 'Nomme les couleurs en rythme.',
      'verseEn': 'Red car, blue car, green car on the track.',
      'verseFr': 'Wagon rouge, bleu, vert, sur les rails en file.',
      'beat': 'snap clap snap clap',
      'moveEn': 'Snap fingers then clap.',
      'moveFr': 'Claque les doigts puis fais un clap.',
    },
    {
      'titleEn': 'Shape Dance Jam',
      'titleFr': 'Danse des Formes',
      'objectiveEn': 'Move while naming shapes.',
      'objectiveFr': 'Bouge tout en nommant les formes.',
      'verseEn': 'Circle turn, square step, triangle jump and rest.',
      'verseFr': 'Tourne cercle, pas carre, saute triangle puis pause.',
      'beat': 'clap turn clap turn',
      'moveEn': 'Clap and spin in place.',
      'moveFr': 'Fais un clap puis tourne sur place.',
    },
    {
      'titleEn': 'Kindness Sparkle Song',
      'titleFr': 'Chanson Etincelle Gentille',
      'objectiveEn': 'Sing kind words with expressive rhythm.',
      'objectiveFr': 'Chante des mots gentils avec un rythme expressif.',
      'verseEn': 'Kind words glow, smiles grow, friends shine where we go.',
      'verseFr':
          'Les mots gentils brillent, les sourires grandissent, les amis brillent.',
      'beat': 'tap heart clap smile',
      'moveEn': 'Tap chest, clap, then smile big.',
      'moveFr': 'Tape la poitrine, clap, puis grand sourire.',
    },
    {
      'titleEn': 'Jungle March Song',
      'titleFr': 'Chanson Marche Jungle',
      'objectiveEn': 'Keep a strong marching beat.',
      'objectiveFr': 'Garde un rythme de marche fort.',
      'verseEn': 'Lion steps, monkey hops, jungle band never stops.',
      'verseFr': 'Pas du lion, saut du singe, la fanfare jungle continue.',
      'beat': 'stomp stomp clap roar',
      'moveEn': 'Stomp twice, clap, then make a roar voice.',
      'moveFr': 'Deux pas forts, clap, puis fais un rugissement.',
    },
    {
      'titleEn': 'Sleepy Star Lullaby',
      'titleFr': 'Berceuse Etoiles',
      'objectiveEn': 'Follow a calm slow beat.',
      'objectiveFr': 'Suis un rythme calme et lent.',
      'verseEn': 'Tiny stars blink slow tonight, moon is painting silver light.',
      'verseFr': 'Petites etoiles clignotent, la lune peint une douce lumiere.',
      'beat': 'soft clap pause soft clap',
      'moveEn': 'Clap softly and breathe slowly.',
      'moveFr': 'Clap doucement et respire lentement.',
    },
    {
      'titleEn': 'Picnic Beat Song',
      'titleFr': 'Chanson Pique Nique',
      'objectiveEn': 'Switch between four beat actions.',
      'objectiveFr': 'Change entre quatre actions de rythme.',
      'verseEn': 'Apples, juice, blanket wide, picnic beat side by side.',
      'verseFr': 'Pommes, jus, grande couverture, rythme pique nique ensemble.',
      'beat': 'clap clap stomp tap',
      'moveEn': 'Two claps, one stomp, one knee tap.',
      'moveFr': 'Deux claps, un pas, un tap sur le genou.',
    },
  ];

  Future<Directory> _localLessonDir(String lang) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/lessons/$lang');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _loadStringAssetOrLocal(String lang, String assetFile) async {
    if (kIsWeb) {
      return rootBundle.loadString('assets/lessons/$lang/$assetFile');
    }
    final localDir = await _localLessonDir(lang);
    final localFile = File('${localDir.path}/$assetFile');
    if (await localFile.exists()) {
      return localFile.readAsString();
    }
    return rootBundle.loadString('assets/lessons/$lang/$assetFile');
  }

  Future<T> _loadModelWithLocalFallback<T>({
    required String lang,
    required String assetFile,
    required T Function(Map<String, dynamic> jsonMap) parse,
  }) async {
    try {
      final raw = await _loadStringAssetOrLocal(lang, assetFile);
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Lesson JSON root must be an object.');
      }
      return parse(decoded);
    } catch (e) {
      // If locally imported JSON is bad, gracefully fall back to bundled assets.
      debugPrint('Local content fallback for $assetFile ($lang): $e');
      final raw =
          await rootBundle.loadString('assets/lessons/$lang/$assetFile');
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
            'Bundled lesson JSON root must be an object.');
      }
      return parse(decoded);
    }
  }

  Future<WorldsManifest> loadManifest(String lang) async {
    return _loadModelWithLocalFallback(
      lang: lang,
      assetFile: 'worlds_manifest.json',
      parse: WorldsManifest.fromJson,
    );
  }

  Future<World> loadWorld(String lang, String assetFile) async {
    return _loadModelWithLocalFallback(
      lang: lang,
      assetFile: assetFile,
      parse: World.fromJson,
    );
  }

  Future<Unit> loadUnit(String lang, String assetFile) async {
    return _loadModelWithLocalFallback(
      lang: lang,
      assetFile: assetFile,
      parse: Unit.fromJson,
    );
  }

  Future<Lesson> loadLesson(String lang, String assetFile) async {
    if (assetFile.startsWith('generated_path:')) {
      return _buildGeneratedPathLesson(lang, assetFile);
    }
    if (assetFile.startsWith('generated_song:')) {
      return _buildGeneratedSongLesson(lang, assetFile);
    }
    if (assetFile.startsWith('generated_game:')) {
      return _buildGeneratedGameLesson(lang, assetFile);
    }
    if (assetFile.startsWith('games/')) {
      final packFile = assetFile.substring('games/'.length);
      final pack = await loadGamePack(lang, packFile);
      return _buildLessonFromGamePack(
        lang,
        pack,
        assetFile: assetFile,
      );
    }
    return _loadModelWithLocalFallback(
      lang: lang,
      assetFile: assetFile,
      parse: Lesson.fromJson,
    );
  }

  Lesson _buildGeneratedPathLesson(String lang, String spec) {
    final parts = spec.split(':');
    if (parts.length < 3) {
      throw ArgumentError('Invalid generated path lesson spec: $spec');
    }
    final chapter = parts[1];
    final lessonNo = int.tryParse(parts[2]) ?? 1;
    final level = _normalizePathLevel(parts.length >= 4 ? parts[3] : 'Pre-K');
    final fr = lang == 'fr';

    final id = 'generated_path_${chapter}_${level.toLowerCase()}_$lessonNo';
    final title = _pathTitle(chapter, lessonNo, fr);
    final objective = _pathObjective(chapter, lessonNo, fr, level);
    final baseSteps = _pathSteps(chapter, lessonNo, fr, level);
    final steps = _withTeachThenPracticeIntro(
      steps: baseSteps,
      fr: fr,
      objective: objective,
    );

    return Lesson(id: id, title: title, objective: objective, steps: steps);
  }

  List<LessonStep> _withTeachThenPracticeIntro({
    required List<LessonStep> steps,
    required bool fr,
    required String objective,
  }) {
    if (steps.isEmpty) return steps;
    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'D abord on apprend: $objective'
            : 'First we learn: $objective'
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? 'Observe l exemple puis reponds pas a pas.'
            : 'Watch the example, then answer step by step.',
        'hint': fr
            ? 'Prends ton temps avant les exercices.'
            : 'Take your time before exercises.',
      }),
      ...steps,
    ];
  }

  Lesson _buildGeneratedSongLesson(String lang, String spec) {
    final parts = spec.split(':');
    if (parts.length < 2) {
      throw ArgumentError('Invalid generated song lesson spec: $spec');
    }
    final songNo = int.tryParse(parts[1]) ?? 1;
    final index = (songNo - 1).clamp(0, _songCatalog.length - 1).toInt();
    final entry = _songCatalog[index];
    final fr = lang == 'fr';

    final title = fr ? entry['titleFr']! : entry['titleEn']!;
    final objective = fr ? entry['objectiveFr']! : entry['objectiveEn']!;
    final verse = fr ? entry['verseFr']! : entry['verseEn']!;
    final move = fr ? entry['moveFr']! : entry['moveEn']!;
    final beat = entry['beat']!;
    final id = 'generated_song_${songNo.toString().padLeft(2, '0')}';

    final choices = <String>[
      beat,
      'clap pause clap pause',
      'stomp pause stomp pause',
    ];

    return Lesson(
      id: id,
      title: title,
      objective: objective,
      steps: [
        LessonStep(kind: 'info', data: {
          'text': fr
              ? 'Paroles: $verse Beat: $beat.'
              : 'Lyrics: $verse Beat: $beat.'
        }),
        LessonStep(kind: 'prompt', data: {
          'prompt': fr
              ? 'Chante doucement puis plus fort.'
              : 'Sing once softly, then once louder.',
          'hint': move,
        }),
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Quel rythme correspond a la chanson ?'
              : 'Which beat matches this song?',
          'choices': choices,
          'answerIndex': 0,
          'hint': fr
              ? 'Ecoute le tempo: $beat.'
              : 'Listen to the tempo: $beat.',
        }),
        LessonStep(kind: 'prompt', data: {
          'prompt': fr
              ? 'Ajoute une petite phrase drole pour finir la chanson.'
              : 'Add one funny ending line to the song.',
          'hint': fr
              ? 'Exemple: on danse tous ensemble.'
              : 'Example: everybody dances together.',
          'inputEnabled': true,
          'inputLabel': fr ? 'Ta phrase' : 'Your line',
          'inputHint': fr ? 'Ecris une phrase courte.' : 'Type a short line.',
          'submitLabel': fr ? 'Valider' : 'Submit',
          'displayPrefix': fr ? 'Ta phrase:' : 'Your line:',
          'emptyInputMessage': fr
              ? 'Ecris une petite phrase avant de valider.'
              : 'Please type a short line first.',
        }),
      ],
    );
  }

  Lesson _buildGeneratedGameLesson(String lang, String spec) {
    final parts = spec.split(':');
    if (parts.length < 3) {
      throw ArgumentError('Invalid generated game lesson spec: $spec');
    }
    final theme = parts[1];
    final gameNo = int.tryParse(parts[2]) ?? 1;
    final fr = lang == 'fr';
    final rand = Random(theme.hashCode + (gameNo * 97));

    final id = 'generated_game_${theme}_$gameNo';
    final title = _generatedGameTitle(theme, fr, gameNo);
    final objective = fr
        ? 'Termine 10 mini manches sans repetition.'
        : 'Finish 10 mini rounds with no repetition.';
    final rounds = _generatedGameRounds(
      theme: theme,
      fr: fr,
      gameNo: gameNo,
      rand: rand,
    );
    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Jeu rapide: lis chaque question et touche la meilleure reponse.'
            : 'Quick game: read each question and tap the best answer.'
      }),
      ..._roundsToMcqSteps(rounds, fr),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? 'Super! Quelle manche as-tu preferee?'
            : 'Great! Which round was your favorite?',
        'hint': fr
            ? 'Parle avec une phrase complete.'
            : 'Answer in a full sentence.',
      }),
    ];

    return Lesson(
      id: id,
      title: title,
      objective: objective,
      steps: steps,
    );
  }

  String _generatedGameTitle(String theme, bool fr, int gameNo) {
    switch (theme) {
      case 'letter_hunt':
        return fr ? 'Jeu $gameNo: Chasse aux Lettres' : 'Game $gameNo: Letter Hunt';
      case 'rhyme_race':
        return fr ? 'Jeu $gameNo: Course des Rimes' : 'Game $gameNo: Rhyme Race';
      case 'pattern_dash':
        return fr ? 'Jeu $gameNo: Sprint des Motifs' : 'Game $gameNo: Pattern Dash';
      case 'kindness_pick':
        return fr
            ? 'Jeu $gameNo: Choix Gentils'
            : 'Game $gameNo: Kindness Picks';
      case 'science_flash':
        return fr
            ? 'Jeu $gameNo: Science Flash'
            : 'Game $gameNo: Science Flash';
      case 'word_family':
        return fr
            ? 'Jeu $gameNo: Familles de Mots'
            : 'Game $gameNo: Word Families';
      case 'color_match':
        return fr
            ? 'Jeu $gameNo: Match Couleurs'
            : 'Game $gameNo: Color Match';
      case 'math_story':
        return fr
            ? 'Jeu $gameNo: Histoires Maths'
            : 'Game $gameNo: Story Math';
      case 'shape_count':
        return fr
            ? 'Jeu $gameNo: Compte les Formes'
            : 'Game $gameNo: Shape Count';
      case 'time_measure':
        return fr
            ? 'Jeu $gameNo: Temps et Mesure'
            : 'Game $gameNo: Time and Measure';
      default:
        return fr ? 'Jeu $gameNo' : 'Game $gameNo';
    }
  }

  List<Map<String, dynamic>> _generatedGameRounds({
    required String theme,
    required bool fr,
    required int gameNo,
    required Random rand,
  }) {
    switch (theme) {
      case 'letter_hunt':
        return _genReadingItems(rand, fr, 'Pre-K', 'sight_words', gameNo);
      case 'rhyme_race':
        return _genReadingItems(rand, fr, 'Pre-K', 'rhymes', gameNo);
      case 'pattern_dash':
        return _genReadingItems(rand, fr, 'Pre-K', 'patterns', gameNo);
      case 'kindness_pick':
        return _genReadingItems(rand, fr, 'Pre-K', 'kindness', gameNo);
      case 'science_flash':
        return _genReadingItems(rand, fr, 'K', 'science_world', gameNo);
      case 'word_family':
        return _genReadingItems(rand, fr, 'K', 'word_families', gameNo);
      case 'color_match':
        return _genReadingItems(rand, fr, 'Pre-K', 'colors', gameNo);
      case 'math_story':
        return _genMathItems(rand, fr, 'K', 'story_problem', gameNo);
      case 'shape_count':
        return _genCircleCountItems(
          rand,
          fr,
          'Pre-K',
          'shapes_patterns',
          gameNo,
        );
      case 'time_measure':
        return _genReadingItems(rand, fr, 'K', 'measurement_time', gameNo);
      default:
        return _genReadingItems(rand, fr, 'Pre-K', 'patterns', gameNo);
    }
  }

  List<LessonStep> _roundsToMcqSteps(List<Map<String, dynamic>> rounds, bool fr) {
    final steps = <LessonStep>[];
    final seenPrompts = <String>{};
    for (final row in rounds) {
      final prompt = (row['prompt'] ?? row['question'] ?? '').toString().trim();
      final rawChoices = row['choices'];
      if (prompt.isEmpty || rawChoices is! List) continue;
      if (!seenPrompts.add(prompt)) continue;
      final choices = rawChoices.map((e) => e.toString()).toList();
      if (choices.length < 2) continue;
      int answerIndex = 0;
      if (row['answerIndex'] is num) {
        answerIndex = (row['answerIndex'] as num).toInt();
      }
      if (answerIndex < 0 || answerIndex >= choices.length) {
        answerIndex = 0;
      }
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': prompt,
          'choices': choices,
          'answerIndex': answerIndex,
          'hint': fr
              ? 'Lis chaque choix avant de toucher la reponse.'
              : 'Read each option before tapping your answer.',
        }),
      );
      if (steps.length == 10) break;
    }
    while (steps.length < 10) {
      final roundNo = steps.length + 1;
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Manche bonus $roundNo: touche le mot "Oui".'
              : 'Bonus round $roundNo: tap the word "Yes".',
          'choices': fr ? ['Oui', 'Non', 'Peut-etre'] : ['Yes', 'No', 'Maybe'],
          'answerIndex': 0,
        }),
      );
    }
    return steps;
  }

  Lesson _buildLessonFromGamePack(
    String lang,
    Map<String, dynamic> pack, {
    required String assetFile,
  }) {
    final fr = lang == 'fr';
    final idRaw = (pack['id'] ?? assetFile).toString();
    final id = idRaw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final title = (pack['title'] ?? (fr ? 'Jeu' : 'Game')).toString();
    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Mini jeu: complete toutes les manches.'
            : 'Mini game: complete every round.'
      }),
    ];

    final pairsRaw = pack['pairs'];
    if (pairsRaw is List) {
      final pairs = pairsRaw
          .whereType<List>()
          .where((e) => e.length >= 2)
          .map(
            (e) => {
              'left': e[0].toString(),
              'right': e[1].toString(),
            },
          )
          .toList();
      for (int i = 0; i < pairs.length; i += 5) {
        final chunk = pairs.sublist(i, min(i + 5, pairs.length));
        steps.add(
          LessonStep(kind: 'match', data: {
            'instruction': fr
                ? 'Associe les elements (${i + 1}-${i + chunk.length}).'
                : 'Match the pairs (${i + 1}-${i + chunk.length}).',
            'pairs': chunk,
          }),
        );
      }
    }

    final binsRaw = pack['bins'];
    final itemsRaw = pack['items'];
    if (binsRaw is List && itemsRaw is List && binsRaw.isNotEmpty) {
      final bins = binsRaw.map((e) => e.toString()).toList();
      for (final row in itemsRaw.whereType<List>()) {
        if (row.length < 2) continue;
        final token = row[0].toString();
        final bucket = row[1].toString();
        final answerIndex =
            bins.indexOf(bucket).clamp(0, bins.length - 1).toInt();
        steps.add(
          LessonStep(kind: 'mcq', data: {
            'question': fr
                ? 'Ou va "$token" ?'
                : 'Where does "$token" belong?',
            'choices': bins,
            'answerIndex': answerIndex,
            'hint': fr
                ? 'Choisis le bon groupe.'
                : 'Pick the matching group.',
          }),
        );
      }
    }

    final questionsRaw = pack['questions'];
    if (questionsRaw is List) {
      for (final row in questionsRaw.whereType<Map>()) {
        final q = (row['question'] ?? '').toString();
        final rawChoices = row['choices'];
        if (q.isEmpty || rawChoices is! List || rawChoices.length < 2) continue;
        int answerIndex = 0;
        if (row['answerIndex'] is num) {
          answerIndex = (row['answerIndex'] as num).toInt();
        }
        if (answerIndex < 0 || answerIndex >= rawChoices.length) {
          answerIndex = 0;
        }
        steps.add(
          LessonStep(kind: 'mcq', data: {
            'question': q,
            'choices': rawChoices.map((e) => e.toString()).toList(),
            'answerIndex': answerIndex,
          }),
        );
      }
    }

    if (steps.length == 1) {
      steps.add(
        LessonStep(kind: 'prompt', data: {
          'prompt': fr
              ? 'Ce jeu na pas encore de manches.'
              : 'This game does not have rounds yet.',
          'hint': fr
              ? 'Ajoute des questions dans le pack JSON.'
              : 'Add questions in the JSON game pack.',
        }),
      );
    }

    return Lesson(
      id: 'game_$id',
      title: title,
      objective: fr
          ? 'Complete le jeu et gagne des etoiles.'
          : 'Complete the game and earn stars.',
      steps: steps,
    );
  }

  String _normalizePathLevel(String raw) {
    final val = raw.trim().toLowerCase();
    if (val == 'k' || val.contains('kindergarten')) return 'K';
    return 'Pre-K';
  }

  bool _isKLevel(String level) {
    return level.trim().toLowerCase() == 'k';
  }

  int _lessonRowIndex(int lessonNo, int itemCount, {int cycleShift = 1}) {
    if (itemCount <= 0) {
      return 0;
    }
    final safeLesson = lessonNo < 1 ? 1 : lessonNo;
    final zeroBased = safeLesson - 1;
    final cycle = zeroBased ~/ itemCount;
    final base = zeroBased % itemCount;
    return (base + (cycle * cycleShift)) % itemCount;
  }

  bool _isChallengeLesson(int lessonNo, int itemCount) {
    if (itemCount <= 0) {
      return false;
    }
    final safeLesson = lessonNo < 1 ? 1 : lessonNo;
    return ((safeLesson - 1) ~/ itemCount) > 0;
  }

  String _pathTitle(String chapter, int n, bool fr) {
    final chapterName = _pathChapterName(chapter, fr);
    final lessonWord = fr ? 'Lecon' : 'Lesson';
    return '$chapterName - $lessonWord $n';
  }

  String _pathObjective(String chapter, int n, bool fr, String level) {
    final tag = fr ? 'Objectif' : 'Objective';
    final levelTag = fr ? 'Niveau $level' : 'Level $level';
    switch (chapter) {
      case 'numbers_foundations':
        return '$tag ($levelTag): ${fr ? 'compter, reconnaitre et tracer les nombres' : 'count, recognize, and trace numbers'} ($n).';
      case 'shapes_patterns':
        return '$tag ($levelTag): ${fr ? 'identifier les formes et motifs' : 'identify shapes and patterns'} ($n).';
      case 'alphabet_letters':
        return '$tag ($levelTag): ${fr ? 'reconnaitre les lettres et leurs mots' : 'recognize letters and word links'} ($n).';
      case 'phonics_sounds':
        return '$tag ($levelTag): ${fr ? 'ecouter les sons initiaux' : 'hear beginning sounds'} ($n).';
      case 'reading_comprehension':
        return '$tag ($levelTag): ${fr ? 'comprendre un petit texte' : 'understand a short text'} ($n).';
      case 'writing_tracing':
        return '$tag ($levelTag): ${fr ? 'ecrire et tracer avec precision' : 'write and trace with control'} ($n).';
      case 'social_emotional':
        return '$tag ($levelTag): ${fr ? 'choisir des actions positives' : 'choose positive actions'} ($n).';
      case 'science_nature':
        return '$tag ($levelTag): ${fr ? 'observer la nature et la science' : 'observe nature and science ideas'} ($n).';
      case 'measurement_time':
        return '$tag ($levelTag): ${fr ? 'mesurer et lire le temps' : 'measure and read time'} ($n).';
      case 'problem_solving':
        return '$tag ($levelTag): ${fr ? 'resoudre des problemes pas a pas' : 'solve problems step by step'} ($n).';
      case 'creative_arts':
        return '$tag ($levelTag): ${fr ? 'creer des projets artistiques originaux' : 'create original art projects'} ($n).';
      case 'world_geography':
        return '$tag ($levelTag): ${fr ? 'explorer les cartes, lieux et cultures du monde' : 'explore maps, places, and world cultures'} ($n).';
      case 'history_culture':
        return '$tag ($levelTag): ${fr ? 'comprendre le passe, le present et les traditions' : 'understand past, present, and traditions'} ($n).';
      default:
        return '$tag ($levelTag): ${fr ? 'apprendre avec pratique' : 'learn through guided practice'} ($n).';
    }
  }

  String _pathChapterName(String chapter, bool fr) {
    switch (chapter) {
      case 'numbers_foundations':
        return fr ? 'Nombres Fondamentaux' : 'Numbers Foundations';
      case 'shapes_patterns':
        return fr ? 'Formes et Motifs' : 'Shapes and Patterns';
      case 'alphabet_letters':
        return fr ? 'Alphabet et Lettres' : 'Alphabet and Letters';
      case 'phonics_sounds':
        return fr ? 'Phonique et Sons' : 'Phonics and Sounds';
      case 'reading_comprehension':
        return fr ? 'Comprehension de Lecture' : 'Reading Comprehension';
      case 'writing_tracing':
        return fr ? 'Ecriture et Tracage' : 'Writing and Tracing';
      case 'social_emotional':
        return fr
            ? 'Competences Socio-Emotionnelles'
            : 'Social Emotional Skills';
      case 'science_nature':
        return fr ? 'Science et Nature' : 'Science and Nature';
      case 'measurement_time':
        return fr ? 'Mesure et Temps' : 'Measurement and Time';
      case 'problem_solving':
        return fr ? 'Resolution de Problemes' : 'Problem Solving';
      case 'creative_arts':
        return fr ? 'Arts Creatifs' : 'Creative Arts';
      case 'world_geography':
        return fr ? 'Geographie du Monde' : 'World Geography';
      case 'history_culture':
        return fr ? 'Histoire et Culture' : 'History and Culture';
      default:
        return fr ? 'Parcours' : 'Path';
    }
  }

  List<LessonStep> _pathSteps(String chapter, int n, bool fr, String level) {
    switch (chapter) {
      case 'numbers_foundations':
        return _pathNumbersSteps(n, fr, level);
      case 'shapes_patterns':
        return _pathShapesSteps(n, fr, level);
      case 'alphabet_letters':
        return _pathAlphabetSteps(n, fr, level);
      case 'phonics_sounds':
        return _pathPhonicsSteps(n, fr, level);
      case 'reading_comprehension':
        return _pathReadingSteps(n, fr, level);
      case 'writing_tracing':
        return _pathWritingSteps(n, fr, level);
      case 'social_emotional':
        return _pathSelSteps(n, fr, level);
      case 'science_nature':
        return _pathScienceSteps(n, fr, level);
      case 'measurement_time':
        return _pathMeasureSteps(n, fr, level);
      case 'problem_solving':
        return _pathProblemSteps(n, fr, level);
      case 'creative_arts':
        return _pathCreativeArtsSteps(n, fr, level);
      case 'world_geography':
        return _pathWorldGeographySteps(n, fr, level);
      case 'history_culture':
        return _pathHistoryCultureSteps(n, fr, level);
      default:
        return [
          LessonStep(kind: 'info', data: {
            'text': fr ? 'Lecon en preparation.' : 'Lesson in preparation.'
          }),
          LessonStep(kind: 'prompt', data: {
            'prompt': fr ? 'Dis ce que tu as appris.' : 'Say what you learned.',
            'hint':
                fr ? 'Utilise une phrase complete.' : 'Use a complete sentence.'
          }),
        ];
    }
  }

  List<LessonStep> _pathNumbersSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final minValue = isK ? 21 : 1;
    final maxValue = isK ? 50 : 20;
    final window = isK ? 5 : 3;
    final maxStart = isK ? 45 : 17;
    final step = isK ? 3 : 2;
    final startSpan = maxStart - minValue + 1;
    final start = minValue + (((n - 1) * step) % startSpan);
    final end = (start + window).clamp(minValue, maxValue).toInt();
    final rangeText = '$start-$end';

    final practice = <int>{
      start,
      ((start + end) ~/ 2),
      end,
      (start + 1).clamp(1, isK ? 50 : 20),
    }.toList()
      ..sort();

    List<String> neighborChoices(int value, int min, int max) {
      var low = min;
      var high = max;
      if (low > high) {
        final tmp = low;
        low = high;
        high = tmp;
      }

      final target = value.clamp(low, high).toInt();
      final set = <int>{target};
      final probes = <int>[
        target - 1,
        target + 1,
        target - 2,
        target + 2,
        low,
        high,
        ((low + high) ~/ 2),
      ];

      for (final probe in probes) {
        set.add(probe.clamp(low, high).toInt());
        if (set.length >= 3) break;
      }

      if (set.length < 3) {
        for (var v = low; v <= high && set.length < 3; v++) {
          set.add(v);
        }
      }

      final out = set.take(3).map((e) => '$e').toList();
      while (out.length < 3) {
        out.add('$target');
      }
      return out;
    }

    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? 'Lecon $n (K) - Nombres $rangeText. Objectif: lire, comparer et decomposer les nombres.'
                : 'Lecon $n (Pre-K) - Nombres $rangeText. Objectif: reconnaitre et compter.')
            : (isK
                ? 'Lesson $n (K) - Numbers $rangeText. Goal: read, compare, and compose numbers.'
                : 'Lesson $n (Pre-K) - Numbers $rangeText. Goal: recognize and count.')
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Compte de $start a $end, puis de $end a $start.'
                : 'Compte lentement de $start a $end.')
            : (isK
                ? 'Count from $start to $end, then backward from $end to $start.'
                : 'Count slowly from $start to $end.'),
        'hint': fr
            ? 'Utilise ton doigt pour suivre les nombres.'
            : 'Use your finger to track each number.'
      }),
    ];

    for (final value in practice.take(3)) {
      final choices = neighborChoices(value, start, end);
      steps.add(
        LessonStep(kind: 'draw', data: {
          'prompt': fr ? 'Trace le nombre $value.' : 'Trace number $value.',
          'guide': fr
              ? 'Ecris proprement et lis le nombre a voix haute.'
              : 'Write neatly and read the number aloud.',
          'target': '$value'
        }),
      );
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question':
              fr ? 'Choisis le nombre $value.' : 'Pick the number $value.',
          'choices': choices,
          'answerIndex': choices.indexOf('$value'),
          'hint': fr
              ? 'Observe les chiffres avec attention.'
              : 'Look carefully at the digits.'
        }),
      );
    }

    final compareA = practice.first;
    final compareB = practice.last;
    final greater = compareA > compareB ? compareA : compareB;

    steps.addAll([
      LessonStep(kind: 'mcq', data: {
        'question':
            fr ? 'Quel nombre est le plus grand ?' : 'Which number is greater?',
        'choices': ['$compareA', '$compareB', '${(compareA + compareB) ~/ 2}'],
        'answerIndex': [
          '$compareA',
          '$compareB',
          '${(compareA + compareB) ~/ 2}'
        ].indexOf('$greater'),
        'hint': fr
            ? 'Le plus grand nombre a la plus grande valeur.'
            : 'The greater number has the larger value.'
      }),
      LessonStep(kind: 'match', data: {
        'instruction':
            fr ? 'Associe nombre et ecriture.' : 'Match number and word form.',
        'pairs': [
          {'left': '$start', 'right': _numberWord(start, fr)},
          {
            'left': '${((start + end) ~/ 2)}',
            'right': _numberWord(((start + end) ~/ 2), fr)
          },
          {'left': '$end', 'right': _numberWord(end.toInt(), fr)},
        ]
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Explique comment tu sais comparer deux nombres.'
                : 'Dis un nombre prefere entre $start et $end.')
            : (isK
                ? 'Explain how you compare two numbers.'
                : 'Say your favorite number between $start and $end.'),
        'hint': fr ? 'Utilise une phrase complete.' : 'Use a complete sentence.'
      }),
    ]);

    return steps;
  }

  List<LessonStep> _pathShapesSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final List<Map<String, Object>> shapes = [
      {
        'nameEn': 'circle',
        'nameFr': 'cercle',
        'propertyEn': 'no corners',
        'propertyFr': 'pas de coin',
        'sides': 0,
        'target': 'O'
      },
      {
        'nameEn': 'triangle',
        'nameFr': 'triangle',
        'propertyEn': '3 sides',
        'propertyFr': '3 cotes',
        'sides': 3,
        'target': 'A'
      },
      {
        'nameEn': 'square',
        'nameFr': 'carre',
        'propertyEn': '4 equal sides',
        'propertyFr': '4 cotes egaux',
        'sides': 4,
        'target': 'S'
      },
      {
        'nameEn': 'rectangle',
        'nameFr': 'rectangle',
        'propertyEn': '4 sides, 2 long and 2 short',
        'propertyFr': '4 cotes, 2 longs et 2 courts',
        'sides': 4,
        'target': 'R'
      },
      {
        'nameEn': 'oval',
        'nameFr': 'ovale',
        'propertyEn': 'rounded stretched circle',
        'propertyFr': 'cercle allonge',
        'sides': 0,
        'target': 'O'
      },
      {
        'nameEn': 'star',
        'nameFr': 'etoile',
        'propertyEn': 'points and angles',
        'propertyFr': 'pointes et angles',
        'sides': 0,
        'target': 'E'
      },
      {
        'nameEn': 'heart',
        'nameFr': 'coeur',
        'propertyEn': 'curved top, pointed bottom',
        'propertyFr': 'haut courbe, bas pointu',
        'sides': 0,
        'target': 'C'
      },
      {
        'nameEn': 'diamond',
        'nameFr': 'losange',
        'propertyEn': '4 equal sides tilted',
        'propertyFr': '4 cotes egaux inclines',
        'sides': 4,
        'target': 'L'
      },
      {
        'nameEn': 'pentagon',
        'nameFr': 'pentagone',
        'propertyEn': '5 sides',
        'propertyFr': '5 cotes',
        'sides': 5,
        'target': 'P'
      },
      {
        'nameEn': 'hexagon',
        'nameFr': 'hexagone',
        'propertyEn': '6 sides',
        'propertyFr': '6 cotes',
        'sides': 6,
        'target': 'H'
      },
      {
        'nameEn': 'octagon',
        'nameFr': 'octogone',
        'propertyEn': '8 sides',
        'propertyFr': '8 cotes',
        'sides': 8,
        'target': 'O'
      },
    ];
    const colorsEn = [
      'red',
      'blue',
      'green',
      'yellow',
      'orange',
      'purple',
      'pink',
      'brown',
      'black',
      'white',
      'gray',
      'gold'
    ];
    const colorsFr = [
      'rouge',
      'bleu',
      'vert',
      'jaune',
      'orange',
      'violet',
      'rose',
      'marron',
      'noir',
      'blanc',
      'gris',
      'dore'
    ];
    final colorObjectsEn = <String, String>{
      'red': 'apple',
      'blue': 'sky',
      'green': 'grass',
      'yellow': 'banana',
      'orange': 'orange fruit',
      'purple': 'grape',
      'pink': 'flower',
      'brown': 'tree trunk',
      'black': 'night sky',
      'white': 'cloud',
      'gray': 'elephant',
      'gold': 'sun'
    };
    final colorObjectsFr = <String, String>{
      'rouge': 'pomme',
      'bleu': 'ciel',
      'vert': 'herbe',
      'jaune': 'banane',
      'orange': 'orange',
      'violet': 'raisin',
      'rose': 'fleur',
      'marron': 'tronc',
      'noir': 'nuit',
      'blanc': 'nuage',
      'gris': 'elephant',
      'dore': 'soleil'
    };

    String shapeName(Map<String, Object> shape) =>
        (fr ? shape['nameFr'] : shape['nameEn']).toString();
    String shapeProperty(Map<String, Object> shape) =>
        (fr ? shape['propertyFr'] : shape['propertyEn']).toString();

    List<String> sideChoices(int sides) {
      final set = <int>{sides, max(3, sides - 1), sides + 1};
      var probe = sides + 2;
      while (set.length < 3) {
        set.add(probe);
        probe++;
      }
      return set.map((e) => '$e').toList();
    }

    final focusCount = isK ? 5 : 4;
    final start = ((n - 1) * 2) % shapes.length;
    final focus =
        List.generate(focusCount, (i) => shapes[(start + i) % shapes.length]);
    final colorSource = fr ? colorsFr : colorsEn;
    final focusColors = List.generate(
      4,
      (i) => colorSource[((n - 1) * 3 + i) % colorSource.length],
    );
    final colorObjects = fr ? colorObjectsFr : colorObjectsEn;

    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Lecon $n (${isK ? 'K' : 'Pre-K'}) - Formes: ${focus.map(shapeName).join(', ')}. Couleurs: ${focusColors.join(', ')}.'
            : 'Lesson $n (${isK ? 'K' : 'Pre-K'}) - Shapes: ${focus.map(shapeName).join(', ')}. Colors: ${focusColors.join(', ')}.'
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Observe les objets autour de toi et repere leurs formes.'
                : 'Regarde autour de toi et nomme des formes simples.')
            : (isK
                ? 'Look around and identify the shapes of objects.'
                : 'Look around and name simple shapes.'),
        'hint': fr
            ? (isK
                ? 'Pense aux cotes, aux coins et aux courbes.'
                : 'Pense a rond, triangle, carre, rectangle.')
            : (isK
                ? 'Think about sides, corners, and curves.'
                : 'Think of circle, triangle, square, rectangle.')
      }),
    ];

    for (final shape in focus.take(isK ? 3 : 2)) {
      final name = shapeName(shape);
      steps.add(
        LessonStep(kind: 'draw', data: {
          'prompt': fr ? 'Dessine un $name.' : 'Draw a $name.',
          'guide': fr
              ? 'Dis son nom et compte ses cotes ou coins.'
              : 'Say its name and count sides or corners.',
          'target': shape['target']
        }),
      );
    }

    for (final shape in focus.take(3)) {
      final name = shapeName(shape);
      final property = shapeProperty(shape);
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Quelle propriete correspond au $name ?'
              : 'Which property matches a $name?',
          'choices': [
            property,
            fr ? 'nombre de lettres du mot' : 'number of letters in the word',
            fr ? 'taille de l objet' : 'size of the object',
          ],
          'answerIndex': 0,
          'hint': fr
              ? 'Repense a la definition geometrique.'
              : 'Think about the geometry definition.'
        }),
      );
    }

    if (isK) {
      final withSides = focus
          .where((shape) => ((shape['sides'] ?? 0) as int) > 0)
          .toList(growable: false);
      final targetShape = withSides.isNotEmpty ? withSides.first : focus.first;
      final sides = (targetShape['sides'] ?? 0) as int;
      final choices = sideChoices(sides);
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Combien de cotes a un ${shapeName(targetShape)} ?'
              : 'How many sides does a ${shapeName(targetShape)} have?',
          'choices': choices,
          'answerIndex': choices.indexOf('$sides'),
          'hint': fr
              ? 'Compte les segments un par un.'
              : 'Count the straight sides one by one.'
        }),
      );
    }

    final patternA = shapeName(focus[0]);
    final patternB = shapeName(focus[1]);
    final patternC = shapeName(focus[2]);
    steps.add(
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel mot complete le motif: $patternA, $patternB, $patternA, $patternB, ... ?'
            : 'Which word completes the pattern: $patternA, $patternB, $patternA, $patternB, ... ?',
        'choices': [patternA, patternB, patternC],
        'answerIndex': 0,
        'hint': fr
            ? 'Les formes se repetent dans le meme ordre.'
            : 'The shapes repeat in the same order.'
      }),
    );

    steps.addAll([
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe chaque forme a sa caracteristique.'
            : 'Match each shape to its feature.',
        'pairs': focus
            .take(4)
            .map((shape) =>
                {'left': shapeName(shape), 'right': shapeProperty(shape)})
            .toList()
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe chaque couleur a un objet courant.'
            : 'Match each color to a common object.',
        'pairs': focusColors
            .take(3)
            .map((color) => {
                  'left': color,
                  'right': colorObjects[color] ?? (fr ? 'objet' : 'object')
                })
            .toList()
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Nomme deux formes et deux couleurs que tu vois maintenant.'
                : 'Nomme une forme et une couleur autour de toi.')
            : (isK
                ? 'Name two shapes and two colors you can see now.'
                : 'Name one shape and one color around you.'),
        'hint': fr
            ? 'Observe les details des objets dans la piece.'
            : 'Look closely at details of objects in the room.',
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta reponse' : 'Your answer',
        'inputHint': fr
            ? (isK
                ? 'Exemple: carre rouge, cercle bleu'
                : 'Exemple: cercle jaune')
            : (isK
                ? 'Example: red square, blue circle'
                : 'Example: yellow circle'),
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris au moins une forme ou une couleur.'
            : 'Please type at least one shape or color.'
      }),
    ]);

    return steps;
  }

  List<LessonStep> _pathAlphabetSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    const coreGroups = [
      ['A', 'B', 'C', 'D', 'E'],
      ['F', 'G', 'H', 'I', 'J'],
      ['K', 'L', 'M', 'N', 'O'],
      ['P', 'Q', 'R', 'S', 'T'],
      ['U', 'V', 'W', 'X', 'Y', 'Z'],
    ];
    const reviewGroups = [
      ['A', 'G', 'M', 'S', 'Y'],
      ['B', 'H', 'N', 'T', 'Z'],
      ['C', 'I', 'O', 'U'],
      ['D', 'J', 'P', 'V'],
      ['E', 'K', 'Q', 'W', 'X', 'F', 'L', 'R'],
    ];
    final wordsEn = <String, String>{
      'A': 'apple',
      'B': 'ball',
      'C': 'cat',
      'D': 'dog',
      'E': 'egg',
      'F': 'fish',
      'G': 'goat',
      'H': 'hat',
      'I': 'igloo',
      'J': 'juice',
      'K': 'kite',
      'L': 'lion',
      'M': 'moon',
      'N': 'nest',
      'O': 'octopus',
      'P': 'pig',
      'Q': 'queen',
      'R': 'rabbit',
      'S': 'sun',
      'T': 'tree',
      'U': 'umbrella',
      'V': 'violin',
      'W': 'whale',
      'X': 'xylophone',
      'Y': 'yak',
      'Z': 'zebra'
    };
    final wordsFr = <String, String>{
      'A': 'avion',
      'B': 'balle',
      'C': 'chat',
      'D': 'doudou',
      'E': 'ecole',
      'F': 'fleur',
      'G': 'gateau',
      'H': 'herisson',
      'I': 'igloo',
      'J': 'jus',
      'K': 'koala',
      'L': 'lune',
      'M': 'maman',
      'N': 'nez',
      'O': 'orange',
      'P': 'poisson',
      'Q': 'quiche',
      'R': 'robot',
      'S': 'soleil',
      'T': 'tomate',
      'U': 'uniforme',
      'V': 'velo',
      'W': 'wagon',
      'X': 'xylophone',
      'Y': 'yaourt',
      'Z': 'zebre'
    };

    String wordFor(String letter) => fr ? wordsFr[letter]! : wordsEn[letter]!;
    final allWords = (fr ? wordsFr.values : wordsEn.values).toList();
    final idx = _lessonRowIndex(n, coreGroups.length, cycleShift: 2);
    final challenge = _isChallengeLesson(n, coreGroups.length);
    final group = challenge ? reviewGroups[idx] : coreGroups[idx];
    final first = group.first;
    final second = group.length > 1 ? group[1] : group.first;
    final third = group.length > 2 ? group[2] : group.last;

    List<String> wordChoices(String correct) {
      final choices = <String>[correct];
      for (final word in allWords) {
        if (word != correct && !choices.contains(word)) {
          choices.add(word);
        }
        if (choices.length == 3) {
          break;
        }
      }
      return choices;
    }

    List<String> letterChoices(String correct, String wrongA, String wrongB) {
      final choices = <String>{correct, wrongA, wrongB}.toList();
      for (final letter in group) {
        if (!choices.contains(letter)) {
          choices.add(letter);
        }
        if (choices.length == 3) {
          break;
        }
      }
      return choices.take(3).toList();
    }

    if (!isK) {
      final firstChoices = wordChoices(wordFor(first));
      final afterChoices = letterChoices(second, first, third);
      return [
        LessonStep(kind: 'info', data: {
          'text': fr
              ? (challenge
                  ? 'Lecon $n (Pre-K) - Revision active des lettres ${group.join(', ')}.'
                  : 'Lecon $n (Pre-K) - Lettres ${group.join(', ')}. Nous apprenons le nom de chaque lettre et un mot exemple.')
              : (challenge
                  ? 'Lesson $n (Pre-K) - Active review letters ${group.join(', ')}.'
                  : 'Lesson $n (Pre-K) - Letters ${group.join(', ')}. We learn each letter name and one example word.')
        }),
        LessonStep(kind: 'prompt', data: {
          'prompt': fr
              ? (challenge
                  ? 'Defi: dis puis epelle les lettres ${group.join(', ')}.'
                  : 'Dis les lettres ${group.join(', ')} lentement.')
              : (challenge
                  ? 'Challenge: say and spell letters ${group.join(', ')}.'
                  : 'Say letters ${group.join(', ')} slowly.'),
          'hint': fr
              ? (challenge
                  ? 'Essaie une voix douce puis une voix forte.'
                  : 'Tape dans les mains une fois par lettre.')
              : (challenge
                  ? 'Try a soft voice, then a strong voice.'
                  : 'Clap once for each letter.')
        }),
        LessonStep(kind: 'draw', data: {
          'prompt': fr ? 'Trace la lettre $first.' : 'Trace letter $first.',
          'guide': fr
              ? 'Commence en haut et suis le modele.'
              : 'Start at the top and follow the model.',
          'target': first
        }),
        LessonStep(kind: 'draw', data: {
          'prompt': fr ? 'Trace la lettre $second.' : 'Trace letter $second.',
          'guide': fr
              ? 'Dis le son de la lettre en tracant.'
              : 'Say the letter sound while tracing.',
          'target': second
        }),
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Quel mot commence par $first ?'
              : 'Which word starts with $first?',
          'choices': firstChoices,
          'answerIndex': firstChoices.indexOf(wordFor(first)),
          'hint': fr
              ? 'Ecoute le premier son du mot.'
              : 'Listen to the first sound.'
        }),
        LessonStep(kind: 'mcq', data: {
          'question': fr
              ? 'Quelle lettre vient apres $first ?'
              : 'Which letter comes after $first?',
          'choices': afterChoices,
          'answerIndex': afterChoices.indexOf(second),
          'hint': fr
              ? 'Recite l alphabet dans l ordre.'
              : 'Say the alphabet in order.'
        }),
        LessonStep(kind: 'match', data: {
          'instruction': fr
              ? 'Associe lettre et mot.'
              : 'Match each letter with its word.',
          'pairs': group
              .take(3)
              .map((letter) => {'left': letter, 'right': wordFor(letter)})
              .toList()
        }),
        LessonStep(kind: 'match', data: {
          'instruction': fr
              ? 'Associe majuscule et minuscule.'
              : 'Match uppercase and lowercase.',
          'pairs': group
              .take(4)
              .map((letter) => {'left': letter, 'right': letter.toLowerCase()})
              .toList()
        }),
        LessonStep(kind: 'prompt', data: {
          'prompt': fr
              ? 'Ecris un mot qui commence par $second.'
              : 'Type one word that starts with $second.',
          'hint': fr
              ? 'Tu peux utiliser le mot de la lecon.'
              : 'You can reuse a lesson word.',
          'inputEnabled': true,
          'inputLabel': fr ? 'Ton mot' : 'Your word',
          'inputHint': wordFor(second),
          'submitLabel': fr ? 'Valider' : 'Enter',
          'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
          'emptyInputMessage': fr
              ? 'Ecris un mot avant de valider.'
              : 'Type a word before submitting.'
        }),
      ];
    }

    final kRowsEn = <Map<String, dynamic>>[
      {
        'focus': 'alphabetical order',
        'trace': 'MNOP',
        'q1': 'Which letters are in correct order?',
        'c1': ['M N O P', 'M O N P', 'P O N M'],
        'a1': 0,
        'q2': 'Which letter comes before N?',
        'c2': ['M', 'O', 'P'],
        'a2': 0,
        'pairs': [
          {'left': 'A', 'right': 'a'},
          {'left': 'M', 'right': 'm'},
          {'left': 'R', 'right': 'r'},
        ],
        'drawPrompt': 'Draw a letter train in order: M N O P.',
        'drawGuide': 'Write uppercase and lowercase under each.',
        'inputPrompt': 'Type the alphabet from A to H in order.',
        'inputHint': 'A B C D E F G H'
      },
      {
        'focus': 'short vowels',
        'trace': 'AT',
        'q1': 'Which word has the short a sound?',
        'c1': ['cat', 'kite', 'moon'],
        'a1': 0,
        'q2': 'Which word is in the -at family?',
        'c2': ['hat', 'hen', 'hop'],
        'a2': 0,
        'pairs': [
          {'left': 'a', 'right': 'cat'},
          {'left': 'e', 'right': 'bed'},
          {'left': 'i', 'right': 'pig'},
        ],
        'drawPrompt': 'Draw and label one -at word.',
        'drawGuide': 'Examples: cat, hat, bat.',
        'inputPrompt': 'Type one more word from the -at family.',
        'inputHint': 'cat/hat/bat'
      },
      {
        'focus': 'digraphs',
        'trace': 'SH',
        'q1': 'Which word starts with SH?',
        'c1': ['ship', 'cat', 'book'],
        'a1': 0,
        'q2': 'Which word starts with CH?',
        'c2': ['chair', 'sun', 'map'],
        'a2': 0,
        'pairs': [
          {'left': 'SH', 'right': 'ship'},
          {'left': 'CH', 'right': 'chair'},
          {'left': 'TH', 'right': 'thumb'},
        ],
        'drawPrompt': 'Draw one SH object and one CH object.',
        'drawGuide': 'Say each beginning sound aloud.',
        'inputPrompt': 'Type one word with TH.',
        'inputHint': 'thumb/three'
      },
      {
        'focus': 'blends',
        'trace': 'BR',
        'q1': 'Which word starts with BR?',
        'c1': ['bread', 'apple', 'sun'],
        'a1': 0,
        'q2': 'Which word starts with CL?',
        'c2': ['clock', 'moon', 'fish'],
        'a2': 0,
        'pairs': [
          {'left': 'BR', 'right': 'bread'},
          {'left': 'CL', 'right': 'clock'},
          {'left': 'ST', 'right': 'star'},
        ],
        'drawPrompt': 'Draw and label a BR or CL word.',
        'drawGuide': 'Underline the blend letters.',
        'inputPrompt': 'Type one word that starts with ST.',
        'inputHint': 'star/stop'
      },
      {
        'focus': 'long vowels and silent e',
        'trace': 'CAPE',
        'q1': 'Which word has silent e?',
        'c1': ['cake', 'cat', 'cup'],
        'a1': 0,
        'q2': 'Which pair has same long a sound?',
        'c2': ['cake and gate', 'cat and bed', 'pig and top'],
        'a2': 0,
        'pairs': [
          {'left': 'cap', 'right': 'short a'},
          {'left': 'cape', 'right': 'long a'},
          {'left': 'bit', 'right': 'bite'},
        ],
        'drawPrompt': 'Draw cap and cape, then label both.',
        'drawGuide': 'Circle the silent e in cape.',
        'inputPrompt': 'Type one silent-e word.',
        'inputHint': 'cake/make/home'
      },
    ];
    final kRowsFr = <Map<String, dynamic>>[
      {
        'focus': 'ordre alphabetique',
        'trace': 'MNOP',
        'q1': 'Quelle suite est dans le bon ordre ?',
        'c1': ['M N O P', 'M O N P', 'P O N M'],
        'a1': 0,
        'q2': 'Quelle lettre vient avant N ?',
        'c2': ['M', 'O', 'P'],
        'a2': 0,
        'pairs': [
          {'left': 'A', 'right': 'a'},
          {'left': 'M', 'right': 'm'},
          {'left': 'R', 'right': 'r'},
        ],
        'drawPrompt': 'Dessine un train de lettres: M N O P.',
        'drawGuide': 'Ecris la minuscule sous chaque majuscule.',
        'inputPrompt': 'Ecris l alphabet de A a H dans l ordre.',
        'inputHint': 'A B C D E F G H'
      },
      {
        'focus': 'sons voyelles simples',
        'trace': 'AN',
        'q1': 'Quel mot contient le son AN ?',
        'c1': ['ananas', 'velo', 'livre'],
        'a1': 0,
        'q2': 'Quel mot contient le son ON ?',
        'c2': ['ballon', 'table', 'chat'],
        'a2': 0,
        'pairs': [
          {'left': 'AN', 'right': 'ananas'},
          {'left': 'ON', 'right': 'ballon'},
          {'left': 'IN', 'right': 'lapin'},
        ],
        'drawPrompt': 'Dessine et ecris un mot avec AN ou ON.',
        'drawGuide': 'Souligne les lettres du son.',
        'inputPrompt': 'Ecris un mot avec IN.',
        'inputHint': 'lapin/matin'
      },
      {
        'focus': 'digrammes',
        'trace': 'CH',
        'q1': 'Quel mot commence par CH ?',
        'c1': ['chat', 'table', 'velo'],
        'a1': 0,
        'q2': 'Quel mot contient OU ?',
        'c2': ['ours', 'chat', 'lit'],
        'a2': 0,
        'pairs': [
          {'left': 'CH', 'right': 'chat'},
          {'left': 'OU', 'right': 'ours'},
          {'left': 'ON', 'right': 'maison'},
        ],
        'drawPrompt': 'Dessine un objet avec CH et un avec OU.',
        'drawGuide': 'Dis les sons au debut du mot.',
        'inputPrompt': 'Ecris un mot avec CH.',
        'inputHint': 'chat/chaise'
      },
      {
        'focus': 'blends et groupes consonnes',
        'trace': 'TR',
        'q1': 'Quel mot commence par TR ?',
        'c1': ['train', 'ananas', 'moto'],
        'a1': 0,
        'q2': 'Quel mot commence par PL ?',
        'c2': ['plume', 'chat', 'soleil'],
        'a2': 0,
        'pairs': [
          {'left': 'TR', 'right': 'train'},
          {'left': 'PL', 'right': 'plume'},
          {'left': 'BR', 'right': 'brosse'},
        ],
        'drawPrompt': 'Dessine un mot TR ou PL.',
        'drawGuide': 'Entoure les deux premieres lettres.',
        'inputPrompt': 'Ecris un mot qui commence par BR.',
        'inputHint': 'brosse/bruit'
      },
      {
        'focus': 'syllabes et lecture de mots',
        'trace': 'MAI',
        'q1': 'Quel mot a deux syllabes ?',
        'c1': ['maison', 'chat', 'bleu'],
        'a1': 0,
        'q2': 'Quelle syllabe est au debut de "lapin" ?',
        'c2': ['la', 'pin', 'in'],
        'a2': 0,
        'pairs': [
          {'left': 'maison', 'right': 'mai-son'},
          {'left': 'lapin', 'right': 'la-pin'},
          {'left': 'robot', 'right': 'ro-bot'},
        ],
        'drawPrompt': 'Dessine un mot de deux syllabes.',
        'drawGuide': 'Tape dans les mains pour chaque syllabe.',
        'inputPrompt': 'Ecris un mot et coupe-le en syllabes.',
        'inputHint': 'maison = mai-son'
      },
    ];

    final kRows = fr ? kRowsFr : kRowsEn;
    final kIdx = _lessonRowIndex(n, kRows.length, cycleShift: 2);
    final kChallenge = _isChallengeLesson(n, kRows.length);
    final row = kRows[kIdx];
    final pairList = (row['pairs'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final q1Question = kChallenge
        ? (fr
            ? 'Defi: Quel element correspond a ${pairList[0]['left']} ?'
            : 'Challenge: Which item matches ${pairList[0]['left']}?')
        : row['q1'].toString();
    final q1Choices = kChallenge
        ? [
            pairList[0]['right']!,
            pairList[1]['right']!,
            pairList[2]['right']!,
          ]
        : (row['c1'] as List).map((e) => e.toString()).toList();
    final q1Answer = kChallenge ? 0 : (row['a1'] as num).toInt();
    final q2Question = kChallenge
        ? (fr
            ? 'Defi: Quel symbole va avec "${pairList[1]['right']}" ?'
            : 'Challenge: Which symbol goes with "${pairList[1]['right']}"?')
        : row['q2'].toString();
    final q2Choices = kChallenge
        ? [
            pairList[1]['left']!,
            pairList[0]['left']!,
            pairList[2]['left']!,
          ]
        : (row['c2'] as List).map((e) => e.toString()).toList();
    final q2Answer = kChallenge ? 0 : (row['a2'] as num).toInt();

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (kChallenge
                ? 'Lecon $n (K) - Defi lecture/sons: ${row['focus']}.'
                : 'Lecon $n (K) - ${row['focus']}. Objectif: lire et ecrire des mots plus avances.')
            : (kChallenge
                ? 'Lesson $n (K) - Reading/sound challenge: ${row['focus']}.'
                : 'Lesson $n (K) - ${row['focus']}. Goal: read and write more advanced words.')
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (kChallenge
                ? 'Defi: lis, repere le motif, puis explique ton choix.'
                : 'Lis les exemples puis ecoute le son principal.')
            : (kChallenge
                ? 'Challenge: read, spot the pattern, and explain your choice.'
                : 'Read the examples and listen for the main sound.'),
        'hint': fr
            ? (kChallenge
                ? 'Compare les mots et cherche ce qui revient.'
                : 'Observe les lettres qui se repetent.')
            : (kChallenge
                ? 'Compare words and look for recurring patterns.'
                : 'Watch for repeating letter patterns.')
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': fr
            ? 'Trace le modele: ${row['trace']}.'
            : 'Trace the model: ${row['trace']}.',
        'guide': fr
            ? 'Lis ce que tu traces a voix haute.'
            : 'Read aloud while tracing.',
        'target': row['trace']
      }),
      LessonStep(kind: 'mcq', data: {
        'question': q1Question,
        'choices': q1Choices,
        'answerIndex': q1Answer,
        'hint': fr
            ? 'Concentre-toi sur le son du debut.'
            : 'Focus on the beginning sound.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': q2Question,
        'choices': q2Choices,
        'answerIndex': q2Answer,
        'hint': fr
            ? 'Repere les lettres du son cible.'
            : 'Find the target sound letters.'
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr ? 'Associe correctement.' : 'Match correctly.',
        'pairs': (row['pairs'] as List)
            .map((e) => (e as Map).cast<String, String>())
            .toList()
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': row['drawPrompt'],
        'guide': row['drawGuide'],
        'target': row['trace']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': row['inputPrompt'],
        'hint':
            fr ? 'Ecris proprement en une ligne.' : 'Write neatly in one line.',
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta reponse' : 'Your answer',
        'inputHint': row['inputHint'],
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une reponse avant de valider.'
            : 'Type a response before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathPhonicsSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final preRowsEn = <Map<String, String>>[
      {
        'sound': 'm',
        'word': 'moon',
        'wrong1': 'sun',
        'wrong2': 'ball',
        'rhyme': 'room',
        'nonRhyme': 'cat',
        'trace': 'M'
      },
      {
        'sound': 's',
        'word': 'sun',
        'wrong1': 'map',
        'wrong2': 'book',
        'rhyme': 'fun',
        'nonRhyme': 'tree',
        'trace': 'S'
      },
      {
        'sound': 'b',
        'word': 'ball',
        'wrong1': 'moon',
        'wrong2': 'egg',
        'rhyme': 'tall',
        'nonRhyme': 'fish',
        'trace': 'B'
      },
      {
        'sound': 't',
        'word': 'tree',
        'wrong1': 'apple',
        'wrong2': 'sun',
        'rhyme': 'bee',
        'nonRhyme': 'dog',
        'trace': 'T'
      },
      {
        'sound': 'c',
        'word': 'cat',
        'wrong1': 'umbrella',
        'wrong2': 'sun',
        'rhyme': 'hat',
        'nonRhyme': 'book',
        'trace': 'C'
      },
    ];
    final preRowsFr = <Map<String, String>>[
      {
        'sound': 'm',
        'word': 'maman',
        'wrong1': 'soleil',
        'wrong2': 'balle',
        'rhyme': 'maman',
        'nonRhyme': 'chat',
        'trace': 'M'
      },
      {
        'sound': 's',
        'word': 'savon',
        'wrong1': 'table',
        'wrong2': 'livre',
        'rhyme': 'ballon',
        'nonRhyme': 'chat',
        'trace': 'S'
      },
      {
        'sound': 'b',
        'word': 'balle',
        'wrong1': 'lune',
        'wrong2': 'ami',
        'rhyme': 'salle',
        'nonRhyme': 'nez',
        'trace': 'B'
      },
      {
        'sound': 't',
        'word': 'table',
        'wrong1': 'orange',
        'wrong2': 'sac',
        'rhyme': 'fable',
        'nonRhyme': 'chat',
        'trace': 'T'
      },
      {
        'sound': 'c',
        'word': 'chat',
        'wrong1': 'uniforme',
        'wrong2': 'soleil',
        'rhyme': 'rat',
        'nonRhyme': 'livre',
        'trace': 'C'
      },
    ];
    final kRowsEn = <Map<String, String>>[
      {
        'chunk': 'SH',
        'word': 'ship',
        'wrong1': 'cat',
        'wrong2': 'book',
        'endWord': 'fish',
        'endWrong1': 'sun',
        'endWrong2': 'table',
        'trace': 'SH'
      },
      {
        'chunk': 'CH',
        'word': 'chair',
        'wrong1': 'moon',
        'wrong2': 'apple',
        'endWord': 'beach',
        'endWrong1': 'tree',
        'endWrong2': 'dog',
        'trace': 'CH'
      },
      {
        'chunk': 'TH',
        'word': 'thumb',
        'wrong1': 'zebra',
        'wrong2': 'ball',
        'endWord': 'bath',
        'endWrong1': 'cat',
        'endWrong2': 'sun',
        'trace': 'TH'
      },
      {
        'chunk': 'BR',
        'word': 'bread',
        'wrong1': 'leaf',
        'wrong2': 'ice',
        'endWord': 'car',
        'endWrong1': 'dog',
        'endWrong2': 'sun',
        'trace': 'BR'
      },
      {
        'chunk': 'PL',
        'word': 'plant',
        'wrong1': 'rain',
        'wrong2': 'book',
        'endWord': 'seal',
        'endWrong1': 'sun',
        'endWrong2': 'map',
        'trace': 'PL'
      },
    ];
    final kRowsFr = <Map<String, String>>[
      {
        'chunk': 'CH',
        'word': 'chat',
        'wrong1': 'table',
        'wrong2': 'velo',
        'endWord': 'bouche',
        'endWrong1': 'maman',
        'endWrong2': 'soleil',
        'trace': 'CH'
      },
      {
        'chunk': 'OU',
        'word': 'ours',
        'wrong1': 'chat',
        'wrong2': 'livre',
        'endWord': 'genou',
        'endWrong1': 'table',
        'endWrong2': 'moto',
        'trace': 'OU'
      },
      {
        'chunk': 'AN',
        'word': 'ananas',
        'wrong1': 'velo',
        'wrong2': 'chat',
        'endWord': 'ruban',
        'endWrong1': 'soleil',
        'endWrong2': 'lune',
        'trace': 'AN'
      },
      {
        'chunk': 'ON',
        'word': 'ballon',
        'wrong1': 'moto',
        'wrong2': 'livre',
        'endWord': 'maison',
        'endWrong1': 'chat',
        'endWrong2': 'velo',
        'trace': 'ON'
      },
      {
        'chunk': 'IN',
        'word': 'lapin',
        'wrong1': 'table',
        'wrong2': 'radio',
        'endWord': 'matin',
        'endWrong1': 'soleil',
        'endWrong2': 'maman',
        'trace': 'IN'
      },
    ];

    final source = isK ? (fr ? kRowsFr : kRowsEn) : (fr ? preRowsFr : preRowsEn);
    final i = _lessonRowIndex(n, source.length, cycleShift: 1);
    final challenge = _isChallengeLesson(n, source.length);
    final row = source[i];
    final focus = isK ? row['chunk']! : row['sound']!;
    final modelWord = row['word']!;
    final firstMcqChoices = challenge
        ? [modelWord, row['wrong2']!, row['wrong1']!]
        : [modelWord, row['wrong1']!, row['wrong2']!];
    final secondMcqChoices = isK
        ? (challenge
            ? [row['endWord']!, row['endWrong2']!, row['endWrong1']!]
            : [row['endWord']!, row['endWrong1']!, row['endWrong2']!])
        : (challenge
            ? [row['rhyme']!, row['wrong1']!, row['nonRhyme']!]
            : [row['rhyme']!, row['nonRhyme']!, row['wrong1']!]);
    final anchorPairs = source;
    final pairRows = List.generate(
      3,
      (idx) => anchorPairs[(i + idx + (challenge ? 1 : 0)) % anchorPairs.length],
    );

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? (challenge
                    ? 'Lecon $n (K): Defi phonique sur le groupe $focus.'
                    : 'Lecon $n (K): Nous travaillons le groupe de lettres $focus dans des mots.')
                : (challenge
                    ? 'Lecon $n (Pre-K): Defi revision du son /$focus/.'
                    : 'Lecon $n (Pre-K): Nous ecoutons et repetons le son /$focus/.'))
            : (isK
                ? (challenge
                    ? 'Lesson $n (K): Phonics challenge on chunk $focus.'
                    : 'Lesson $n (K): We practice the letter chunk $focus in words.')
                : (challenge
                    ? 'Lesson $n (Pre-K): Sound review challenge for /$focus/.'
                    : 'Lesson $n (Pre-K): We listen to and repeat /$focus/.'))
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? (challenge
                    ? 'Defi: lis "$modelWord" puis dis ou tu entends le son.'
                    : 'Lis ce mot: $modelWord. Quel son special entends-tu ?')
                : (challenge
                    ? 'Defi: repete /$focus/ puis donne un mot qui commence pareil.'
                    : 'Repete le son /$focus/ trois fois.'))
            : (isK
                ? (challenge
                    ? 'Challenge: read "$modelWord" and say where you hear the chunk.'
                    : 'Read this word: $modelWord. Which special sound do you hear?')
                : (challenge
                    ? 'Challenge: repeat /$focus/ and give one matching starter word.'
                    : 'Repeat the /$focus/ sound three times.')),
        'hint': fr
            ? (isK
                ? 'Cherche le son au debut ou a la fin du mot.'
                : 'Parle lentement et clairement.')
            : (isK
                ? 'Listen for the chunk at the beginning or end.'
                : 'Speak slowly and clearly.')
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': fr
            ? (isK
                ? 'Trace le groupe $focus puis lis $modelWord.'
                : 'Trace la lettre du son $focus.')
            : (isK
                ? 'Trace chunk $focus and read $modelWord.'
                : 'Trace the letter for sound $focus.'),
        'guide': fr
            ? 'Ecris proprement et dis le son a voix haute.'
            : 'Write neatly and say the sound aloud.',
        'target': row['trace']
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? (isK
                ? (challenge
                    ? 'Defi: Quel mot commence clairement par $focus ?'
                    : 'Quel mot contient le son $focus ?')
                : (challenge
                    ? 'Defi: Quel mot commence avec /$focus/ ?'
                    : 'Quel mot commence par le son /$focus/ ?'))
            : (isK
                ? (challenge
                    ? 'Challenge: Which word clearly starts with $focus?'
                    : 'Which word contains sound $focus?')
                : (challenge
                    ? 'Challenge: Which word starts with /$focus/?'
                    : 'Which word starts with /$focus/?')),
        'choices': firstMcqChoices,
        'answerIndex': 0,
        'hint':
            fr ? 'Ecoute le son du debut.' : 'Listen to the beginning sound.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? (isK
                ? (challenge
                    ? 'Defi: Quel mot finit avec le son de la lecon ?'
                    : 'Quel mot se termine avec le son cible de la lecon ?')
                : (challenge
                    ? 'Defi: Quel mot rime le mieux avec $modelWord ?'
                    : 'Quel mot rime avec $modelWord ?'))
            : (isK
                ? (challenge
                    ? 'Challenge: Which word ends with the lesson sound?'
                    : 'Which word ends with the target sound?')
                : (challenge
                    ? 'Challenge: Which word rhymes best with $modelWord?'
                    : 'Which word rhymes with $modelWord?')),
        'choices': secondMcqChoices,
        'answerIndex': 0,
        'hint': fr
            ? (isK
                ? 'Concentre-toi sur le dernier son.'
                : 'Les mots qui riment se ressemblent a la fin.')
            : (isK
                ? 'Focus on the ending sound.'
                : 'Rhyming words sound similar at the end.')
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? (isK
                ? 'Associe groupe de lettres et mot.'
                : 'Associe son et mot.')
            : (isK ? 'Match letter chunk and word.' : 'Match sound and word.'),
        'pairs': pairRows
            .map((r) => {
                  'left': (isK ? r['chunk']! : r['sound']!).toString(),
                  'right': r['word']!.toString(),
                })
            .toList()
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Ecris un mot qui contient $focus.'
                : 'Ecris un mot qui commence par $focus.')
            : (isK
                ? 'Type one word that contains $focus.'
                : 'Type one word that starts with $focus.'),
        'hint': fr
            ? 'Tu peux utiliser un mot de la lecon.'
            : 'You can reuse a lesson word.',
        'inputEnabled': true,
        'inputLabel': fr ? 'Ton mot' : 'Your word',
        'inputHint': modelWord,
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris un mot avant de valider.'
            : 'Type a word before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathReadingSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final preEn = <Map<String, dynamic>>[
      {
        'text': 'Lina sees a black cat in the garden.',
        'q1': 'Who does Lina see?',
        'c1': ['a cat', 'a bus', 'a moon'],
        'a1': 0,
        'q2': 'Where is the cat?',
        'c2': ['in the garden', 'in a school', 'in a pool'],
        'a2': 0,
        'pairs': [
          {'left': 'cat', 'right': 'animal'},
          {'left': 'garden', 'right': 'place'},
          {'left': 'sees', 'right': 'action'},
        ],
        'drawPrompt': 'Draw the cat from the story.',
        'drawGuide': 'Add one detail from the garden.',
        'drawTarget': 'C'
      },
      {
        'text': 'Tom has two apples and shares one with his friend.',
        'q1': 'What does Tom share?',
        'c1': ['an apple', 'a pencil', 'a ball'],
        'a1': 0,
        'q2': 'How many apples does Tom start with?',
        'c2': ['two', 'one', 'five'],
        'a2': 0,
        'pairs': [
          {'left': 'apple', 'right': 'food'},
          {'left': 'friend', 'right': 'person'},
          {'left': 'shares', 'right': 'action'},
        ],
        'drawPrompt': 'Draw Tom and two apples.',
        'drawGuide': 'Circle the apple he shares.',
        'drawTarget': 'A'
      },
      {
        'text': 'In the morning, Sara goes to school with her bag.',
        'q1': 'Where does Sara go?',
        'c1': ['to school', 'to the zoo', 'to the beach'],
        'a1': 0,
        'q2': 'When does she go?',
        'c2': ['in the morning', 'at night', 'at noon'],
        'a2': 0,
        'pairs': [
          {'left': 'school', 'right': 'place'},
          {'left': 'bag', 'right': 'object'},
          {'left': 'morning', 'right': 'time'},
        ],
        'drawPrompt': 'Draw Sara going to school.',
        'drawGuide': 'Add her school bag.',
        'drawTarget': 'S'
      },
      {
        'text': 'Noah waters a plant so it can grow.',
        'q1': 'What does Noah do?',
        'c1': ['he waters a plant', 'he sleeps', 'he jumps'],
        'a1': 0,
        'q2': 'Why does he water it?',
        'c2': ['so it can grow', 'so it can fly', 'so it can run'],
        'a2': 0,
        'pairs': [
          {'left': 'plant', 'right': 'living thing'},
          {'left': 'water', 'right': 'need'},
          {'left': 'grow', 'right': 'change'},
        ],
        'drawPrompt': 'Draw Noah and the plant.',
        'drawGuide': 'Show water drops.',
        'drawTarget': 'P'
      },
      {
        'text': 'Mila reads a story before sleeping.',
        'q1': 'What does Mila read?',
        'c1': ['a story', 'a map', 'a recipe'],
        'a1': 0,
        'q2': 'When does she read?',
        'c2': ['before sleeping', 'during lunch', 'on the bus'],
        'a2': 0,
        'pairs': [
          {'left': 'reads', 'right': 'action'},
          {'left': 'story', 'right': 'text'},
          {'left': 'before', 'right': 'time word'},
        ],
        'drawPrompt': 'Draw Mila reading.',
        'drawGuide': 'Add a book and a bed.',
        'drawTarget': 'R'
      },
    ];
    final preFr = <Map<String, dynamic>>[
      {
        'text': 'Lina voit un chat noir dans le jardin.',
        'q1': 'Qui Lina voit-elle ?',
        'c1': ['un chat', 'un bus', 'une lune'],
        'a1': 0,
        'q2': 'Ou est le chat ?',
        'c2': ['dans le jardin', 'a l ecole', 'a la piscine'],
        'a2': 0,
        'pairs': [
          {'left': 'chat', 'right': 'animal'},
          {'left': 'jardin', 'right': 'lieu'},
          {'left': 'voit', 'right': 'action'},
        ],
        'drawPrompt': 'Dessine le chat de l histoire.',
        'drawGuide': 'Ajoute un detail du jardin.',
        'drawTarget': 'C'
      },
      {
        'text': 'Tom a deux pommes et en partage une avec son ami.',
        'q1': 'Que partage Tom ?',
        'c1': ['une pomme', 'un crayon', 'une balle'],
        'a1': 0,
        'q2': 'Combien de pommes a-t-il au debut ?',
        'c2': ['deux', 'une', 'cinq'],
        'a2': 0,
        'pairs': [
          {'left': 'pomme', 'right': 'nourriture'},
          {'left': 'ami', 'right': 'personne'},
          {'left': 'partage', 'right': 'action'},
        ],
        'drawPrompt': 'Dessine Tom avec deux pommes.',
        'drawGuide': 'Entoure la pomme partagee.',
        'drawTarget': 'A'
      },
      {
        'text': 'Le matin, Sara va a l ecole avec son sac.',
        'q1': 'Ou va Sara ?',
        'c1': ['a l ecole', 'au zoo', 'a la plage'],
        'a1': 0,
        'q2': 'Quand y va-t-elle ?',
        'c2': ['le matin', 'la nuit', 'a midi'],
        'a2': 0,
        'pairs': [
          {'left': 'ecole', 'right': 'lieu'},
          {'left': 'sac', 'right': 'objet'},
          {'left': 'matin', 'right': 'moment'},
        ],
        'drawPrompt': 'Dessine Sara qui va a l ecole.',
        'drawGuide': 'Ajoute son sac.',
        'drawTarget': 'S'
      },
      {
        'text': 'Noe arrose une plante pour qu elle grandisse.',
        'q1': 'Que fait Noe ?',
        'c1': ['il arrose une plante', 'il dort', 'il saute'],
        'a1': 0,
        'q2': 'Pourquoi arrose-t-il ?',
        'c2': [
          'pour qu elle grandisse',
          'pour qu elle vole',
          'pour qu elle coure'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'plante', 'right': 'etre vivant'},
          {'left': 'eau', 'right': 'besoin'},
          {'left': 'grandir', 'right': 'changement'},
        ],
        'drawPrompt': 'Dessine Noe et la plante.',
        'drawGuide': 'Montre des gouttes d eau.',
        'drawTarget': 'P'
      },
      {
        'text': 'Mila lit une histoire avant de dormir.',
        'q1': 'Que lit Mila ?',
        'c1': ['une histoire', 'une carte', 'une recette'],
        'a1': 0,
        'q2': 'Quand lit-elle ?',
        'c2': ['avant de dormir', 'a midi', 'dans le bus'],
        'a2': 0,
        'pairs': [
          {'left': 'lit', 'right': 'action'},
          {'left': 'histoire', 'right': 'texte'},
          {'left': 'avant', 'right': 'mot de temps'},
        ],
        'drawPrompt': 'Dessine Mila qui lit.',
        'drawGuide': 'Ajoute un livre et un lit.',
        'drawTarget': 'R'
      },
    ];
    final kEn = <Map<String, dynamic>>[
      {
        'text':
            'Lina forgets her coat. The wind is strong, so she goes back to get it before class.',
        'q1': 'Why does Lina go back?',
        'c1': ['It is cold and windy', 'She wants a toy', 'She wants to sleep'],
        'a1': 0,
        'q2': 'What happens first?',
        'c2': [
          'She forgets her coat',
          'She sits in class',
          'She plays outside'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'wind', 'right': 'weather'},
          {'left': 'coat', 'right': 'clothing'},
          {'left': 'before class', 'right': 'sequence'},
        ],
        'drawPrompt': 'Draw Lina getting ready for class.',
        'drawGuide': 'Show the weather in your picture.',
        'drawTarget': 'L'
      },
      {
        'text':
            'Tom finishes homework and puts away his pencils before playing with his team.',
        'q1': 'What does Tom do before playing?',
        'c1': ['He puts away his pencils', 'He watches TV', 'He goes to sleep'],
        'a1': 0,
        'q2': 'Which word means the same as "puts away"?',
        'c2': ['stores', 'breaks', 'throws'],
        'a2': 0,
        'pairs': [
          {'left': 'homework', 'right': 'school task'},
          {'left': 'team', 'right': 'group'},
          {'left': 'before', 'right': 'time word'},
        ],
        'drawPrompt': 'Draw Tom finishing homework.',
        'drawGuide': 'Add pencils and a tidy desk.',
        'drawTarget': 'T'
      },
      {
        'text':
            'Sara reads a map to find the library near the park. She turns left at the bakery.',
        'q1': 'What tool does Sara use?',
        'c1': ['a map', 'a spoon', 'a toy'],
        'a1': 0,
        'q2': 'Where is the library?',
        'c2': ['near the park', 'inside the bakery', 'next to a lake'],
        'a2': 0,
        'pairs': [
          {'left': 'map', 'right': 'tool'},
          {'left': 'library', 'right': 'place'},
          {'left': 'left', 'right': 'direction'},
        ],
        'drawPrompt': 'Draw a simple map to the library.',
        'drawGuide': 'Add the park and bakery.',
        'drawTarget': 'M'
      },
      {
        'text':
            'Noah plants seeds. He waters them every day and measures the sprouts each week.',
        'q1': 'What does Noah do every day?',
        'c1': ['He waters the seeds', 'He throws them away', 'He hides them'],
        'a1': 0,
        'q2': 'What does he measure each week?',
        'c2': ['the sprouts', 'the clouds', 'the wind'],
        'a2': 0,
        'pairs': [
          {'left': 'seeds', 'right': 'start of plant'},
          {'left': 'sprouts', 'right': 'young plants'},
          {'left': 'measure', 'right': 'check size'},
        ],
        'drawPrompt': 'Draw the seed growing into a sprout.',
        'drawGuide': 'Use arrows to show change over time.',
        'drawTarget': 'G'
      },
      {
        'text':
            'Mila writes a list: book, pencil, eraser, and water bottle. She checks her bag before class.',
        'q1': 'Why does Mila check her bag?',
        'c1': ['To be prepared', 'To hide toys', 'To take a nap'],
        'a1': 0,
        'q2': 'Which item is NOT on her list?',
        'c2': ['soccer ball', 'book', 'pencil'],
        'a2': 0,
        'pairs': [
          {'left': 'list', 'right': 'organized notes'},
          {'left': 'prepared', 'right': 'ready'},
          {'left': 'before class', 'right': 'time phrase'},
        ],
        'drawPrompt': 'Draw Mila packing her school bag.',
        'drawGuide': 'Include at least three listed items.',
        'drawTarget': 'B'
      },
    ];
    final kFr = <Map<String, dynamic>>[
      {
        'text':
            'Lina oublie son manteau. Le vent souffle fort, alors elle retourne le chercher avant la classe.',
        'q1': 'Pourquoi Lina retourne-t-elle ?',
        'c1': [
          'Il fait froid et venteux',
          'Elle cherche un jouet',
          'Elle veut dormir'
        ],
        'a1': 0,
        'q2': 'Quelle action vient en premier ?',
        'c2': [
          'Elle oublie son manteau',
          'Elle entre en classe',
          'Elle joue dehors'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'vent', 'right': 'meteo'},
          {'left': 'manteau', 'right': 'vetement'},
          {'left': 'avant la classe', 'right': 'ordre'},
        ],
        'drawPrompt': 'Dessine Lina qui se prepare pour la classe.',
        'drawGuide': 'Montre la meteo dans ton dessin.',
        'drawTarget': 'L'
      },
      {
        'text':
            'Tom termine ses devoirs puis range ses crayons avant de jouer avec son equipe.',
        'q1': 'Que fait Tom avant de jouer ?',
        'c1': ['Il range ses crayons', 'Il regarde la TV', 'Il dort'],
        'a1': 0,
        'q2': 'Quel mot veut dire presque la meme chose que "range" ?',
        'c2': ['organise', 'casse', 'jette'],
        'a2': 0,
        'pairs': [
          {'left': 'devoirs', 'right': 'travail scolaire'},
          {'left': 'equipe', 'right': 'groupe'},
          {'left': 'avant', 'right': 'mot de temps'},
        ],
        'drawPrompt': 'Dessine Tom qui finit ses devoirs.',
        'drawGuide': 'Ajoute des crayons et un bureau range.',
        'drawTarget': 'T'
      },
      {
        'text':
            'Sara lit une carte pour trouver la bibliotheque pres du parc. Elle tourne a gauche a la boulangerie.',
        'q1': 'Quel outil Sara utilise-t-elle ?',
        'c1': ['une carte', 'une cuillere', 'un jouet'],
        'a1': 0,
        'q2': 'Ou est la bibliotheque ?',
        'c2': ['pres du parc', 'dans la boulangerie', 'pres du lac'],
        'a2': 0,
        'pairs': [
          {'left': 'carte', 'right': 'outil'},
          {'left': 'bibliotheque', 'right': 'lieu'},
          {'left': 'gauche', 'right': 'direction'},
        ],
        'drawPrompt': 'Dessine une petite carte vers la bibliotheque.',
        'drawGuide': 'Ajoute le parc et la boulangerie.',
        'drawTarget': 'M'
      },
      {
        'text':
            'Noe plante des graines. Il les arrose chaque jour et mesure les pousses chaque semaine.',
        'q1': 'Que fait Noe chaque jour ?',
        'c1': ['Il arrose les graines', 'Il les jette', 'Il les cache'],
        'a1': 0,
        'q2': 'Que mesure-t-il chaque semaine ?',
        'c2': ['les pousses', 'les nuages', 'le vent'],
        'a2': 0,
        'pairs': [
          {'left': 'graine', 'right': 'debut de plante'},
          {'left': 'pousse', 'right': 'jeune plante'},
          {'left': 'mesurer', 'right': 'verifier la taille'},
        ],
        'drawPrompt': 'Dessine la graine qui devient pousse.',
        'drawGuide': 'Ajoute des fleches pour montrer le changement.',
        'drawTarget': 'G'
      },
      {
        'text':
            'Mila ecrit une liste: livre, crayon, gomme, bouteille d eau. Elle verifie son sac avant la classe.',
        'q1': 'Pourquoi Mila verifie-t-elle son sac ?',
        'c1': ['Pour etre prete', 'Pour cacher des jouets', 'Pour dormir'],
        'a1': 0,
        'q2': 'Quel objet n est PAS sur sa liste ?',
        'c2': ['ballon', 'livre', 'crayon'],
        'a2': 0,
        'pairs': [
          {'left': 'liste', 'right': 'notes organisees'},
          {'left': 'prete', 'right': 'ready'},
          {'left': 'avant la classe', 'right': 'expression de temps'},
        ],
        'drawPrompt': 'Dessine Mila qui prepare son sac.',
        'drawGuide': 'Ajoute au moins trois objets de la liste.',
        'drawTarget': 'B'
      },
    ];

    final source = isK ? (fr ? kFr : kEn) : (fr ? preFr : preEn);
    final rowIndex = _lessonRowIndex(n, source.length, cycleShift: 1);
    final challenge = _isChallengeLesson(n, source.length);
    final row = source[rowIndex];
    final pairList = (row['pairs'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final firstQuestion = challenge
        ? (fr
            ? 'Defi: Quel mot est un ${pairList[0]['right']} ?'
            : 'Challenge: Which word is a ${pairList[0]['right']}?')
        : row['q1'].toString();
    final firstChoices = challenge
        ? [
            pairList[0]['left']!,
            pairList[1]['left']!,
            pairList[2]['left']!,
          ]
        : (row['c1'] as List).map((e) => e.toString()).toList();
    final firstAnswer = challenge ? 0 : (row['a1'] as num).toInt();
    final secondQuestion = challenge
        ? (fr
            ? 'Defi: Quelle categorie correspond a "${pairList[1]['left']}" ?'
            : 'Challenge: Which category matches "${pairList[1]['left']}"?')
        : row['q2'].toString();
    final secondChoices = challenge
        ? [
            pairList[1]['right']!,
            pairList[0]['right']!,
            pairList[2]['right']!,
          ]
        : (row['c2'] as List).map((e) => e.toString()).toList();
    final secondAnswer = challenge ? 0 : (row['a2'] as num).toInt();
    final rotatedPairs = List.generate(
      pairList.length,
      (idx) => pairList[(idx + (challenge ? 1 : 0)) % pairList.length],
    );

    return [
      LessonStep(kind: 'info', data: {
        'text': challenge
            ? (fr
                ? '${row['text']} Defi: lis et classe le vocabulaire.'
                : '${row['text']} Challenge: read and classify vocabulary.')
            : row['text']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? (challenge
                    ? 'Defi: lis le texte puis cite deux mots importants.'
                    : 'Lis le texte puis resume-le en une phrase.')
                : (challenge
                    ? 'Defi: lis puis nomme un personnage, un lieu et une action.'
                    : 'Lis la phrase et dis ce que tu comprends.'))
            : (isK
                ? (challenge
                    ? 'Challenge: read and name two key words from the text.'
                    : 'Read the text and summarize it in one sentence.')
                : (challenge
                    ? 'Challenge: read and name one character, place, and action.'
                    : 'Read the sentence and say what you understand.')),
        'hint': fr
            ? (isK
                ? 'Utilise qui, quoi, ou et pourquoi.'
                : 'Pense a qui fait l action.')
            : (isK
                ? 'Use who, what, where, and why.'
                : 'Think about who is doing the action.')
      }),
      LessonStep(kind: 'mcq', data: {
        'question': firstQuestion,
        'choices': firstChoices,
        'answerIndex': firstAnswer,
        'hint': fr
            ? 'Relis la phrase qui contient la reponse.'
            : 'Reread the sentence that contains the answer.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': secondQuestion,
        'choices': secondChoices,
        'answerIndex': secondAnswer,
        'hint': fr
            ? 'Cherche les indices de temps ou de lieu.'
            : 'Look for time or place clues.'
      }),
      LessonStep(kind: 'match', data: {
        'instruction':
            fr ? 'Associe mot et categorie.' : 'Match word and category.',
        'pairs': rotatedPairs
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': challenge
            ? (fr
                ? 'Defi dessin: cree une mini BD de cette histoire.'
                : 'Drawing challenge: create a mini comic of this story.')
            : row['drawPrompt'],
        'guide': challenge
            ? (fr
                ? 'Dessine debut, milieu et fin avec labels.'
                : 'Draw beginning, middle, and end with labels.')
            : row['drawGuide'],
        'target': row['drawTarget']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? (challenge
                    ? 'Ecris deux phrases: un fait et une idee importante.'
                    : 'Ecris une phrase sur cette histoire.')
                : (challenge
                    ? 'Ecris deux mots importants de l histoire.'
                    : 'Ecris un mot important de l histoire.'))
            : (isK
                ? (challenge
                    ? 'Type two sentences: one fact and one key idea.'
                    : 'Type one sentence about this story.')
                : (challenge
                    ? 'Type two important words from the story.'
                    : 'Type one important word from the story.')),
        'hint': fr
            ? (isK
                ? 'Commence par: Dans cette histoire...'
                : 'Exemple: chat, ecole, plante.')
            : (isK
                ? 'Start with: In this story...'
                : 'Example: cat, school, plant.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta reponse' : 'Your response',
        'inputHint': fr
            ? (isK ? 'Une phrase complete.' : 'Un mot.')
            : (isK ? 'One complete sentence.' : 'One word.'),
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris ta reponse avant de valider.'
            : 'Type your response before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathWritingSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final preWordsEn = [
      'cat',
      'sun',
      'house',
      'book',
      'flower',
      'tree',
      'kite',
      'apple',
      'rain',
      'music',
    ];
    final preWordsFr = [
      'chat',
      'soleil',
      'maison',
      'livre',
      'fleur',
      'arbre',
      'kite',
      'pomme',
      'pluie',
      'musique',
    ];
    final kStartersEn = [
      'I can',
      'We like',
      'Today',
      'In class',
      'Because',
      'My friend',
      'At home',
      'I feel',
      'We can',
      'First',
    ];
    final kStartersFr = [
      'Je peux',
      'Nous aimons',
      'Aujourd hui',
      'En classe',
      'Parce que',
      'Mon ami',
      'A la maison',
      'Je me sens',
      'Nous pouvons',
      'D abord',
    ];
    final i = _lessonRowIndex(n, preWordsEn.length, cycleShift: 0);
    final word = fr ? preWordsFr[i] : preWordsEn[i];
    final starter = fr ? kStartersFr[i] : kStartersEn[i];
    final firstLetter = word[0].toUpperCase();
    final letterChoices = <String>[firstLetter];
    for (final letter in ['M', 'S', 'A', 'T', 'L']) {
      if (!letterChoices.contains(letter)) {
        letterChoices.add(letter);
      }
      if (letterChoices.length == 3) {
        break;
      }
    }
    final fixedSentence = fr ? 'Je vois un $word.' : 'I see a $word.';
    final wrongCase = fr ? 'je vois un $word.' : 'i see a $word.';
    final wrongPunct = fr ? 'Je vois un $word' : 'I see a $word';

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? 'Lecon $n (K): Ecriture de phrases completes avec majuscule, espaces et point.'
                : 'Lecon $n (Pre-K): Tracer les lettres et ecrire des mots simples.')
            : (isK
                ? 'Lesson $n (K): Write complete sentences with capitals, spaces, and punctuation.'
                : 'Lesson $n (Pre-K): Trace letters and write simple words.')
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Lis ce debut de phrase: "$starter ..."'
                : 'Dis les lettres du mot "$word".')
            : (isK
                ? 'Read this sentence starter: "$starter ..."'
                : 'Say the letters in "$word".'),
        'hint': fr
            ? (isK
                ? 'Commence avec majuscule et termine avec un point.'
                : 'Ecris lentement en suivant les lignes.')
            : (isK
                ? 'Start with a capital and end with punctuation.'
                : 'Write slowly and follow the guide lines.')
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': fr
            ? (isK ? 'Trace ce debut: "$starter ..."' : 'Trace le mot "$word".')
            : (isK
                ? 'Trace this starter: "$starter ..."'
                : 'Trace the word "$word".'),
        'guide': fr
            ? (isK
                ? 'Garde un espace entre les mots.'
                : 'Respecte la taille des lettres.')
            : (isK
                ? 'Keep spaces between words.'
                : 'Keep letter size consistent.'),
        'target': isK ? starter.toUpperCase() : word.toUpperCase()
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? (isK
                ? 'Quelle phrase est ecrite correctement ?'
                : 'Quelle lettre commence "$word" ?')
            : (isK
                ? 'Which sentence is written correctly?'
                : 'Which letter starts "$word"?'),
        'choices': isK
            ? [fixedSentence, wrongCase, wrongPunct]
            : letterChoices,
        'answerIndex': 0,
        'hint': fr
            ? (isK
                ? 'Cherche majuscule et ponctuation.'
                : 'Observe la premiere lettre.')
            : (isK
                ? 'Look for capitalization and punctuation.'
                : 'Look at the first letter.')
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? (isK
                ? 'Quel signe termine souvent une phrase declarative ?'
                : 'Quel mot est ecrit correctement ?')
            : (isK
                ? 'Which mark usually ends a statement sentence?'
                : 'Which word is spelled correctly?'),
        'choices': isK ? ['.', '?', ','] : [word, '${word}x', '${word}z'],
        'answerIndex': 0,
        'hint': fr
            ? (isK
                ? 'La phrase declarative se termine par un point.'
                : 'Choisis le mot sans lettre en plus.')
            : (isK
                ? 'A statement sentence ends with a period.'
                : 'Pick the word without extra letters.')
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? (isK
                ? 'Associe element de phrase et role.'
                : 'Associe majuscule et minuscule.')
            : (isK
                ? 'Match sentence element and role.'
                : 'Match uppercase and lowercase.'),
        'pairs': isK
            ? [
                {'left': fr ? 'Majuscule' : 'Capital letter', 'right': 'A'},
                {'left': fr ? 'Espace' : 'Space', 'right': ' '},
                {'left': fr ? 'Point' : 'Period', 'right': '.'},
              ]
            : [
                {'left': firstLetter, 'right': firstLetter.toLowerCase()},
                {'left': 'A', 'right': 'a'},
                {'left': 'B', 'right': 'b'},
              ]
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Ecris une phrase complete qui commence par "$starter".'
                : 'Ecris un mot ou une phrase avec "$word".')
            : (isK
                ? 'Type a complete sentence that starts with "$starter".'
                : 'Type a word or short sentence with "$word".'),
        'hint': fr
            ? (isK
                ? 'Exemple: $starter je lis un livre.'
                : 'Exemple: Je vois un $word.')
            : (isK
                ? 'Example: $starter I read a book.'
                : 'Example: I see a $word.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ton ecriture' : 'Your writing',
        'inputHint': isK ? '$starter ...' : word,
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une reponse avant de valider.'
            : 'Type a response before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathSelSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final preEn = <Map<String, dynamic>>[
      {
        'q1': 'Your friend falls. What do you do?',
        'c1': ['Help them', 'Laugh', 'Walk away'],
        'a1': 0,
        'q2': 'Which choice shows sharing?',
        'c2': ['Give a toy', 'Hide toys', 'Push'],
        'a2': 0,
        'pairs': [
          {'left': 'sad', 'right': 'comfort'},
          {'left': 'upset', 'right': 'breathe'},
          {'left': 'happy', 'right': 'share'},
        ],
        'drawPrompt': 'Draw two friends helping each other.',
        'drawGuide': 'Show one kind action in the picture.',
        'drawTarget': 'K',
      },
      {
        'q1': 'A friend is sad. You...',
        'c1': ['comfort them', 'ignore them', 'tease them'],
        'a1': 0,
        'q2': 'When someone talks, you...',
        'c2': ['listen', 'interrupt', 'turn away'],
        'a2': 0,
        'pairs': [
          {'left': 'listen', 'right': 'respect'},
          {'left': 'wait turn', 'right': 'self-control'},
          {'left': 'share', 'right': 'kindness'},
        ],
        'drawPrompt': 'Draw children taking turns.',
        'drawGuide': 'Add a speech bubble with kind words.',
        'drawTarget': 'T',
      },
      {
        'q1': 'During a game, what is fair?',
        'c1': ['take turns', 'cheat', 'shove'],
        'a1': 0,
        'q2': 'If you make a mistake, what should you do?',
        'c2': ['say sorry and fix it', 'hide it', 'blame others'],
        'a2': 0,
        'pairs': [
          {'left': 'sorry', 'right': 'repair'},
          {'left': 'thank you', 'right': 'gratitude'},
          {'left': 'please', 'right': 'polite request'},
        ],
        'drawPrompt': 'Draw a fair game.',
        'drawGuide': 'Show one child waiting patiently.',
        'drawTarget': 'F',
      },
      {
        'q1': 'If someone is left out, you should...',
        'c1': ['invite them', 'ignore them', 'laugh'],
        'a1': 0,
        'q2': 'When you feel angry, what helps?',
        'c2': ['take deep breaths', 'yell loudly', 'throw things'],
        'a2': 0,
        'pairs': [
          {'left': 'angry', 'right': 'breathe'},
          {'left': 'worried', 'right': 'ask for help'},
          {'left': 'excited', 'right': 'speak calmly'},
        ],
        'drawPrompt': 'Draw a calm-down corner.',
        'drawGuide': 'Add one tool: breathing, counting, or water.',
        'drawTarget': 'C',
      },
      {
        'q1': 'What helps in teamwork?',
        'c1': ['listen and cooperate', 'control everyone', 'give up'],
        'a1': 0,
        'q2': 'What is a kind classroom rule?',
        'c2': ['use gentle words', 'shout at others', 'grab materials'],
        'a2': 0,
        'pairs': [
          {'left': 'team', 'right': 'cooperate'},
          {'left': 'rule', 'right': 'safety'},
          {'left': 'kind word', 'right': 'respect'},
        ],
        'drawPrompt': 'Draw your class team working together.',
        'drawGuide': 'Show at least two children cooperating.',
        'drawTarget': 'R',
      },
    ];
    final preFr = <Map<String, dynamic>>[
      {
        'q1': 'Ton ami tombe. Que fais-tu ?',
        'c1': ['Je l aide', 'Je ris', 'Je pars'],
        'a1': 0,
        'q2': 'Quel choix montre le partage ?',
        'c2': ['Donner un jouet', 'Cacher les jouets', 'Pousser'],
        'a2': 0,
        'pairs': [
          {'left': 'triste', 'right': 'consoler'},
          {'left': 'fache', 'right': 'respirer'},
          {'left': 'joyeux', 'right': 'partager'},
        ],
        'drawPrompt': 'Dessine deux amis qui s aident.',
        'drawGuide': 'Montre une action gentille.',
        'drawTarget': 'K',
      },
      {
        'q1': 'Un ami est triste. Tu...',
        'c1': ['le consoles', 'l ignores', 'te moques'],
        'a1': 0,
        'q2': 'Quand quelqu un parle, tu...',
        'c2': ['ecoutes', 'coupe la parole', 'tournes le dos'],
        'a2': 0,
        'pairs': [
          {'left': 'ecouter', 'right': 'respect'},
          {'left': 'attendre son tour', 'right': 'controle de soi'},
          {'left': 'partager', 'right': 'gentillesse'},
        ],
        'drawPrompt': 'Dessine des enfants qui attendent leur tour.',
        'drawGuide': 'Ajoute une bulle avec des mots gentils.',
        'drawTarget': 'T',
      },
      {
        'q1': 'Dans un jeu, quel choix est juste ?',
        'c1': ['attendre son tour', 'tricher', 'bousculer'],
        'a1': 0,
        'q2': 'Si tu fais une erreur, que fais-tu ?',
        'c2': ['je m excuse et je corrige', 'je cache', 'j accuse'],
        'a2': 0,
        'pairs': [
          {'left': 'pardon', 'right': 'reparer'},
          {'left': 'merci', 'right': 'gratitude'},
          {'left': 's il te plait', 'right': 'demande polie'},
        ],
        'drawPrompt': 'Dessine un jeu equitable.',
        'drawGuide': 'Montre un enfant qui attend calmement.',
        'drawTarget': 'F',
      },
      {
        'q1': 'Si un enfant est exclu, tu...',
        'c1': ['l invites', 'l ignores', 'ries'],
        'a1': 0,
        'q2': 'Quand tu es en colere, que faire ?',
        'c2': ['respirer profondement', 'crier', 'jeter des objets'],
        'a2': 0,
        'pairs': [
          {'left': 'colere', 'right': 'respirer'},
          {'left': 'inquiet', 'right': 'demander aide'},
          {'left': 'excite', 'right': 'parler calmement'},
        ],
        'drawPrompt': 'Dessine un coin calme.',
        'drawGuide': 'Ajoute un outil: respiration, compter, eau.',
        'drawTarget': 'C',
      },
      {
        'q1': 'Qu est-ce qui aide le travail en equipe ?',
        'c1': ['ecouter et cooperer', 'tout diriger', 'abandonner'],
        'a1': 0,
        'q2': 'Quelle regle de classe est gentille ?',
        'c2': ['utiliser des mots doux', 'crier', 'arracher le materiel'],
        'a2': 0,
        'pairs': [
          {'left': 'equipe', 'right': 'cooperation'},
          {'left': 'regle', 'right': 'securite'},
          {'left': 'mot gentil', 'right': 'respect'},
        ],
        'drawPrompt': 'Dessine ta classe qui travaille ensemble.',
        'drawGuide': 'Montre au moins deux enfants qui cooperent.',
        'drawTarget': 'R',
      },
    ];
    final kEn = <Map<String, dynamic>>[
      {
        'q1': 'A classmate forgot supplies. What should you do?',
        'c1': ['Offer to share', 'Make fun', 'Ignore'],
        'a1': 0,
        'q2': 'You feel upset. What strategy works best?',
        'c2': ['Breathe and use words', 'Yell', 'Push objects'],
        'a2': 0,
        'pairs': [
          {'left': 'frustrated', 'right': 'pause and breathe'},
          {'left': 'conflict', 'right': 'talk and listen'},
          {'left': 'mistake', 'right': 'repair and learn'},
        ],
        'drawPrompt': 'Draw two students solving a problem calmly.',
        'drawGuide': 'Show one calm strategy in action.',
        'drawTarget': 'S',
      },
      {
        'q1': 'A friend is left out of a game. You...',
        'c1': ['Invite them in', 'Laugh with others', 'Walk away'],
        'a1': 0,
        'q2': 'What makes teamwork successful?',
        'c2': [
          'Listening and shared roles',
          'One person controls all',
          'No plan'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'leader', 'right': 'helps everyone participate'},
          {'left': 'listener', 'right': 'shows respect'},
          {'left': 'team', 'right': 'works toward one goal'},
        ],
        'drawPrompt': 'Draw a team activity with shared roles.',
        'drawGuide': 'Label at least two roles.',
        'drawTarget': 'T',
      },
      {
        'q1': 'You made a mistake in class. Best next step?',
        'c1': ['Tell the truth and fix it', 'Hide it', 'Blame someone'],
        'a1': 0,
        'q2': 'Someone disagrees with you. You should...',
        'c2': [
          'Use calm words and listen',
          'Shout louder',
          'Walk away angrily'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'honesty', 'right': 'tell truth'},
          {'left': 'respect', 'right': 'listen first'},
          {'left': 'responsibility', 'right': 'fix actions'},
        ],
        'drawPrompt': 'Draw a repair plan after a mistake.',
        'drawGuide': 'Include step 1 and step 2.',
        'drawTarget': 'R',
      },
      {
        'q1': 'You see unsafe behavior on the playground. You should...',
        'c1': [
          'Get an adult and help safely',
          'Record it and laugh',
          'Ignore it'
        ],
        'a1': 0,
        'q2': 'Which statement is assertive and kind?',
        'c2': [
          'Please stop, that is not safe.',
          'You are bad.',
          'I will hit you.'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'unsafe', 'right': 'seek trusted adult'},
          {'left': 'assertive', 'right': 'clear + respectful words'},
          {'left': 'boundary', 'right': 'protects self and others'},
        ],
        'drawPrompt': 'Draw a safe playground choice.',
        'drawGuide': 'Add one safety rule in words.',
        'drawTarget': 'A',
      },
      {
        'q1': 'What is a growth mindset sentence?',
        'c1': [
          'I can improve with practice',
          'I can never do this',
          'I quit now'
        ],
        'a1': 0,
        'q2': 'How can you show empathy?',
        'c2': [
          'Ask how someone feels and help',
          'Ignore feelings',
          'Mock others'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'goal', 'right': 'small next step'},
          {'left': 'practice', 'right': 'improvement'},
          {'left': 'empathy', 'right': 'understand feelings'},
        ],
        'drawPrompt': 'Draw yourself reaching a learning goal.',
        'drawGuide': 'Write one encouraging sentence.',
        'drawTarget': 'G',
      },
    ];
    final kFr = <Map<String, dynamic>>[
      {
        'q1': 'Un camarade oublie son materiel. Que fais-tu ?',
        'c1': ['Je propose de partager', 'Je me moque', 'J ignore'],
        'a1': 0,
        'q2': 'Tu es fache. Quelle strategie aide le plus ?',
        'c2': ['Respirer et parler calmement', 'Crier', 'Jeter des objets'],
        'a2': 0,
        'pairs': [
          {'left': 'frustre', 'right': 'pause et respiration'},
          {'left': 'conflit', 'right': 'parler et ecouter'},
          {'left': 'erreur', 'right': 'reparer et apprendre'},
        ],
        'drawPrompt': 'Dessine deux eleves qui resolvent un conflit calmement.',
        'drawGuide': 'Montre une strategie calme.',
        'drawTarget': 'S',
      },
      {
        'q1': 'Un ami est exclu d un jeu. Tu...',
        'c1': ['L invites a participer', 'Ries avec les autres', 'Pars'],
        'a1': 0,
        'q2': 'Qu est-ce qui aide une equipe a reussir ?',
        'c2': [
          'Ecoute et roles partages',
          'Une seule personne commande',
          'Pas de plan'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'leader', 'right': 'fait participer tout le monde'},
          {'left': 'ecoute', 'right': 'montre respect'},
          {'left': 'equipe', 'right': 'meme objectif'},
        ],
        'drawPrompt': 'Dessine une activite d equipe avec des roles.',
        'drawGuide': 'Nomme au moins deux roles.',
        'drawTarget': 'T',
      },
      {
        'q1': 'Tu as fait une erreur en classe. Que faire ?',
        'c1': ['Dire la verite et corriger', 'Cacher', 'Accuser un autre'],
        'a1': 0,
        'q2': 'Quelqu un n est pas d accord avec toi. Tu...',
        'c2': ['Parles calmement et ecoutes', 'Cries plus fort', 'Pars fache'],
        'a2': 0,
        'pairs': [
          {'left': 'honnetete', 'right': 'dire la verite'},
          {'left': 'respect', 'right': 'ecouter d abord'},
          {'left': 'responsabilite', 'right': 'corriger ses actes'},
        ],
        'drawPrompt': 'Dessine un plan pour reparer une erreur.',
        'drawGuide': 'Ajoute etape 1 et etape 2.',
        'drawTarget': 'R',
      },
      {
        'q1': 'Tu vois un comportement dangereux. Tu...',
        'c1': ['Previens un adulte et aides en securite', 'Ries', 'Ignores'],
        'a1': 0,
        'q2': 'Quelle phrase est assertive et gentille ?',
        'c2': [
          'S il te plait, arrete, ce n est pas securise.',
          'Tu es nul.',
          'Je vais te frapper.'
        ],
        'a2': 0,
        'pairs': [
          {'left': 'dangereux', 'right': 'chercher adulte de confiance'},
          {'left': 'assertif', 'right': 'clair et respectueux'},
          {'left': 'limite', 'right': 'proteger soi et autres'},
        ],
        'drawPrompt': 'Dessine un choix securitaire a la recreation.',
        'drawGuide': 'Ajoute une regle de securite.',
        'drawTarget': 'A',
      },
      {
        'q1': 'Quelle phrase montre un etat d esprit de progression ?',
        'c1': [
          'Je peux m ameliorer avec la pratique',
          'Je n y arriverai jamais',
          'J abandonne'
        ],
        'a1': 0,
        'q2': 'Comment montrer de l empathie ?',
        'c2': ['Demander comment la personne se sent', 'Ignorer', 'Se moquer'],
        'a2': 0,
        'pairs': [
          {'left': 'objectif', 'right': 'petite etape suivante'},
          {'left': 'pratique', 'right': 'amelioration'},
          {'left': 'empathie', 'right': 'comprendre les sentiments'},
        ],
        'drawPrompt': 'Dessine-toi en train d atteindre un objectif.',
        'drawGuide': 'Ecris une phrase d encouragement.',
        'drawTarget': 'G',
      },
    ];

    final source = isK ? (fr ? kFr : kEn) : (fr ? preFr : preEn);
    final rowIndex = _lessonRowIndex(n, source.length, cycleShift: 1);
    final challenge = _isChallengeLesson(n, source.length);
    final row = source[rowIndex];
    final pairList = (row['pairs'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final firstQuestion = challenge
        ? (fr
            ? 'Defi: Quelle action correspond a "${pairList[0]['left']}" ?'
            : 'Challenge: Which action matches "${pairList[0]['left']}"?')
        : row['q1'].toString();
    final firstChoices = challenge
        ? [
            pairList[0]['right']!,
            pairList[1]['right']!,
            pairList[2]['right']!,
          ]
        : (row['c1'] as List).map((e) => e.toString()).toList();
    final firstAnswer = challenge ? 0 : (row['a1'] as num).toInt();
    final secondQuestion = challenge
        ? (fr
            ? 'Defi: Quel mot correspond a "${pairList[2]['right']}" ?'
            : 'Challenge: Which word matches "${pairList[2]['right']}"?')
        : row['q2'].toString();
    final secondChoices = challenge
        ? [
            pairList[2]['left']!,
            pairList[1]['left']!,
            pairList[0]['left']!,
          ]
        : (row['c2'] as List).map((e) => e.toString()).toList();
    final secondAnswer = challenge ? 0 : (row['a2'] as num).toInt();
    final rotatedPairs = List.generate(
      pairList.length,
      (idx) => pairList[(idx + (challenge ? 1 : 0)) % pairList.length],
    );

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? (challenge
                    ? 'Lecon $n (K): Defi SEL sur empathie, responsabilite et cooperation.'
                    : 'Lecon $n (K): Empathie, responsabilite, cooperation et gestion des emotions.')
                : (challenge
                    ? 'Lecon $n (Pre-K): Defi choix gentils et mots utiles.'
                    : 'Lecon $n (Pre-K): Les choix gentils aident tout le monde.'))
            : (isK
                ? (challenge
                    ? 'Lesson $n (K): SEL challenge for empathy, responsibility, and teamwork.'
                    : 'Lesson $n (K): Empathy, responsibility, cooperation, and emotion management.')
                : (challenge
                    ? 'Lesson $n (Pre-K): Kind-choice challenge with social words.'
                    : 'Lesson $n (Pre-K): Kind choices help everyone.'))
      }),
      LessonStep(kind: 'mcq', data: {
        'question': firstQuestion,
        'choices': firstChoices,
        'answerIndex': firstAnswer,
        'hint': fr
            ? 'Choisis la reponse la plus respectueuse.'
            : 'Pick the most respectful response.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': secondQuestion,
        'choices': secondChoices,
        'answerIndex': secondAnswer,
        'hint': fr
            ? 'Pense a la securite et a la gentillesse.'
            : 'Think about safety and kindness.'
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe emotion ou mot et action utile.'
            : 'Match each feeling/word and helpful action.',
        'pairs': rotatedPairs
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': challenge
            ? (fr
                ? 'Defi dessin: montre une situation et une solution gentille.'
                : 'Drawing challenge: show a problem and a kind solution.')
            : row['drawPrompt'],
        'guide': challenge
            ? (fr
                ? 'Ajoute une bulle de dialogue respectueuse.'
                : 'Add one respectful speech bubble.')
            : row['drawGuide'],
        'target': row['drawTarget']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? (challenge
                    ? 'Ecris deux phrases: comprendre puis aider.'
                    : 'Ecris une phrase pour aider un ami dans une situation difficile.')
                : (challenge
                    ? 'Dis ou ecris deux mots gentils pour un ami.'
                    : 'Dis ou ecris une phrase gentille pour un ami.'))
            : (isK
                ? (challenge
                    ? 'Type two sentences: understand first, then help.'
                    : 'Type one sentence to help a friend in a hard moment.')
                : (challenge
                    ? 'Say or type two kind words for a friend.'
                    : 'Say or type one kind sentence to a friend.')),
        'hint': fr
            ? 'Exemple: Je peux t aider et rester avec toi.'
            : 'Example: I can help you and stay with you.',
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta phrase' : 'Your sentence',
        'inputHint': fr ? 'Une phrase gentille.' : 'One kind sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une phrase avant de valider.'
            : 'Type a sentence before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathScienceSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final topicsPreEn = <Map<String, dynamic>>[
      {
        'info':
            'Living things around us can be animals or plants. Colors help us describe them.',
        'q1': 'Which color is a banana usually?',
        'c1': ['yellow', 'blue', 'gray'],
        'a1': 0,
        'q2': 'Where does a fish live?',
        'c2': ['water', 'tree', 'nest'],
        'a2': 0,
        'pairs1': [
          {'left': 'cow', 'right': 'farm'},
          {'left': 'fish', 'right': 'water'},
          {'left': 'bird', 'right': 'nest'},
        ],
        'pairs2': [
          {'left': 'red', 'right': 'apple'},
          {'left': 'blue', 'right': 'sky'},
          {'left': 'green', 'right': 'grass'},
        ],
        'drawPrompt': 'Draw your favorite animal.',
        'drawGuide': 'Color it and say its color.',
        'drawTarget': 'A',
        'prompt': 'Name one animal and one color you can see today.',
        'hint': 'Example: black dog, green tree.'
      },
      {
        'info': 'Farm animals need food, water, and a safe place to live.',
        'q1': 'Which animal gives milk?',
        'c1': ['cow', 'lion', 'snake'],
        'a1': 0,
        'q2': 'Which animal hatches from an egg?',
        'c2': ['chicken', 'cat', 'goat'],
        'a2': 0,
        'pairs1': [
          {'left': 'duck', 'right': 'pond'},
          {'left': 'horse', 'right': 'stable'},
          {'left': 'sheep', 'right': 'field'},
        ],
        'pairs2': [
          {'left': 'brown', 'right': 'soil'},
          {'left': 'white', 'right': 'cloud'},
          {'left': 'orange', 'right': 'carrot'},
        ],
        'drawPrompt': 'Draw a farm animal.',
        'drawGuide': 'Add the place where it lives.',
        'drawTarget': 'F',
        'prompt': 'Tell one thing farm animals need every day.',
        'hint': 'Think about food, water, and shelter.'
      },
      {
        'info':
            'Wild animals live in different habitats like jungle, savanna, and forest.',
        'q1': 'Which animal often lives in the jungle?',
        'c1': ['monkey', 'cow', 'duck'],
        'a1': 0,
        'q2': 'Which animal has black and white stripes?',
        'c2': ['zebra', 'frog', 'snail'],
        'a2': 0,
        'pairs1': [
          {'left': 'lion', 'right': 'savanna'},
          {'left': 'polar bear', 'right': 'ice'},
          {'left': 'monkey', 'right': 'jungle'},
        ],
        'pairs2': [
          {'left': 'gray', 'right': 'elephant'},
          {'left': 'pink', 'right': 'flamingo'},
          {'left': 'gold', 'right': 'sun'},
        ],
        'drawPrompt': 'Draw one wild animal and its home.',
        'drawGuide': 'Name the habitat.',
        'drawTarget': 'W',
        'prompt': 'Name two wild animals you know.',
        'hint': 'Example: lion, zebra.'
      },
      {
        'info':
            'Animals and people use body parts and senses to survive and explore.',
        'q1': 'Which body part helps us smell?',
        'c1': ['nose', 'knee', 'elbow'],
        'a1': 0,
        'q2': 'What helps a bird fly?',
        'c2': ['wings', 'fins', 'hooves'],
        'a2': 0,
        'pairs1': [
          {'left': 'eyes', 'right': 'see'},
          {'left': 'ears', 'right': 'hear'},
          {'left': 'nose', 'right': 'smell'},
        ],
        'pairs2': [
          {'left': 'purple', 'right': 'grape'},
          {'left': 'black', 'right': 'night'},
          {'left': 'yellow', 'right': 'sunflower'},
        ],
        'drawPrompt': 'Draw an animal and label one body part.',
        'drawGuide': 'Say what that part does.',
        'drawTarget': 'B',
        'prompt': 'Say one sense you used today.',
        'hint': 'See, hear, smell, taste, touch.'
      },
      {
        'info':
            'Weather changes every day. Animals adapt to hot, cold, wet, or dry places.',
        'q1': 'Which weather gives us rain?',
        'c1': ['clouds', 'rocks', 'sand'],
        'a1': 0,
        'q2': 'On a hot day, where might a dog rest?',
        'c2': ['in the shade', 'inside a freezer', 'on a fire'],
        'a2': 0,
        'pairs1': [
          {'left': 'rainy', 'right': 'umbrella'},
          {'left': 'sunny', 'right': 'hat'},
          {'left': 'cold', 'right': 'coat'},
        ],
        'pairs2': [
          {'left': 'blue', 'right': 'raincoat'},
          {'left': 'gray', 'right': 'storm cloud'},
          {'left': 'green', 'right': 'spring leaves'},
        ],
        'drawPrompt': 'Draw today weather and one animal.',
        'drawGuide': 'Describe how the animal stays safe.',
        'drawTarget': 'S',
        'prompt': 'Describe today weather in one short sentence.',
        'hint': 'Example: Today is sunny and warm.'
      },
    ];
    final topicsPreFr = <Map<String, dynamic>>[
      {
        'info':
            'Les etres vivants autour de nous sont des animaux ou des plantes. Les couleurs aident a les decrire.',
        'q1': 'Quelle couleur a souvent une banane ?',
        'c1': ['jaune', 'bleu', 'gris'],
        'a1': 0,
        'q2': 'Ou vit un poisson ?',
        'c2': ['eau', 'arbre', 'nid'],
        'a2': 0,
        'pairs1': [
          {'left': 'vache', 'right': 'ferme'},
          {'left': 'poisson', 'right': 'eau'},
          {'left': 'oiseau', 'right': 'nid'},
        ],
        'pairs2': [
          {'left': 'rouge', 'right': 'pomme'},
          {'left': 'bleu', 'right': 'ciel'},
          {'left': 'vert', 'right': 'herbe'},
        ],
        'drawPrompt': 'Dessine ton animal prefere.',
        'drawGuide': 'Colorie-le et dis sa couleur.',
        'drawTarget': 'A',
        'prompt': 'Nomme un animal et une couleur que tu vois aujourd hui.',
        'hint': 'Exemple: chien noir, arbre vert.'
      },
      {
        'info':
            'Les animaux de la ferme ont besoin de nourriture, d eau et d un abri.',
        'q1': 'Quel animal donne du lait ?',
        'c1': ['vache', 'lion', 'serpent'],
        'a1': 0,
        'q2': 'Quel animal sort d un oeuf ?',
        'c2': ['poule', 'chat', 'chevre'],
        'a2': 0,
        'pairs1': [
          {'left': 'canard', 'right': 'mare'},
          {'left': 'cheval', 'right': 'ecurie'},
          {'left': 'mouton', 'right': 'champ'},
        ],
        'pairs2': [
          {'left': 'marron', 'right': 'sol'},
          {'left': 'blanc', 'right': 'nuage'},
          {'left': 'orange', 'right': 'carotte'},
        ],
        'drawPrompt': 'Dessine un animal de la ferme.',
        'drawGuide': 'Ajoute l endroit ou il vit.',
        'drawTarget': 'F',
        'prompt': 'Dis une chose dont les animaux de la ferme ont besoin.',
        'hint': 'Pense a nourriture, eau, abri.'
      },
      {
        'info':
            'Les animaux sauvages vivent dans des habitats differents: jungle, savane, foret.',
        'q1': 'Quel animal vit souvent dans la jungle ?',
        'c1': ['singe', 'vache', 'canard'],
        'a1': 0,
        'q2': 'Quel animal a des rayures noires et blanches ?',
        'c2': ['zebre', 'grenouille', 'escargot'],
        'a2': 0,
        'pairs1': [
          {'left': 'lion', 'right': 'savane'},
          {'left': 'ours polaire', 'right': 'glace'},
          {'left': 'singe', 'right': 'jungle'},
        ],
        'pairs2': [
          {'left': 'gris', 'right': 'elephant'},
          {'left': 'rose', 'right': 'flamant'},
          {'left': 'dore', 'right': 'soleil'},
        ],
        'drawPrompt': 'Dessine un animal sauvage et son habitat.',
        'drawGuide': 'Nomme cet habitat.',
        'drawTarget': 'W',
        'prompt': 'Nomme deux animaux sauvages.',
        'hint': 'Exemple: lion, zebre.'
      },
      {
        'info':
            'Les animaux et les humains utilisent leurs parties du corps et leurs sens.',
        'q1': 'Quelle partie du corps sert a sentir les odeurs ?',
        'c1': ['nez', 'genou', 'coude'],
        'a1': 0,
        'q2': 'Qu est-ce qui aide un oiseau a voler ?',
        'c2': ['ailes', 'nageoires', 'sabots'],
        'a2': 0,
        'pairs1': [
          {'left': 'yeux', 'right': 'voir'},
          {'left': 'oreilles', 'right': 'entendre'},
          {'left': 'nez', 'right': 'sentir'},
        ],
        'pairs2': [
          {'left': 'violet', 'right': 'raisin'},
          {'left': 'noir', 'right': 'nuit'},
          {'left': 'jaune', 'right': 'tournesol'},
        ],
        'drawPrompt': 'Dessine un animal et nomme une partie du corps.',
        'drawGuide': 'Dis ce que cette partie fait.',
        'drawTarget': 'B',
        'prompt': 'Dis un sens que tu as utilise aujourd hui.',
        'hint': 'Voir, entendre, sentir, gouter, toucher.'
      },
      {
        'info':
            'La meteo change chaque jour. Les animaux s adaptent au chaud, au froid et a la pluie.',
        'q1': 'Quelle meteo apporte la pluie ?',
        'c1': ['nuages', 'rochers', 'sable'],
        'a1': 0,
        'q2': 'Quand il fait chaud, ou un chien peut-il se reposer ?',
        'c2': ['a l ombre', 'dans le feu', 'dans un congelateur'],
        'a2': 0,
        'pairs1': [
          {'left': 'pluvieux', 'right': 'parapluie'},
          {'left': 'ensoleille', 'right': 'chapeau'},
          {'left': 'froid', 'right': 'manteau'},
        ],
        'pairs2': [
          {'left': 'bleu', 'right': 'impermable'},
          {'left': 'gris', 'right': 'nuage de pluie'},
          {'left': 'vert', 'right': 'feuilles du printemps'},
        ],
        'drawPrompt': 'Dessine la meteo du jour et un animal.',
        'drawGuide': 'Explique comment l animal se protege.',
        'drawTarget': 'S',
        'prompt': 'Decris la meteo du jour en une phrase courte.',
        'hint': 'Exemple: Aujourd hui il fait chaud et ensoleille.'
      },
    ];
    final topicsKEn = <Map<String, dynamic>>[
      {
        'info':
            'Animals can be grouped as mammals, birds, reptiles, fish, and amphibians.',
        'q1': 'Which animal is a mammal?',
        'c1': ['dolphin', 'shark', 'frog'],
        'a1': 0,
        'q2': 'Which group has feathers?',
        'c2': ['birds', 'reptiles', 'fish'],
        'a2': 0,
        'q3': 'Which animal is a reptile?',
        'c3': ['lizard', 'whale', 'eagle'],
        'a3': 0,
        'pairs1': [
          {'left': 'mammal', 'right': 'cat'},
          {'left': 'bird', 'right': 'owl'},
          {'left': 'reptile', 'right': 'snake'},
        ],
        'pairs2': [
          {'left': 'forest', 'right': 'deer'},
          {'left': 'ocean', 'right': 'dolphin'},
          {'left': 'desert', 'right': 'camel'},
        ],
        'drawPrompt': 'Draw one animal and label its group.',
        'drawGuide': 'Write mammal, bird, reptile, fish, or amphibian.',
        'drawTarget': 'C',
        'prompt': 'Explain one way mammals are different from birds.',
        'hint': 'Think about hair, feathers, and how babies are born.'
      },
      {
        'info': 'Life cycles describe how living things change as they grow.',
        'q1': 'What is the first stage of a butterfly life cycle?',
        'c1': ['egg', 'caterpillar', 'butterfly'],
        'a1': 0,
        'q2': 'A tadpole grows into a...',
        'c2': ['frog', 'fish', 'duck'],
        'a2': 0,
        'q3': 'What does a seed need to sprout?',
        'c3': ['water', 'plastic', 'metal'],
        'a3': 0,
        'pairs1': [
          {'left': 'egg', 'right': 'caterpillar'},
          {'left': 'caterpillar', 'right': 'chrysalis'},
          {'left': 'chrysalis', 'right': 'butterfly'},
        ],
        'pairs2': [
          {'left': 'white', 'right': 'egg'},
          {'left': 'green', 'right': 'leaf'},
          {'left': 'brown', 'right': 'seed'},
        ],
        'drawPrompt': 'Draw a simple life cycle with arrows.',
        'drawGuide': 'Use at least three stages.',
        'drawTarget': 'L',
        'prompt': 'Name one life cycle stage and describe it.',
        'hint': 'Example: egg is the first stage.'
      },
      {
        'info': 'Food chains show how energy moves from plants to animals.',
        'q1': 'What is usually the first part of a food chain?',
        'c1': ['plant', 'lion', 'rock'],
        'a1': 0,
        'q2': 'Which animal can be a prey animal?',
        'c2': ['rabbit', 'oak tree', 'cloud'],
        'a2': 0,
        'q3': 'Which habitat has very little water?',
        'c3': ['desert', 'pond', 'rainforest'],
        'a3': 0,
        'pairs1': [
          {'left': 'grass', 'right': 'rabbit'},
          {'left': 'rabbit', 'right': 'fox'},
          {'left': 'algae', 'right': 'fish'},
        ],
        'pairs2': [
          {'left': 'green', 'right': 'producer'},
          {'left': 'gray', 'right': 'wolf'},
          {'left': 'blue', 'right': 'pond'},
        ],
        'drawPrompt': 'Draw a food chain with three links.',
        'drawGuide': 'Add arrows to show energy flow.',
        'drawTarget': 'F',
        'prompt': 'Explain why plants are important in food chains.',
        'hint': 'Most chains start with plants.'
      },
      {
        'info':
            'Plants have roots, stems, leaves, flowers, and seeds. Each part has a job.',
        'q1': 'Which plant part takes in water from soil?',
        'c1': ['roots', 'petals', 'fruit'],
        'a1': 0,
        'q2': 'Which part helps make food using sunlight?',
        'c2': ['leaves', 'roots', 'soil'],
        'a2': 0,
        'q3': 'What do seeds become when conditions are right?',
        'c3': ['new plants', 'rocks', 'clouds'],
        'a3': 0,
        'pairs1': [
          {'left': 'roots', 'right': 'absorb water'},
          {'left': 'stem', 'right': 'supports plant'},
          {'left': 'flower', 'right': 'makes seeds'},
        ],
        'pairs2': [
          {'left': 'green', 'right': 'leaf'},
          {'left': 'brown', 'right': 'soil'},
          {'left': 'yellow', 'right': 'petal'},
        ],
        'drawPrompt': 'Draw a plant and label three parts.',
        'drawGuide': 'Use arrows to show part names.',
        'drawTarget': 'P',
        'prompt': 'Tell how one plant part helps the whole plant.',
        'hint': 'Example: roots absorb water.'
      },
      {
        'info':
            'Weather patterns include temperature, wind, and rain. Animals adapt to survive.',
        'q1': 'What tool measures temperature?',
        'c1': ['thermometer', 'ruler', 'scale'],
        'a1': 0,
        'q2': 'Why do many animals grow thicker fur in cold seasons?',
        'c2': ['to stay warm', 'to fly faster', 'to change color for fun'],
        'a2': 0,
        'q3': 'Which season is often the coldest?',
        'c3': ['winter', 'summer', 'spring'],
        'a3': 0,
        'pairs1': [
          {'left': 'winter', 'right': 'thick fur'},
          {'left': 'summer', 'right': 'seek shade'},
          {'left': 'rainy day', 'right': 'find shelter'},
        ],
        'pairs2': [
          {'left': 'gray', 'right': 'storm cloud'},
          {'left': 'white', 'right': 'snow'},
          {'left': 'gold', 'right': 'sunlight'},
        ],
        'drawPrompt': 'Draw one weather condition and one adapting animal.',
        'drawGuide': 'Label both the weather and the adaptation.',
        'drawTarget': 'W',
        'prompt': 'Describe one animal adaptation to weather.',
        'hint': 'Example: a camel stores water for dry places.'
      },
    ];
    final topicsKFr = <Map<String, dynamic>>[
      {
        'info':
            'Les animaux se classent en mammiferes, oiseaux, reptiles, poissons et amphibiens.',
        'q1': 'Quel animal est un mammifere ?',
        'c1': ['dauphin', 'requin', 'grenouille'],
        'a1': 0,
        'q2': 'Quel groupe a des plumes ?',
        'c2': ['oiseaux', 'reptiles', 'poissons'],
        'a2': 0,
        'q3': 'Quel animal est un reptile ?',
        'c3': ['lezard', 'baleine', 'aigle'],
        'a3': 0,
        'pairs1': [
          {'left': 'mammifere', 'right': 'chat'},
          {'left': 'oiseau', 'right': 'hibou'},
          {'left': 'reptile', 'right': 'serpent'},
        ],
        'pairs2': [
          {'left': 'foret', 'right': 'cerf'},
          {'left': 'ocean', 'right': 'dauphin'},
          {'left': 'desert', 'right': 'chameau'},
        ],
        'drawPrompt': 'Dessine un animal et ecris son groupe.',
        'drawGuide': 'Ecris: mammifere, oiseau, reptile, poisson ou amphibien.',
        'drawTarget': 'C',
        'prompt': 'Explique une difference entre mammiferes et oiseaux.',
        'hint': 'Pense aux poils, aux plumes et a la naissance.'
      },
      {
        'info':
            'Le cycle de vie montre comment les etres vivants changent en grandissant.',
        'q1': 'Quelle est la premiere etape du papillon ?',
        'c1': ['oeuf', 'chenille', 'papillon'],
        'a1': 0,
        'q2': 'Un tetard devient une...',
        'c2': ['grenouille', 'truite', 'poule'],
        'a2': 0,
        'q3': 'De quoi une graine a-t-elle besoin pour germer ?',
        'c3': ['eau', 'plastique', 'metal'],
        'a3': 0,
        'pairs1': [
          {'left': 'oeuf', 'right': 'chenille'},
          {'left': 'chenille', 'right': 'chrysalide'},
          {'left': 'chrysalide', 'right': 'papillon'},
        ],
        'pairs2': [
          {'left': 'blanc', 'right': 'oeuf'},
          {'left': 'vert', 'right': 'feuille'},
          {'left': 'marron', 'right': 'graine'},
        ],
        'drawPrompt': 'Dessine un cycle de vie simple avec des fleches.',
        'drawGuide': 'Montre au moins trois etapes.',
        'drawTarget': 'L',
        'prompt': 'Nomme une etape du cycle de vie et decris-la.',
        'hint': 'Exemple: l oeuf est la premiere etape.'
      },
      {
        'info':
            'Les chaines alimentaires montrent le passage de l energie des plantes aux animaux.',
        'q1': 'Quelle est souvent la premiere partie d une chaine ?',
        'c1': ['plante', 'lion', 'rocher'],
        'a1': 0,
        'q2': 'Quel animal peut etre une proie ?',
        'c2': ['lapin', 'chene', 'nuage'],
        'a2': 0,
        'q3': 'Quel habitat a tres peu d eau ?',
        'c3': ['desert', 'mare', 'foret tropicale'],
        'a3': 0,
        'pairs1': [
          {'left': 'herbe', 'right': 'lapin'},
          {'left': 'lapin', 'right': 'renard'},
          {'left': 'algue', 'right': 'poisson'},
        ],
        'pairs2': [
          {'left': 'vert', 'right': 'producteur'},
          {'left': 'gris', 'right': 'loup'},
          {'left': 'bleu', 'right': 'mare'},
        ],
        'drawPrompt': 'Dessine une chaine alimentaire avec trois maillons.',
        'drawGuide': 'Ajoute des fleches pour montrer le sens.',
        'drawTarget': 'F',
        'prompt': 'Explique pourquoi les plantes sont importantes.',
        'hint': 'La plupart des chaines commencent par des plantes.'
      },
      {
        'info':
            'Les plantes ont des racines, tiges, feuilles, fleurs et graines. Chaque partie a un role.',
        'q1': 'Quelle partie prend l eau du sol ?',
        'c1': ['racines', 'petales', 'fruit'],
        'a1': 0,
        'q2': 'Quelle partie fabrique la nourriture avec la lumiere ?',
        'c2': ['feuilles', 'racines', 'sol'],
        'a2': 0,
        'q3': 'Que deviennent les graines dans de bonnes conditions ?',
        'c3': ['nouvelles plantes', 'rochers', 'nuages'],
        'a3': 0,
        'pairs1': [
          {'left': 'racines', 'right': 'absorber eau'},
          {'left': 'tige', 'right': 'soutenir plante'},
          {'left': 'fleur', 'right': 'former graines'},
        ],
        'pairs2': [
          {'left': 'vert', 'right': 'feuille'},
          {'left': 'marron', 'right': 'sol'},
          {'left': 'jaune', 'right': 'petale'},
        ],
        'drawPrompt': 'Dessine une plante et nomme trois parties.',
        'drawGuide': 'Utilise des fleches pour relier les noms.',
        'drawTarget': 'P',
        'prompt': 'Dis comment une partie aide toute la plante.',
        'hint': 'Exemple: les racines absorbent l eau.'
      },
      {
        'info':
            'La meteo inclut temperature, vent et pluie. Les animaux s adaptent pour survivre.',
        'q1': 'Quel outil mesure la temperature ?',
        'c1': ['thermometre', 'regle', 'balance'],
        'a1': 0,
        'q2': 'Pourquoi beaucoup d animaux ont un pelage plus epais en hiver ?',
        'c2': [
          'pour rester au chaud',
          'pour voler plus vite',
          'pour changer de couleur'
        ],
        'a2': 0,
        'q3': 'Quelle saison est souvent la plus froide ?',
        'c3': ['hiver', 'ete', 'printemps'],
        'a3': 0,
        'pairs1': [
          {'left': 'hiver', 'right': 'pelage epais'},
          {'left': 'ete', 'right': 'chercher ombre'},
          {'left': 'jour de pluie', 'right': 'chercher abri'},
        ],
        'pairs2': [
          {'left': 'gris', 'right': 'nuage d orage'},
          {'left': 'blanc', 'right': 'neige'},
          {'left': 'dore', 'right': 'soleil'},
        ],
        'drawPrompt': 'Dessine une meteo et un animal adapte.',
        'drawGuide': 'Ecris la meteo et l adaptation.',
        'drawTarget': 'W',
        'prompt': 'Decris une adaptation animale a la meteo.',
        'hint': 'Exemple: le chameau stocke de l eau dans le desert.'
      },
    ];

    final topics =
        isK ? (fr ? topicsKFr : topicsKEn) : (fr ? topicsPreFr : topicsPreEn);
    final topicIndex = _lessonRowIndex(n, topics.length, cycleShift: 1);
    final challenge = _isChallengeLesson(n, topics.length);
    final topic = topics[topicIndex];
    final pairs1 = (topic['pairs1'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final pairs2 = (topic['pairs2'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final choices1 = challenge
        ? [pairs1[0]['right']!, pairs1[1]['right']!, pairs1[2]['right']!]
        : (topic['c1'] as List).map((e) => e.toString()).toList();
    final question1 = challenge
        ? (fr
            ? 'Defi: Quel element correspond a "${pairs1[0]['left']}" ?'
            : 'Challenge: Which item matches "${pairs1[0]['left']}"?')
        : topic['q1'].toString();
    final answer1 = challenge ? 0 : (topic['a1'] as num).toInt();
    final choices2 = challenge
        ? [pairs2[1]['left']!, pairs2[0]['left']!, pairs2[2]['left']!]
        : (topic['c2'] as List).map((e) => e.toString()).toList();
    final question2 = challenge
        ? (fr
            ? 'Defi: Quelle couleur va avec "${pairs2[1]['right']}" ?'
            : 'Challenge: Which color matches "${pairs2[1]['right']}"?')
        : topic['q2'].toString();
    final answer2 = challenge ? 0 : (topic['a2'] as num).toInt();
    final rotatedPairs1 = List.generate(
      pairs1.length,
      (idx) => pairs1[(idx + (challenge ? 1 : 0)) % pairs1.length],
    );
    final rotatedPairs2 = List.generate(
      pairs2.length,
      (idx) => pairs2[(idx + (challenge ? 1 : 0)) % pairs2.length],
    );

    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': challenge
            ? (fr
                ? '${topic['info']} Defi: observe et classe les indices.'
                : '${topic['info']} Challenge: observe and classify clues.')
            : topic['info']
      }),
      LessonStep(kind: 'mcq', data: {
        'question': question1,
        'choices': choices1,
        'answerIndex': answer1,
        'hint': fr
            ? 'Repense au fait principal de la lecon.'
            : 'Think back to the main science fact.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': question2,
        'choices': choices2,
        'answerIndex': answer2,
        'hint': fr
            ? 'Observe les indices dans la nature.'
            : 'Look for clues from nature.'
      }),
    ];

    if (topic['q3'] != null) {
      final choices3 = challenge
          ? [pairs1[2]['left']!, pairs1[0]['left']!, pairs1[1]['left']!]
          : (topic['c3'] as List).map((e) => e.toString()).toList();
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': challenge
              ? (fr
                  ? 'Defi: Quel mot complete cette paire "${pairs1[2]['right']}" ?'
                  : 'Challenge: Which word completes this pair "${pairs1[2]['right']}"?')
              : topic['q3'],
          'choices': choices3,
          'answerIndex': challenge ? 0 : (topic['a3'] as num).toInt(),
          'hint': fr
              ? 'Utilise le vocabulaire scientifique de la lecon.'
              : 'Use the science vocabulary from this lesson.'
        }),
      );
    }

    steps.addAll([
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe correctement chaque paire.'
            : 'Match each pair correctly.',
        'pairs': rotatedPairs1
      }),
      LessonStep(kind: 'match', data: {
        'instruction':
            fr ? 'Associe couleur et exemple.' : 'Match color and example.',
        'pairs': rotatedPairs2
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': challenge
            ? (fr
                ? 'Defi dessin: realise une scene scientifique et ajoute trois labels.'
                : 'Drawing challenge: make a science scene and add three labels.')
            : topic['drawPrompt'],
        'guide': challenge
            ? (fr
                ? 'Montre cause, effet et exemple.'
                : 'Show cause, effect, and one example.')
            : topic['drawGuide'],
        'target': topic['drawTarget']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': challenge
            ? (fr
                ? 'Ecris deux phrases scientifiques de cette lecon.'
                : 'Write two science sentences from this lesson.')
            : topic['prompt'],
        'hint': challenge
            ? (fr
                ? 'Utilise au moins un mot des paires.'
                : 'Use at least one word from the match pairs.')
            : topic['hint'],
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta reponse' : 'Your answer',
        'inputHint':
            fr ? 'Ecris une phrase courte.' : 'Write one short sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris ta reponse avant de valider.'
            : 'Type your answer before submitting.'
      }),
    ]);

    return steps;
  }

  List<LessonStep> _pathMeasureSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final preEn = <Map<String, dynamic>>[
      {
        'q1': 'What do you measure with a ruler?',
        'c1': ['length', 'smell', 'taste'],
        'a1': 0,
        'q2': 'Which object is usually longer?',
        'c2': ['pencil', 'coin', 'eraser'],
        'a2': 0,
        'pairs': [
          {'left': 'ruler', 'right': 'length'},
          {'left': 'clock', 'right': 'time'},
          {'left': 'scale', 'right': 'weight'},
        ],
        'drawPrompt': 'Draw one long object and one short object.',
        'drawGuide': 'Label them long and short.',
        'drawTarget': 'L'
      },
      {
        'q1': 'What do you check to read time?',
        'c1': ['clock', 'shoe', 'spoon'],
        'a1': 0,
        'q2': 'How many days are in a week?',
        'c2': ['7', '5', '10'],
        'a2': 0,
        'pairs': [
          {'left': 'morning', 'right': 'before noon'},
          {'left': 'night', 'right': 'dark time'},
          {'left': 'week', 'right': '7 days'},
        ],
        'drawPrompt': 'Draw a clock and point to 3:00.',
        'drawGuide': 'Draw short hand and long hand.',
        'drawTarget': '3:00'
      },
      {
        'q1': 'Which is heavier?',
        'c1': ['a chair', 'a feather', 'a leaf'],
        'a1': 0,
        'q2': 'Which container often holds more water?',
        'c2': ['bucket', 'cup', 'spoon'],
        'a2': 0,
        'pairs': [
          {'left': 'heavy', 'right': 'more weight'},
          {'left': 'light', 'right': 'less weight'},
          {'left': 'full', 'right': 'has all space used'},
        ],
        'drawPrompt': 'Draw heavy and light objects.',
        'drawGuide': 'Use arrows and labels.',
        'drawTarget': 'H'
      },
      {
        'q1': 'What helps you compare lengths?',
        'c1': ['line up objects', 'close eyes', 'guess fast'],
        'a1': 0,
        'q2': 'Which comes after afternoon?',
        'c2': ['evening', 'morning', 'breakfast'],
        'a2': 0,
        'pairs': [
          {'left': 'morning', 'right': 'start of day'},
          {'left': 'afternoon', 'right': 'middle of day'},
          {'left': 'evening', 'right': 'end of day'},
        ],
        'drawPrompt': 'Draw your day: morning, afternoon, evening.',
        'drawGuide': 'Use three small pictures in order.',
        'drawTarget': 'D'
      },
      {
        'q1': 'What does a kilogram measure?',
        'c1': ['mass', 'color', 'sound'],
        'a1': 0,
        'q2': 'Which unit is for time?',
        'c2': ['minute', 'meter', 'liter'],
        'a2': 0,
        'pairs': [
          {'left': 'minute', 'right': 'time'},
          {'left': 'meter', 'right': 'length'},
          {'left': 'liter', 'right': 'capacity'},
        ],
        'drawPrompt': 'Draw a clock and write one time.',
        'drawGuide': 'Example: 7:00.',
        'drawTarget': 'T'
      },
    ];
    final preFr = <Map<String, dynamic>>[
      {
        'q1': 'Que mesures-tu avec une regle ?',
        'c1': ['longueur', 'odeur', 'gout'],
        'a1': 0,
        'q2': 'Quel objet est souvent plus long ?',
        'c2': ['crayon', 'piece', 'gomme'],
        'a2': 0,
        'pairs': [
          {'left': 'regle', 'right': 'longueur'},
          {'left': 'horloge', 'right': 'heure'},
          {'left': 'balance', 'right': 'poids'},
        ],
        'drawPrompt': 'Dessine un objet long et un objet court.',
        'drawGuide': 'Ecris long et court.',
        'drawTarget': 'L'
      },
      {
        'q1': 'Que regardes-tu pour lire l heure ?',
        'c1': ['horloge', 'chaussure', 'cuillere'],
        'a1': 0,
        'q2': 'Combien de jours dans une semaine ?',
        'c2': ['7', '5', '10'],
        'a2': 0,
        'pairs': [
          {'left': 'matin', 'right': 'avant midi'},
          {'left': 'nuit', 'right': 'temps sombre'},
          {'left': 'semaine', 'right': '7 jours'},
        ],
        'drawPrompt': 'Dessine une horloge a 3h00.',
        'drawGuide': 'Dessine la petite et la grande aiguille.',
        'drawTarget': '3:00'
      },
      {
        'q1': 'Quel objet est plus lourd ?',
        'c1': ['une chaise', 'une plume', 'une feuille'],
        'a1': 0,
        'q2': 'Quel contenant tient souvent plus d eau ?',
        'c2': ['seau', 'tasse', 'cuillere'],
        'a2': 0,
        'pairs': [
          {'left': 'lourd', 'right': 'plus de poids'},
          {'left': 'leger', 'right': 'moins de poids'},
          {'left': 'plein', 'right': 'espace rempli'},
        ],
        'drawPrompt': 'Dessine des objets lourds et legers.',
        'drawGuide': 'Ajoute des fleches et des mots.',
        'drawTarget': 'H'
      },
      {
        'q1': 'Comment compares-tu les longueurs ?',
        'c1': ['aligner les objets', 'fermer les yeux', 'deviner vite'],
        'a1': 0,
        'q2': 'Que vient apres l apres-midi ?',
        'c2': ['soir', 'matin', 'petit dejeuner'],
        'a2': 0,
        'pairs': [
          {'left': 'matin', 'right': 'debut du jour'},
          {'left': 'apres-midi', 'right': 'milieu du jour'},
          {'left': 'soir', 'right': 'fin du jour'},
        ],
        'drawPrompt': 'Dessine ton jour: matin, apres-midi, soir.',
        'drawGuide': 'Fais trois petits dessins dans l ordre.',
        'drawTarget': 'D'
      },
      {
        'q1': 'Que mesure un kilogramme ?',
        'c1': ['masse', 'couleur', 'son'],
        'a1': 0,
        'q2': 'Quelle unite mesure le temps ?',
        'c2': ['minute', 'metre', 'litre'],
        'a2': 0,
        'pairs': [
          {'left': 'minute', 'right': 'temps'},
          {'left': 'metre', 'right': 'longueur'},
          {'left': 'litre', 'right': 'capacite'},
        ],
        'drawPrompt': 'Dessine une horloge et ecris une heure.',
        'drawGuide': 'Exemple: 7h00.',
        'drawTarget': 'T'
      },
    ];
    final kEn = <Map<String, dynamic>>[
      {
        'q1': 'Which unit fits the length of a pencil?',
        'c1': ['centimeter', 'kilogram', 'liter'],
        'a1': 0,
        'q2': 'At 8:00, one hour later it is...',
        'c2': ['9:00', '7:00', '10:00'],
        'a2': 0,
        'q3': 'How many minutes are in 1 hour?',
        'c3': ['60', '30', '100'],
        'a3': 0,
        'pairs': [
          {'left': 'cm', 'right': 'small length'},
          {'left': 'm', 'right': 'longer length'},
          {'left': 'min', 'right': 'time'},
        ],
        'drawPrompt': 'Draw a clock at 9:30.',
        'drawGuide': 'Place both hands correctly.',
        'drawTarget': '9:30'
      },
      {
        'q1': 'Which tool measures mass?',
        'c1': ['scale', 'ruler', 'thermometer'],
        'a1': 0,
        'q2': 'Which object is likely heaviest?',
        'c2': ['a chair', 'a pencil', 'a feather'],
        'a2': 0,
        'q3': 'Which is the best unit for a backpack mass?',
        'c3': ['kilogram', 'centimeter', 'liter'],
        'a3': 0,
        'pairs': [
          {'left': 'kilogram', 'right': 'mass'},
          {'left': 'liter', 'right': 'capacity'},
          {'left': 'centimeter', 'right': 'length'},
        ],
        'drawPrompt': 'Draw two objects and compare their mass.',
        'drawGuide': 'Write heavier/lighter.',
        'drawTarget': 'M'
      },
      {
        'q1': 'How many days are in 2 weeks?',
        'c1': ['14', '10', '21'],
        'a1': 0,
        'q2': 'What time is 30 minutes after 2:15?',
        'c2': ['2:45', '2:30', '3:15'],
        'a2': 0,
        'q3': 'Which is more: 1 meter or 80 centimeters?',
        'c3': ['1 meter', '80 centimeters', 'they are equal'],
        'a3': 0,
        'pairs': [
          {'left': 'week', 'right': '7 days'},
          {'left': 'fortnight', 'right': '14 days'},
          {'left': 'half hour', 'right': '30 minutes'},
        ],
        'drawPrompt': 'Draw a timeline of your day.',
        'drawGuide': 'Add morning, afternoon, evening times.',
        'drawTarget': 'D'
      },
      {
        'q1': 'Which container likely holds the most liquid?',
        'c1': ['bucket', 'cup', 'spoon'],
        'a1': 0,
        'q2': 'Which is the best unit for water in a bottle?',
        'c2': ['liter', 'meter', 'kilogram'],
        'a2': 0,
        'q3': 'What is quarter past 4?',
        'c3': ['4:15', '4:45', '5:15'],
        'a3': 0,
        'pairs': [
          {'left': 'full', 'right': 'max capacity'},
          {'left': 'empty', 'right': 'no liquid'},
          {'left': 'half', 'right': 'middle amount'},
        ],
        'drawPrompt': 'Draw containers from small to large.',
        'drawGuide': 'Label: small, medium, large.',
        'drawTarget': 'C'
      },
      {
        'q1': 'If school starts at 8:00 and ends at 3:00, how many hours?',
        'c1': ['7', '5', '8'],
        'a1': 0,
        'q2': 'Which is the best unit for classroom length?',
        'c2': ['meter', 'minute', 'kilogram'],
        'a2': 0,
        'q3': 'Which statement is true?',
        'c3': ['100 cm = 1 m', '60 min = 1 day', '1 kg = 100 g'],
        'a3': 0,
        'pairs': [
          {'left': '100 cm', 'right': '1 m'},
          {'left': '60 min', 'right': '1 h'},
          {'left': '24 h', 'right': '1 day'},
        ],
        'drawPrompt': 'Draw one real-life measurement example.',
        'drawGuide': 'Write a value and unit (cm, m, kg, L, min).',
        'drawTarget': 'U'
      },
    ];
    final kFr = <Map<String, dynamic>>[
      {
        'q1': 'Quelle unite convient pour la longueur d un crayon ?',
        'c1': ['centimetre', 'kilogramme', 'litre'],
        'a1': 0,
        'q2': 'A 8h00, une heure plus tard il est...',
        'c2': ['9h00', '7h00', '10h00'],
        'a2': 0,
        'q3': 'Combien de minutes dans 1 heure ?',
        'c3': ['60', '30', '100'],
        'a3': 0,
        'pairs': [
          {'left': 'cm', 'right': 'petite longueur'},
          {'left': 'm', 'right': 'grande longueur'},
          {'left': 'min', 'right': 'temps'},
        ],
        'drawPrompt': 'Dessine une horloge a 9h30.',
        'drawGuide': 'Place correctement les deux aiguilles.',
        'drawTarget': '9:30'
      },
      {
        'q1': 'Quel outil mesure la masse ?',
        'c1': ['balance', 'regle', 'thermometre'],
        'a1': 0,
        'q2': 'Quel objet est probablement le plus lourd ?',
        'c2': ['une chaise', 'un crayon', 'une plume'],
        'a2': 0,
        'q3': 'Quelle unite convient pour la masse d un sac ?',
        'c3': ['kilogramme', 'centimetre', 'litre'],
        'a3': 0,
        'pairs': [
          {'left': 'kilogramme', 'right': 'masse'},
          {'left': 'litre', 'right': 'capacite'},
          {'left': 'centimetre', 'right': 'longueur'},
        ],
        'drawPrompt': 'Dessine deux objets et compare leur masse.',
        'drawGuide': 'Ecris plus lourd/plus leger.',
        'drawTarget': 'M'
      },
      {
        'q1': 'Combien de jours dans 2 semaines ?',
        'c1': ['14', '10', '21'],
        'a1': 0,
        'q2': 'Quelle heure est-il 30 min apres 2h15 ?',
        'c2': ['2h45', '2h30', '3h15'],
        'a2': 0,
        'q3': 'Quel est plus grand: 1 m ou 80 cm ?',
        'c3': ['1 m', '80 cm', 'egal'],
        'a3': 0,
        'pairs': [
          {'left': 'semaine', 'right': '7 jours'},
          {'left': 'quinzaine', 'right': '14 jours'},
          {'left': 'demi-heure', 'right': '30 minutes'},
        ],
        'drawPrompt': 'Dessine la ligne du temps de ta journee.',
        'drawGuide': 'Ajoute matin, apres-midi, soir.',
        'drawTarget': 'D'
      },
      {
        'q1': 'Quel contenant tient le plus de liquide ?',
        'c1': ['seau', 'tasse', 'cuillere'],
        'a1': 0,
        'q2': 'Quelle unite pour l eau d une bouteille ?',
        'c2': ['litre', 'metre', 'kilogramme'],
        'a2': 0,
        'q3': 'Que signifie 4h et quart ?',
        'c3': ['4h15', '4h45', '5h15'],
        'a3': 0,
        'pairs': [
          {'left': 'plein', 'right': 'capacite max'},
          {'left': 'vide', 'right': 'pas de liquide'},
          {'left': 'moitie', 'right': 'quantite moyenne'},
        ],
        'drawPrompt': 'Dessine des contenants du plus petit au plus grand.',
        'drawGuide': 'Ecris petit, moyen, grand.',
        'drawTarget': 'C'
      },
      {
        'q1': 'Si l ecole commence a 8h et finit a 15h, combien d heures ?',
        'c1': ['7', '5', '8'],
        'a1': 0,
        'q2': 'Quelle unite pour la longueur d une classe ?',
        'c2': ['metre', 'minute', 'kilogramme'],
        'a2': 0,
        'q3': 'Quelle phrase est vraie ?',
        'c3': ['100 cm = 1 m', '60 min = 1 jour', '1 kg = 100 g'],
        'a3': 0,
        'pairs': [
          {'left': '100 cm', 'right': '1 m'},
          {'left': '60 min', 'right': '1 h'},
          {'left': '24 h', 'right': '1 jour'},
        ],
        'drawPrompt': 'Dessine un exemple de mesure reelle.',
        'drawGuide': 'Ecris valeur + unite (cm, m, kg, L, min).',
        'drawTarget': 'U'
      },
    ];

    final source = isK ? (fr ? kFr : kEn) : (fr ? preFr : preEn);
    final rowIndex = _lessonRowIndex(n, source.length, cycleShift: 1);
    final challenge = _isChallengeLesson(n, source.length);
    final row = source[rowIndex];
    final pairList = (row['pairs'] as List)
        .map((e) => (e as Map).cast<String, String>())
        .toList();
    final firstQuestion = challenge
        ? (fr
            ? 'Defi: Quel outil ou unite correspond a "${pairList[0]['right']}" ?'
            : 'Challenge: Which tool or unit matches "${pairList[0]['right']}"?')
        : row['q1'].toString();
    final firstChoices = challenge
        ? [
            pairList[0]['left']!,
            pairList[1]['left']!,
            pairList[2]['left']!,
          ]
        : (row['c1'] as List).map((e) => e.toString()).toList();
    final firstAnswer = challenge ? 0 : (row['a1'] as num).toInt();
    final secondQuestion = challenge
        ? (fr
            ? 'Defi: Quelle signification va avec "${pairList[2]['left']}" ?'
            : 'Challenge: Which meaning goes with "${pairList[2]['left']}"?')
        : row['q2'].toString();
    final secondChoices = challenge
        ? [
            pairList[2]['right']!,
            pairList[0]['right']!,
            pairList[1]['right']!,
          ]
        : (row['c2'] as List).map((e) => e.toString()).toList();
    final secondAnswer = challenge ? 0 : (row['a2'] as num).toInt();
    final rotatedPairs = List.generate(
      pairList.length,
      (idx) => pairList[(idx + (challenge ? 1 : 0)) % pairList.length],
    );
    final steps = <LessonStep>[
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? (challenge
                    ? 'Lecon $n (K): Defi mesures, unites et durees.'
                    : 'Lecon $n (K): Unites, durees et comparaison de mesures.')
                : (challenge
                    ? 'Lecon $n (Pre-K): Defi longueur, poids et temps.'
                    : 'Lecon $n (Pre-K): Longueur, poids et temps du quotidien.'))
            : (isK
                ? (challenge
                    ? 'Lesson $n (K): Measurement challenge with units and time.'
                    : 'Lesson $n (K): Units, durations, and measurement comparison.')
                : (challenge
                    ? 'Lesson $n (Pre-K): Length, weight, and time challenge.'
                    : 'Lesson $n (Pre-K): Everyday length, weight, and time.'))
      }),
      LessonStep(kind: 'mcq', data: {
        'question': firstQuestion,
        'choices': firstChoices,
        'answerIndex': firstAnswer,
        'hint': fr
            ? 'Pense a l outil ou l unite correcte.'
            : 'Think about the correct tool or unit.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': secondQuestion,
        'choices': secondChoices,
        'answerIndex': secondAnswer,
        'hint':
            fr ? 'Utilise la logique de comparaison.' : 'Use comparison logic.'
      }),
    ];

    if (isK) {
      steps.add(
        LessonStep(kind: 'mcq', data: {
          'question': challenge
              ? (fr
                  ? 'Defi: Quelle option correspond a "${pairList[1]['left']}" ?'
                  : 'Challenge: Which option fits "${pairList[1]['left']}"?')
              : row['q3'],
          'choices': challenge
              ? [
                  pairList[1]['right']!,
                  pairList[0]['right']!,
                  pairList[2]['right']!,
                ]
              : row['c3'],
          'answerIndex': challenge ? 0 : (row['a3'] as num).toInt(),
          'hint': fr
              ? 'Relie unite et grandeur correcte.'
              : 'Match each unit to the right quantity.'
        }),
      );
    }

    steps.addAll([
      LessonStep(kind: 'match', data: {
        'instruction': fr ? 'Associe correctement.' : 'Match correctly.',
        'pairs': rotatedPairs
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': challenge
            ? (fr
                ? 'Defi dessin: cree une affiche mesure et temps.'
                : 'Drawing challenge: create one measurement/time poster.')
            : row['drawPrompt'],
        'guide': challenge
            ? (fr
                ? 'Ajoute deux unites et un exemple reel.'
                : 'Add two units and one real example.')
            : row['drawGuide'],
        'target': row['drawTarget']
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? (challenge
                    ? 'Ecris deux exemples de mesure avec deux unites differentes.'
                    : 'Ecris un exemple de mesure avec une unite.')
                : (challenge
                    ? 'Dis ou ecris deux exemples de mesure du quotidien.'
                    : 'Dis ou ecris un exemple de mesure a la maison.'))
            : (isK
                ? (challenge
                    ? 'Type two measurement examples using different units.'
                    : 'Type one measurement example with a unit.')
                : (challenge
                    ? 'Say or type two everyday measurement examples.'
                    : 'Say or type one measurement example at home.')),
        'hint': fr
            ? (isK
                ? 'Exemple: Ma table mesure 120 cm.'
                : 'Exemple: Mon crayon est long.')
            : (isK
                ? 'Example: My table is 120 cm long.'
                : 'Example: My pencil is long.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta phrase' : 'Your sentence',
        'inputHint': fr
            ? 'Utilise une unite comme cm, kg, L, min.'
            : 'Use a unit like cm, kg, L, min.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une phrase avant de valider.'
            : 'Type a sentence before submitting.'
      }),
    ]);

    return steps;
  }

  List<LessonStep> _pathProblemSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);

    Map<String, dynamic> makeProblem({
      required int a,
      required int b,
      required String op,
    }) {
      final ans = op == '+' ? a + b : a - b;
      final story = fr
          ? (op == '+'
              ? 'Tu as $a objets et tu en recois $b.'
              : 'Tu as $a objets et tu en donnes $b.')
          : (op == '+'
              ? 'You have $a objects and get $b more.'
              : 'You have $a objects and give away $b.');
      return {'story': story, 'eq': '$a $op $b', 'ans': ans};
    }

    List<String> choicesForAnswer(int answer,
        {required int min, required int max}) {
      final bounded = answer.clamp(min, max).toInt();
      final set = <int>{
        bounded,
        (bounded - 1).clamp(min, max).toInt(),
        (bounded + 1).clamp(min, max).toInt(),
      };
      var delta = 2;
      while (set.length < 3) {
        set.add((bounded + delta).clamp(min, max).toInt());
        delta++;
        if (delta > 8) break;
      }
      if (set.length < 3) {
        for (var v = min; v <= max && set.length < 3; v++) {
          set.add(v);
        }
      }
      return set.map((e) => '$e').toList();
    }

    int answerIndex(List<String> choices, int value) {
      final idx = choices.indexOf('$value');
      return idx < 0 ? 0 : idx;
    }

    late final Map<String, dynamic> p1;
    late final Map<String, dynamic> p2;
    late final Map<String, dynamic> p3;
    late final int compareA;
    late final int compareB;
    final maxValue = isK ? 50 : 20;

    if (isK) {
      p1 = makeProblem(a: (n - 1) * 8 + 12, b: 5, op: '+');
      p2 = makeProblem(a: (n - 1) * 8 + 18, b: 6, op: '-');
      p3 = makeProblem(a: (n - 1) * 6 + 9, b: (n - 1) * 2 + 6, op: '+');
      compareA = ((n - 1) * 7 + 18).clamp(10, 50).toInt();
      compareB = max(1, compareA - (n + 2));
    } else {
      final base = (n - 1) * 2 + 2;
      p1 = makeProblem(a: base, b: 1, op: '+');
      p2 = makeProblem(a: base + 4, b: 2, op: '-');
      p3 = makeProblem(a: base + 1, b: 2, op: '+');
      compareA = base + 5;
      compareB = base + 2;
    }

    final p1Choices = choicesForAnswer(
      (p1['ans'] as num).toInt(),
      min: 0,
      max: maxValue,
    );
    final p2Choices = choicesForAnswer(
      (p2['ans'] as num).toInt(),
      min: 0,
      max: maxValue,
    );
    final p3Choices = choicesForAnswer(
      (p3['ans'] as num).toInt(),
      min: 0,
      max: maxValue,
    );

    final compareSet = <int>{
      compareA.clamp(0, maxValue).toInt(),
      compareB.clamp(0, maxValue).toInt(),
      max(0, compareB - 1).clamp(0, maxValue).toInt(),
    };
    while (compareSet.length < 3) {
      compareSet
          .add((compareA + compareSet.length).clamp(0, maxValue).toInt());
      if (compareSet.length >= maxValue + 1) break;
    }
    if (compareSet.length < 3) {
      for (var v = 0; v <= maxValue && compareSet.length < 3; v++) {
        compareSet.add(v);
      }
    }
    final compareChoices = compareSet.map((e) => '$e').toList();
    final compareCorrect = (isK ? compareB : compareA).clamp(0, maxValue).toInt();

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? (isK
                ? 'Lecon $n (K) - Problemes jusqu a 50: addition, soustraction, comparaison et explication.'
                : 'Lecon $n (Pre-K) - Problemes concrets: compter, ajouter, enlever et comparer.')
            : (isK
                ? 'Lesson $n (K) - Word problems to 50: add, subtract, compare, and explain.'
                : 'Lesson $n (Pre-K) - Real-life problems: count, add, take away, and compare.')
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Avant de calculer, souligne les nombres et choisis + ou -.'
                : 'Lis l histoire et montre les objets avec tes doigts.')
            : (isK
                ? 'Before solving, underline numbers and choose + or -.'
                : 'Read the story and show objects with your fingers.'),
        'hint': fr
            ? (isK
                ? 'Etape: lire, choisir operation, calculer, verifier.'
                : 'Etape: compter puis repondre.')
            : (isK
                ? 'Steps: read, choose operation, calculate, check.'
                : 'Steps: count, then answer.')
      }),
      LessonStep(kind: 'mcq', data: {
        'question':
            '${p1['story']} ${fr ? 'Combien maintenant ?' : 'How many now?'}',
        'choices': p1Choices,
        'answerIndex': answerIndex(p1Choices, (p1['ans'] as num).toInt()),
        'hint': fr
            ? 'Transforme l histoire en calcul.'
            : 'Turn the story into an equation.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question':
            '${p2['story']} ${fr ? 'Combien reste-t-il ?' : 'How many are left?'}',
        'choices': p2Choices,
        'answerIndex': answerIndex(p2Choices, (p2['ans'] as num).toInt()),
        'hint': fr
            ? 'Quand on enleve, le total diminue.'
            : 'When we take away, the total gets smaller.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel est le resultat de ${p3['eq']} ?'
            : 'What is ${p3['eq']}?',
        'choices': p3Choices,
        'answerIndex': answerIndex(p3Choices, (p3['ans'] as num).toInt()),
        'hint': fr ? 'Calcule pas a pas.' : 'Solve it step by step.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? (isK
                ? 'Quel nombre est le plus petit ?'
                : 'Quel nombre est le plus grand ?')
            : (isK ? 'Which number is smaller?' : 'Which number is greater?'),
        'choices': compareChoices,
        'answerIndex': answerIndex(compareChoices, compareCorrect),
        'hint': fr
            ? 'Compare les valeurs des deux nombres.'
            : 'Compare the values of the numbers.'
      }),
      LessonStep(kind: 'match', data: {
        'instruction':
            fr ? 'Associe calcul et resultat.' : 'Match equation and result.',
        'pairs': [
          {
            'left': p1['eq'].toString(),
            'right': (p1['ans'] as num).toInt().toString()
          },
          {
            'left': p2['eq'].toString(),
            'right': (p2['ans'] as num).toInt().toString()
          },
          {
            'left': p3['eq'].toString(),
            'right': (p3['ans'] as num).toInt().toString()
          },
        ]
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': fr
            ? 'Ecris et trace le calcul ${p3['eq']}.'
            : 'Write and trace equation ${p3['eq']}.',
        'guide': fr
            ? 'Lis le calcul puis dis le resultat.'
            : 'Read the equation and say the answer.',
        'target': p3['eq'].toString()
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Explique en une phrase comment tu as resolu un probleme.'
                : 'Dis comment tu as trouve la reponse.')
            : (isK
                ? 'Explain in one sentence how you solved a problem.'
                : 'Say how you found the answer.'),
        'hint': fr
            ? (isK
                ? 'Exemple: J ai choisi + puis j ai additionne.'
                : 'Exemple: J ai compte avec mes doigts.')
            : (isK
                ? 'Example: I chose + and then added.'
                : 'Example: I counted with my fingers.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta methode' : 'Your method',
        'inputHint': fr ? 'Ecris une phrase.' : 'Write one sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une methode avant de valider.'
            : 'Type your method before submitting.'
      }),
    ];
  }

  List<LessonStep> _pathCreativeArtsSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final topics = [
      {
        'themeEn': 'Color Mixing Studio',
        'themeFr': 'Atelier Melange de Couleurs',
        'focusEn': 'primary colors',
        'focusFr': 'couleurs primaires',
        'toolEn': 'paint brush',
        'toolFr': 'pinceau',
        'drawEn': 'Paint two colors that mix into a new color.',
        'drawFr': 'Peins deux couleurs qui se melangent en nouvelle couleur.',
      },
      {
        'themeEn': 'Shape Collage Lab',
        'themeFr': 'Laboratoire Collage de Formes',
        'focusEn': 'shape composition',
        'focusFr': 'composition de formes',
        'toolEn': 'glue stick',
        'toolFr': 'colle',
        'drawEn': 'Create a collage using circles, triangles, and squares.',
        'drawFr': 'Cree un collage avec cercles, triangles et carres.',
      },
      {
        'themeEn': 'Texture Rubbing Art',
        'themeFr': 'Art des Textures',
        'focusEn': 'texture patterns',
        'focusFr': 'motifs de texture',
        'toolEn': 'crayon side',
        'toolFr': 'cote du crayon',
        'drawEn': 'Rub and draw three different textures.',
        'drawFr': 'Frotte et dessine trois textures differentes.',
      },
      {
        'themeEn': 'Pattern Weaving Design',
        'themeFr': 'Design Tissage de Motifs',
        'focusEn': 'repeating patterns',
        'focusFr': 'motifs repetes',
        'toolEn': 'paper strips',
        'toolFr': 'bandes de papier',
        'drawEn': 'Weave or draw an ABAB pattern in two colors.',
        'drawFr': 'Tisse ou dessine un motif ABAB avec deux couleurs.',
      },
      {
        'themeEn': 'Symmetry Butterfly Art',
        'themeFr': 'Art Papillon Symetrique',
        'focusEn': 'line symmetry',
        'focusFr': 'symetrie',
        'toolEn': 'folded paint print',
        'toolFr': 'empreinte pliee',
        'drawEn': 'Make one picture with matching left and right sides.',
        'drawFr': 'Fais une image avec cote gauche et droit identiques.',
      },
      {
        'themeEn': 'Warm and Cool Colors',
        'themeFr': 'Couleurs Chaudes et Froides',
        'focusEn': 'warm versus cool colors',
        'focusFr': 'couleurs chaudes et froides',
        'toolEn': 'color chart',
        'toolFr': 'nuancier',
        'drawEn': 'Split page: warm colors on one side, cool on the other.',
        'drawFr': 'Page partagee: couleurs chaudes d un cote, froides de l autre.',
      },
      {
        'themeEn': 'Clay and Form Studio',
        'themeFr': 'Atelier Argile et Formes',
        'focusEn': '3D forms',
        'focusFr': 'formes en 3D',
        'toolEn': 'modeling clay',
        'toolFr': 'pate a modeler',
        'drawEn': 'Model or draw a sphere, cube, and cone.',
        'drawFr': 'Modele ou dessine une sphere, un cube et un cone.',
      },
      {
        'themeEn': 'Print and Stamp Art',
        'themeFr': 'Art Impression et Tampons',
        'focusEn': 'printmaking',
        'focusFr': 'impression',
        'toolEn': 'stamp sponge',
        'toolFr': 'tampon eponge',
        'drawEn': 'Create a repeating stamp print with at least two shapes.',
        'drawFr': 'Cree une impression repetee avec au moins deux formes.',
      },
      {
        'themeEn': 'Story Mural Design',
        'themeFr': 'Design Fresque Histoire',
        'focusEn': 'visual storytelling',
        'focusFr': 'narration visuelle',
        'toolEn': 'scene sketch',
        'toolFr': 'croquis de scene',
        'drawEn': 'Draw a beginning, middle, and end in one mural strip.',
        'drawFr': 'Dessine debut, milieu et fin sur une bande de fresque.',
      },
      {
        'themeEn': 'Recycled Art Challenge',
        'themeFr': 'Defi Art Recycle',
        'focusEn': 'reuse and design',
        'focusFr': 'reutilisation et design',
        'toolEn': 'recycled materials',
        'toolFr': 'materiaux recycles',
        'drawEn': 'Design one useful object from recycled materials.',
        'drawFr': 'Concois un objet utile a partir de materiaux recycles.',
      },
    ];

    final idx = (n - 1).clamp(0, topics.length - 1).toInt();
    final topic = topics[idx];
    final theme = (fr ? topic['themeFr'] : topic['themeEn'])!.toString();
    final focus = (fr ? topic['focusFr'] : topic['focusEn'])!.toString();
    final tool = (fr ? topic['toolFr'] : topic['toolEn'])!.toString();
    final drawPrompt = (fr ? topic['drawFr'] : topic['drawEn'])!.toString();

    final focusChoices = [
      focus,
      fr ? 'calcul mental' : 'mental math',
      fr ? 'lecture rapide' : 'speed reading',
    ];
    final toolChoices = [
      tool,
      fr ? 'calculatrice' : 'calculator',
      fr ? 'chronometre' : 'stopwatch',
    ];

    final practiceHint = fr
        ? (isK
            ? 'Ajoute details, precision et choix de couleurs.'
            : 'Travaille lentement et proprement.')
        : (isK
            ? 'Add details, precision, and color choices.'
            : 'Work slowly and neatly.');

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Lecon $n (${isK ? 'K' : 'Pre-K'}) - Theme art: $theme.'
            : 'Lesson $n (${isK ? 'K' : 'Pre-K'}) - Art theme: $theme.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel est le focus artistique de cette lecon ?'
            : 'What is the art focus of this lesson?',
        'choices': focusChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Lis le theme puis choisis la meilleure idee.'
            : 'Read the theme and choose the best idea.',
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel outil aide le mieux cette activite ?'
            : 'Which tool best supports this activity?',
        'choices': toolChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Pense au materiel d un atelier d art.'
            : 'Think about real art studio materials.',
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe vocabulaire artistique et sens.'
            : 'Match art vocabulary to meaning.',
        'pairs': [
          {
            'left': fr ? 'theme' : 'theme',
            'right': fr ? 'idee principale du projet' : 'main project idea'
          },
          {
            'left': fr ? 'outil' : 'tool',
            'right': fr ? 'materiel utilise pour creer' : 'material used to create'
          },
          {
            'left': fr ? 'focus' : 'focus',
            'right': fr ? 'competence artistique pratiquee' : 'art skill being practiced'
          },
        ]
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': drawPrompt,
        'guide': practiceHint,
        'target': (isK ? 'ART' : 'A')
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Ecris une phrase sur ton choix artistique dans ce projet.'
                : 'Dis ce que tu as cree dans ton dessin.')
            : (isK
                ? 'Write one sentence about your art choice in this project.'
                : 'Say what you created in your drawing.'),
        'hint': fr
            ? (isK
                ? 'Exemple: J ai choisi des couleurs chaudes pour montrer la joie.'
                : 'Exemple: J ai dessine un papillon colore.')
            : (isK
                ? 'Example: I chose warm colors to show joy.'
                : 'Example: I drew a colorful butterfly.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta phrase d artiste' : 'Your artist sentence',
        'inputHint': fr ? 'Ecris une phrase courte.' : 'Write one short sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une phrase avant de valider.'
            : 'Type a sentence before submitting.',
      }),
    ];
  }

  List<LessonStep> _pathWorldGeographySteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final topics = [
      {
        'themeEn': 'Our Planet Earth',
        'themeFr': 'Notre Planete Terre',
        'focusEn': 'continents and oceans',
        'focusFr': 'continents et oceans',
        'placeEn': 'globe map',
        'placeFr': 'globe terrestre',
        'drawEn': 'Draw Earth with land and water colors.',
        'drawFr': 'Dessine la Terre avec couleurs terre et eau.',
      },
      {
        'themeEn': 'Maps and Symbols',
        'themeFr': 'Cartes et Symboles',
        'focusEn': 'map symbols',
        'focusFr': 'symboles de carte',
        'placeEn': 'map key',
        'placeFr': 'legende de carte',
        'drawEn': 'Draw a mini map using three symbols.',
        'drawFr': 'Dessine une mini carte avec trois symboles.',
      },
      {
        'themeEn': 'Landforms Around Us',
        'themeFr': 'Reliefs Autour de Nous',
        'focusEn': 'mountain river valley',
        'focusFr': 'montagne riviere vallee',
        'placeEn': 'landform map',
        'placeFr': 'carte des reliefs',
        'drawEn': 'Sketch one mountain, one river, and one valley.',
        'drawFr': 'Dessine une montagne, une riviere et une vallee.',
      },
      {
        'themeEn': 'Weather Regions',
        'themeFr': 'Regions Climatiques',
        'focusEn': 'hot cold rainy zones',
        'focusFr': 'zones chaudes froides pluvieuses',
        'placeEn': 'weather map',
        'placeFr': 'carte meteo',
        'drawEn': 'Create a map with hot, cold, and rainy areas.',
        'drawFr': 'Cree une carte avec zones chaudes, froides et pluvieuses.',
      },
      {
        'themeEn': 'Communities and Landmarks',
        'themeFr': 'Communautes et Lieux Importants',
        'focusEn': 'school hospital market',
        'focusFr': 'ecole hopital marche',
        'placeEn': 'town map',
        'placeFr': 'plan de ville',
        'drawEn': 'Draw a neighborhood map with three landmarks.',
        'drawFr': 'Dessine un plan de quartier avec trois lieux importants.',
      },
      {
        'themeEn': 'Routes and Transportation',
        'themeFr': 'Routes et Transport',
        'focusEn': 'road rail water routes',
        'focusFr': 'routes route rail eau',
        'placeEn': 'route map',
        'placeFr': 'carte des routes',
        'drawEn': 'Draw how people travel by road, rail, and water.',
        'drawFr': 'Dessine les trajets par route, rail et eau.',
      },
      {
        'themeEn': 'Homes Around the World',
        'themeFr': 'Maisons du Monde',
        'focusEn': 'different homes by climate',
        'focusFr': 'maisons selon le climat',
        'placeEn': 'world homes chart',
        'placeFr': 'tableau maisons du monde',
        'drawEn': 'Draw two homes from different climates.',
        'drawFr': 'Dessine deux maisons de climats differents.',
      },
      {
        'themeEn': 'Flags and Cultures',
        'themeFr': 'Drapeaux et Cultures',
        'focusEn': 'symbols of countries',
        'focusFr': 'symboles des pays',
        'placeEn': 'culture map',
        'placeFr': 'carte culturelle',
        'drawEn': 'Design a simple class flag and explain its symbols.',
        'drawFr': 'Concois un drapeau de classe et explique ses symboles.',
      },
      {
        'themeEn': 'Natural Resources',
        'themeFr': 'Ressources Naturelles',
        'focusEn': 'water soil forests',
        'focusFr': 'eau sol forets',
        'placeEn': 'resource map',
        'placeFr': 'carte des ressources',
        'drawEn': 'Map water, forest, and farm areas.',
        'drawFr': 'Cartographie eau, foret et zones de ferme.',
      },
      {
        'themeEn': 'Caring for Our World',
        'themeFr': 'Prendre Soin de Notre Monde',
        'focusEn': 'protecting places and people',
        'focusFr': 'proteger lieux et personnes',
        'placeEn': 'eco action map',
        'placeFr': 'carte eco actions',
        'drawEn': 'Draw one world-care plan with three actions.',
        'drawFr': 'Dessine un plan pour la Terre avec trois actions.',
      },
    ];

    final idx = (n - 1).clamp(0, topics.length - 1).toInt();
    final topic = topics[idx];
    final theme = (fr ? topic['themeFr'] : topic['themeEn'])!.toString();
    final focus = (fr ? topic['focusFr'] : topic['focusEn'])!.toString();
    final place = (fr ? topic['placeFr'] : topic['placeEn'])!.toString();
    final drawPrompt = (fr ? topic['drawFr'] : topic['drawEn'])!.toString();

    final focusChoices = [
      focus,
      fr ? 'tables de multiplication' : 'multiplication tables',
      fr ? 'orthographe avancee' : 'advanced spelling',
    ];
    final mapChoices = [
      place,
      fr ? 'equation numerique' : 'number equation',
      fr ? 'instrument de musique' : 'music instrument',
    ];

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Lecon $n (${isK ? 'K' : 'Pre-K'}) - Geographie: $theme.'
            : 'Lesson $n (${isK ? 'K' : 'Pre-K'}) - Geography: $theme.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel est le focus geographique de cette lecon ?'
            : 'What is the geography focus of this lesson?',
        'choices': focusChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Observe les mots du theme.'
            : 'Look carefully at the theme words.',
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel support cartographique est le plus utile ici ?'
            : 'Which map resource is most useful here?',
        'choices': mapChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Choisis un element lie aux cartes et lieux.'
            : 'Choose the option related to maps and places.',
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe vocabulaire geographique et sens.'
            : 'Match geography words and meanings.',
        'pairs': [
          {
            'left': fr ? 'carte' : 'map',
            'right': fr ? 'montre les lieux' : 'shows places'
          },
          {
            'left': fr ? 'legende' : 'key',
            'right': fr ? 'explique symboles' : 'explains symbols'
          },
          {
            'left': fr ? 'itineraire' : 'route',
            'right': fr ? 'chemin pour se deplacer' : 'path for travel'
          },
        ]
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': drawPrompt,
        'guide': fr
            ? (isK
                ? 'Ajoute labels clairs, fleches et orientation.'
                : 'Ajoute couleurs simples et un titre.')
            : (isK
                ? 'Add clear labels, arrows, and orientation.'
                : 'Add simple colors and one title.'),
        'target': 'MAP'
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Ecris une phrase sur ce que ce lieu du monde nous apprend.'
                : 'Dis un mot nouveau appris sur le monde.')
            : (isK
                ? 'Write one sentence about what this world place teaches us.'
                : 'Say one new world word you learned.'),
        'hint': fr
            ? (isK
                ? 'Exemple: Une carte nous aide a trouver des lieux importants.'
                : 'Exemple: J ai appris le mot carte.')
            : (isK
                ? 'Example: A map helps us find important places.'
                : 'Example: I learned the word map.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta phrase monde' : 'Your world sentence',
        'inputHint': fr ? 'Ecris une phrase courte.' : 'Write one short sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une phrase avant de valider.'
            : 'Type a sentence before submitting.',
      }),
    ];
  }

  List<LessonStep> _pathHistoryCultureSteps(int n, bool fr, String level) {
    final isK = _isKLevel(level);
    final topics = [
      {
        'themeEn': 'Past and Present',
        'themeFr': 'Passe et Present',
        'focusEn': 'how life changes over time',
        'focusFr': 'comment la vie change avec le temps',
        'artifactEn': 'old photo album',
        'artifactFr': 'album de vieilles photos',
        'drawEn': 'Draw one thing from the past and one from today.',
        'drawFr': 'Dessine une chose du passe et une chose d aujourd hui.',
      },
      {
        'themeEn': 'Family Timeline',
        'themeFr': 'Ligne du Temps de la Famille',
        'focusEn': 'before now after',
        'focusFr': 'avant maintenant apres',
        'artifactEn': 'timeline chart',
        'artifactFr': 'frise chronologique',
        'drawEn': 'Create a three-step timeline from baby to now.',
        'drawFr': 'Cree une frise en trois etapes de bebe a maintenant.',
      },
      {
        'themeEn': 'Tools Through Time',
        'themeFr': 'Outils a Travers le Temps',
        'focusEn': 'old tools and new tools',
        'focusFr': 'anciens outils et outils modernes',
        'artifactEn': 'tool comparison card',
        'artifactFr': 'fiche comparaison outils',
        'drawEn': 'Draw an old tool and a modern version.',
        'drawFr': 'Dessine un ancien outil et sa version moderne.',
      },
      {
        'themeEn': 'Communication History',
        'themeFr': 'Histoire de la Communication',
        'focusEn': 'letters phone internet',
        'focusFr': 'lettres telephone internet',
        'artifactEn': 'message timeline',
        'artifactFr': 'frise des messages',
        'drawEn': 'Draw how messages were sent then and now.',
        'drawFr': 'Dessine comment les messages etaient envoyes avant et maintenant.',
      },
      {
        'themeEn': 'Transportation History',
        'themeFr': 'Histoire des Transports',
        'focusEn': 'walking carts cars trains',
        'focusFr': 'marche chariots voitures trains',
        'artifactEn': 'transport chart',
        'artifactFr': 'tableau des transports',
        'drawEn': 'Draw transport from past, present, and future.',
        'drawFr': 'Dessine transport passe, present et futur.',
      },
      {
        'themeEn': 'Community Helpers in History',
        'themeFr': 'Aides de la Communaute dans l Histoire',
        'focusEn': 'roles that served people',
        'focusFr': 'roles au service des gens',
        'artifactEn': 'helper role cards',
        'artifactFr': 'cartes metiers utiles',
        'drawEn': 'Draw a helper from long ago and one today.',
        'drawFr': 'Dessine un aide d autrefois et un aide d aujourd hui.',
      },
      {
        'themeEn': 'Traditions and Celebrations',
        'themeFr': 'Traditions et Celebrations',
        'focusEn': 'customs passed between generations',
        'focusFr': 'coutumes transmises entre generations',
        'artifactEn': 'tradition story card',
        'artifactFr': 'fiche histoire de tradition',
        'drawEn': 'Draw one tradition and explain why it matters.',
        'drawFr': 'Dessine une tradition et explique pourquoi elle compte.',
      },
      {
        'themeEn': 'Landmarks and Local Stories',
        'themeFr': 'Lieux Historiques et Histoires Locales',
        'focusEn': 'important places and memories',
        'focusFr': 'lieux importants et souvenirs',
        'artifactEn': 'landmark map',
        'artifactFr': 'carte des lieux historiques',
        'drawEn': 'Draw a local landmark with one historical note.',
        'drawFr': 'Dessine un lieu local avec une note historique.',
      },
      {
        'themeEn': 'Inventors and Ideas',
        'themeFr': 'Inventeurs et Idees',
        'focusEn': 'ideas that solve problems',
        'focusFr': 'idees qui resolvent des problemes',
        'artifactEn': 'invention sketch page',
        'artifactFr': 'page croquis invention',
        'drawEn': 'Sketch one invention and the problem it solved.',
        'drawFr': 'Croque une invention et le probleme resolu.',
      },
      {
        'themeEn': 'Learning from History',
        'themeFr': 'Apprendre de l Histoire',
        'focusEn': 'using past lessons to improve tomorrow',
        'focusFr': 'utiliser le passe pour ameliorer demain',
        'artifactEn': 'history reflection sheet',
        'artifactFr': 'fiche reflexion histoire',
        'drawEn': 'Draw one lesson from history for a better future.',
        'drawFr': 'Dessine une lecon de l histoire pour un meilleur futur.',
      },
    ];

    final idx = (n - 1).clamp(0, topics.length - 1).toInt();
    final topic = topics[idx];
    final theme = (fr ? topic['themeFr'] : topic['themeEn'])!.toString();
    final focus = (fr ? topic['focusFr'] : topic['focusEn'])!.toString();
    final artifact = (fr ? topic['artifactFr'] : topic['artifactEn'])!.toString();
    final drawPrompt = (fr ? topic['drawFr'] : topic['drawEn'])!.toString();

    final focusChoices = [
      focus,
      fr ? 'division longue' : 'long division',
      fr ? 'classification chimique' : 'chemical classification',
    ];
    final artifactChoices = [
      artifact,
      fr ? 'table de multiplication' : 'multiplication table',
      fr ? 'partition musicale' : 'music sheet',
    ];

    return [
      LessonStep(kind: 'info', data: {
        'text': fr
            ? 'Lecon $n (${isK ? 'K' : 'Pre-K'}) - Histoire/Culture: $theme.'
            : 'Lesson $n (${isK ? 'K' : 'Pre-K'}) - History/Culture: $theme.'
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel est le focus historique de cette lecon ?'
            : 'What is the history focus of this lesson?',
        'choices': focusChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Cherche les idees liees au passe et au present.'
            : 'Look for ideas linked to past and present.',
      }),
      LessonStep(kind: 'mcq', data: {
        'question': fr
            ? 'Quel document ou support convient le mieux ?'
            : 'Which document or resource fits best?',
        'choices': artifactChoices,
        'answerIndex': 0,
        'hint': fr
            ? 'Choisis la ressource liee a l histoire.'
            : 'Choose the resource connected to history.',
      }),
      LessonStep(kind: 'match', data: {
        'instruction': fr
            ? 'Associe mot historique et signification.'
            : 'Match history term and meaning.',
        'pairs': [
          {
            'left': fr ? 'passe' : 'past',
            'right': fr ? 'ce qui est deja arrive' : 'what already happened'
          },
          {
            'left': fr ? 'present' : 'present',
            'right': fr ? 'ce qui se passe maintenant' : 'what happens now'
          },
          {
            'left': fr ? 'futur' : 'future',
            'right': fr ? 'ce qui peut arriver demain' : 'what may happen next'
          },
        ]
      }),
      LessonStep(kind: 'draw', data: {
        'prompt': drawPrompt,
        'guide': fr
            ? (isK
                ? 'Ajoute titre, labels et une courte explication.'
                : 'Dessine clair avec deux details.')
            : (isK
                ? 'Add a title, labels, and one short explanation.'
                : 'Draw clearly with two details.'),
        'target': 'TIME'
      }),
      LessonStep(kind: 'prompt', data: {
        'prompt': fr
            ? (isK
                ? 'Ecris une phrase: quelle idee du passe peut aider aujourd hui ?'
                : 'Dis une chose que tu as apprise sur le passe.')
            : (isK
                ? 'Write one sentence: what past idea can help today?'
                : 'Say one thing you learned about the past.'),
        'hint': fr
            ? (isK
                ? 'Exemple: Les anciennes solutions inspirent de nouvelles idees.'
                : 'Exemple: Avant, les gens ecrivaient des lettres.')
            : (isK
                ? 'Example: Old solutions can inspire new ideas.'
                : 'Example: Long ago, people sent letters.'),
        'inputEnabled': true,
        'inputLabel': fr ? 'Ta phrase histoire' : 'Your history sentence',
        'inputHint': fr ? 'Ecris une phrase courte.' : 'Write one short sentence.',
        'submitLabel': fr ? 'Valider' : 'Enter',
        'displayPrefix': fr ? 'Tu as ecrit:' : 'You typed:',
        'emptyInputMessage': fr
            ? 'Ecris une phrase avant de valider.'
            : 'Type a sentence before submitting.',
      }),
    ];
  }

  String _numberWord(int n, bool fr) {
    final safe = n.clamp(0, 50).toInt();

    if (!fr) {
      const units = {
        0: 'zero',
        1: 'one',
        2: 'two',
        3: 'three',
        4: 'four',
        5: 'five',
        6: 'six',
        7: 'seven',
        8: 'eight',
        9: 'nine',
        10: 'ten',
        11: 'eleven',
        12: 'twelve',
        13: 'thirteen',
        14: 'fourteen',
        15: 'fifteen',
        16: 'sixteen',
        17: 'seventeen',
        18: 'eighteen',
        19: 'nineteen'
      };
      const tens = {20: 'twenty', 30: 'thirty', 40: 'forty', 50: 'fifty'};
      if (safe <= 19) {
        return units[safe] ?? '$safe';
      }
      if (safe % 10 == 0) {
        return tens[safe] ?? '$safe';
      }
      final ten = (safe ~/ 10) * 10;
      return '${tens[ten] ?? ten} ${units[safe % 10] ?? safe % 10}';
    }

    const base = {
      0: 'zero',
      1: 'un',
      2: 'deux',
      3: 'trois',
      4: 'quatre',
      5: 'cinq',
      6: 'six',
      7: 'sept',
      8: 'huit',
      9: 'neuf',
      10: 'dix',
      11: 'onze',
      12: 'douze',
      13: 'treize',
      14: 'quatorze',
      15: 'quinze',
      16: 'seize',
      17: 'dix-sept',
      18: 'dix-huit',
      19: 'dix-neuf'
    };

    if (safe <= 19) {
      return base[safe] ?? '$safe';
    }
    if (safe == 20) {
      return 'vingt';
    }
    if (safe < 30) {
      return safe == 21 ? 'vingt et un' : 'vingt-${base[safe - 20]}';
    }
    if (safe == 30) {
      return 'trente';
    }
    if (safe < 40) {
      return safe == 31 ? 'trente et un' : 'trente-${base[safe - 30]}';
    }
    if (safe == 40) {
      return 'quarante';
    }
    if (safe < 50) {
      return safe == 41 ? 'quarante et un' : 'quarante-${base[safe - 40]}';
    }
    return 'cinquante';
  }

  Future<Map<String, dynamic>> loadWorksheetTemplate(
      String lang, String assetFile) async {
    final raw =
        await rootBundle.loadString('assets/worksheets/$lang/$assetFile');
    return (json.decode(raw) as Map).cast<String, dynamic>();
  }

  Future<InteractiveWorksheetManifest> loadInteractiveWorksheetManifest(
      String lang) async {
    final raw = await rootBundle
        .loadString('assets/worksheets/$lang/interactive_manifest.json');
    return InteractiveWorksheetManifest.fromJson(
      (json.decode(raw) as Map).cast<String, dynamic>(),
    );
  }

  Future<InteractiveWorksheet> loadInteractiveWorksheet(
      String lang, String assetFile) async {
    if (assetFile.startsWith('generated:')) {
      return _buildGeneratedWorksheet(lang, assetFile);
    }
    final raw =
        await rootBundle.loadString('assets/worksheets/$lang/$assetFile');
    return InteractiveWorksheet.fromJson(
      (json.decode(raw) as Map).cast<String, dynamic>(),
    );
  }

  InteractiveWorksheet _buildGeneratedWorksheet(String lang, String spec) {
    final parts = spec.split(':');
    if (parts.length < 6) {
      throw ArgumentError('Invalid generated worksheet spec: $spec');
    }
    final type = parts[1];
    final level = parts[2];
    final chapterNumber = int.tryParse(parts[3]) ?? 1;
    final chapterSlug = parts[4];
    final lessonNo = int.tryParse(parts[5]) ?? 1;
    final seed = _stableHash(
      '$lang|$level|$type|$chapterSlug|$chapterNumber|$lessonNo',
    );
    final rand = Random(seed);

    final bool fr = lang == 'fr';
    final title = fr
        ? "Chapitre $chapterNumber - Lecon $lessonNo"
        : "Chapter $chapterNumber - Lesson $lessonNo";
    final subtitle =
        fr ? "Parcours $level - $chapterSlug" : "$level path - $chapterSlug";
    final instructions = switch (type) {
      'circle_count' => fr
          ? "Compte les formes puis touche le bon nombre."
          : "Count the shapes and tap the right number.",
      'trace_letters' =>
        fr ? "Trace puis valide chaque carte." : "Trace and submit each card.",
      'addition_burst' => fr
          ? "Calcule puis choisis la bonne reponse."
          : "Solve then choose the correct answer.",
      _ => fr
          ? "Lis puis choisis la bonne reponse."
          : "Read and choose the best answer.",
    };
    final reward = fr ? "Badge chapitre termine" : "Chapter completion badge";

    final items = switch (type) {
      'circle_count' =>
        _genCircleCountItems(rand, fr, level, chapterSlug, lessonNo),
      'trace_letters' => _genTraceItems(rand, fr, level, chapterSlug, lessonNo),
      'addition_burst' => _genMathItems(rand, fr, level, chapterSlug, lessonNo),
      _ => _genReadingItems(rand, fr, level, chapterSlug, lessonNo),
    };

    return InteractiveWorksheet(
      id: "generated_${type}_${level}_${chapterSlug}_$lessonNo",
      title: title,
      subtitle: subtitle,
      level: level,
      type: type,
      instructions: instructions,
      rewardLabel: reward,
      items: items,
    );
  }

  int _stableHash(String input) {
    int h = 0;
    for (int i = 0; i < input.length; i++) {
      h = ((h * 31) + input.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }

  String _shapeWord(String shape, bool fr) {
    switch (shape) {
      case 'circle':
        return fr ? 'cercles' : 'circles';
      case 'triangle':
        return fr ? 'triangles' : 'triangles';
      case 'square':
        return fr ? 'carres' : 'squares';
      case 'heart':
        return fr ? 'coeurs' : 'hearts';
      default:
        return fr ? 'etoiles' : 'stars';
    }
  }

  String _exercisePrefix(
    bool fr,
    int lessonNo,
    int itemIndex, {
    required String chapterSlug,
  }) {
    final number = ((lessonNo - 1) * 5) + itemIndex + 1;
    final chapter = chapterSlug.replaceAll('_', ' ');
    return fr
        ? "[$chapter] Exercice $number: "
        : "[$chapter] Exercise $number: ";
  }

  List<Map<String, dynamic>> _genCircleCountItems(
      Random rand, bool fr, String level, String chapterSlug, int lessonNo) {
    const defaultShapes = ['star', 'circle', 'triangle', 'square', 'heart'];
    final shapes = chapterSlug.contains('shapes')
        ? const ['triangle', 'square', 'circle', 'heart', 'star']
        : defaultShapes;
    final min =
        chapterSlug.contains('numbers_1_10') ? 1 : (level == 'Pre-K' ? 2 : 6);
    final max = chapterSlug.contains('numbers_1_10')
        ? 10
        : (level == 'Pre-K' ? 12 : 20);

    return List.generate(10, (i) {
      final shape = shapes[(lessonNo + i) % shapes.length];
      final span = max - min + 1;
      final count = min + ((lessonNo * 7 + i * 3 + rand.nextInt(11)) % span);
      final a = (count - 1).clamp(min, max).toInt();
      final b = (count + 1).clamp(min, max).toInt();
      final choices = <int>{a, count, b}.toList();
      while (choices.length < 3) {
        final candidate = min + rand.nextInt(max - min + 1);
        if (!choices.contains(candidate)) choices.add(candidate);
      }
      choices.shuffle(rand);
      final prompt = fr
          ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Combien de ${_shapeWord(shape, fr)} vois-tu ?"
          : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}How many ${_shapeWord(shape, fr)} can you count?";
      return {
        'prompt': prompt,
        'shape': shape,
        'count': count,
        'choices': choices,
        'answerIndex': choices.indexOf(count),
      };
    });
  }

  List<Map<String, dynamic>> _genTraceItems(
      Random rand, bool fr, String level, String chapterSlug, int lessonNo) {
    final preKPool = <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9'
    ];
    final kPool = <String>[
      'CAT',
      'SUN',
      'MAP',
      'BUS',
      'PEN',
      'DOG',
      'BOOK',
      'STAR',
      'TREE',
      'FISH',
      'MOON',
      'RAIN',
      'BIRD',
      'FROG',
      'SHIP',
      'TIME',
      'HOME',
      'READ',
      'PLAY',
      'KIND'
    ];
    final pool = chapterSlug.contains('sentence_reading')
        ? kPool
        : (level == 'Pre-K' ? preKPool : kPool);
    final start = ((lessonNo - 1) * 3) % pool.length;

    return List.generate(10, (i) {
      final idx = (start + i) % pool.length;
      final target = pool[idx];
      final prompt = fr
          ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Trace: $target"
          : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Trace: $target";
      return {
        'prompt': prompt,
        'guide': fr
            ? "Trace lentement, lis le mot, puis touche Termine."
            : "Trace slowly, read the word, then tap Done.",
        'target': target,
      };
    });
  }

  List<Map<String, dynamic>> _genMathItems(
      Random rand, bool fr, String level, String chapterSlug, int lessonNo) {
    final maxA = chapterSlug.contains('story_problem')
        ? 12
        : (level == 'Pre-K' ? 9 : 20);
    final minA = level == 'Pre-K' ? 1 : 4;
    final forceSub = chapterSlug.contains('subtraction') ||
        chapterSlug.contains('soustraction');
    final forceAdd = chapterSlug.contains('addition') ||
        chapterSlug.contains('story_problem');
    final storyNouns = fr
        ? ['pommes', 'crayons', 'blocs', 'fleurs', 'bonbons', 'billes']
        : ['apples', 'pencils', 'blocks', 'flowers', 'candies', 'marbles'];

    return List.generate(10, (i) {
      final useSub =
          forceSub ? true : (forceAdd ? false : (i + lessonNo) % 3 == 0);
      int a =
          minA + ((lessonNo * 4 + i * 3 + rand.nextInt(5)) % (maxA - minA + 1));
      int b = 1 +
          ((lessonNo * 2 + i + rand.nextInt(4)) % (level == 'Pre-K' ? 5 : 10));
      String op = '+';
      int answer = a + b;
      if (useSub) {
        op = '-';
        if (b > a) {
          final tmp = a;
          a = b;
          b = tmp;
        }
        answer = a - b;
      }
      final choices =
          <int>{answer, answer + 1, (answer - 1).clamp(0, 99)}.toList();
      while (choices.length < 3) {
        final candidate = (answer + rand.nextInt(5) - 2).clamp(0, 99);
        if (!choices.contains(candidate)) choices.add(candidate);
      }
      choices.shuffle(rand);
      final noun = storyNouns[(lessonNo + i) % storyNouns.length];
      final prompt = chapterSlug.contains('story_problem')
          ? (fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Tu as $a $noun et tu en recois $b. Combien au total ?"
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}You have $a $noun and get $b more. How many in total?")
          : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}$a $op $b = ?";
      return {
        'prompt': prompt,
        'op': op,
        'a': a,
        'b': b,
        'choices': choices.map((e) => e.toString()).toList(),
        'answerIndex': choices.indexOf(answer),
      };
    });
  }

  List<Map<String, dynamic>> _genReadingItems(
      Random rand, bool fr, String level, String chapterSlug, int lessonNo) {
    if (chapterSlug.contains('colors')) {
      final colors = fr
          ? [
              'rouge',
              'bleu',
              'vert',
              'jaune',
              'orange',
              'violet',
              'rose',
              'blanc',
              'noir',
              'marron',
              'gris',
              'turquoise'
            ]
          : [
              'red',
              'blue',
              'green',
              'yellow',
              'orange',
              'purple',
              'pink',
              'white',
              'black',
              'brown',
              'gray',
              'turquoise'
            ];
      final objects = fr
          ? [
              'pomme',
              'ciel',
              'herbe',
              'banane',
              'carotte',
              'fleur violette',
              'flamant',
              'neige',
              'charbon',
              'chocolat',
              'nuage',
              'mer tropicale'
            ]
          : [
              'apple',
              'sky',
              'grass',
              'banana',
              'carrot',
              'violet flower',
              'flamingo',
              'snow',
              'charcoal',
              'chocolate',
              'cloud',
              'tropical sea'
            ];
      return List.generate(10, (i) {
        final idx = (lessonNo + i) % colors.length;
        final target = colors[idx];
        final wrong1 = colors[(idx + 1) % colors.length];
        final wrong2 = colors[(idx + 2) % colors.length];
        final options = [target, wrong1, wrong2]..shuffle(rand);
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Quelle couleur correspond a ${objects[idx]} ?"
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Which color matches ${objects[idx]}?",
          'choices': options,
          'answerIndex': options.indexOf(target),
        };
      });
    }

    if (chapterSlug.contains('rhymes')) {
      final sets = fr
          ? [
              ['chat', 'rat', 'soleil', 'livre'],
              ['balle', 'salle', 'chien', 'nez'],
              ['lune', 'plume', 'arbre', 'table'],
              ['car', 'star', 'porte', 'vase'],
              ['main', 'pain', 'lampe', 'mur'],
              ['fleur', 'coeur', 'chaussette', 'table'],
              ['bleu', 'feu', 'chat', 'neige'],
              ['bateau', 'chateau', 'stylo', 'fenetre'],
              ['train', 'matin', 'cartable', 'crayon'],
              ['souris', 'gris', 'pomme', 'tasse'],
              ['photo', 'moto', 'sac', 'voiture'],
              ['papier', 'panier', 'table', 'livre'],
            ]
          : [
              ['cat', 'hat', 'sun', 'book'],
              ['ball', 'wall', 'fish', 'cup'],
              ['moon', 'spoon', 'tree', 'pen'],
              ['star', 'car', 'book', 'red'],
              ['bee', 'tree', 'sun', 'bat'],
              ['light', 'kite', 'dog', 'chair'],
              ['boat', 'goat', 'ring', 'sock'],
              ['cake', 'lake', 'cloud', 'book'],
              ['train', 'rain', 'apple', 'door'],
              ['fish', 'dish', 'stone', 'leaf'],
              ['bell', 'shell', 'window', 'star'],
              ['bed', 'red', 'table', 'jump'],
            ];
      return List.generate(10, (i) {
        final row = sets[(lessonNo + i) % sets.length];
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Quel mot rime avec ${row[0]} ?"
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Which word rhymes with ${row[0]}?",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('patterns')) {
      final patterns = fr
          ? [
              ['etoile, cercle, etoile, cercle', 'etoile', 'triangle', 'carre'],
              ['rouge, bleu, rouge, bleu', 'rouge', 'vert', 'jaune'],
              ['1, 2, 1, 2', '1', '3', '4'],
              ['A, B, A, B', 'A', 'C', 'D'],
              ['clap, tape pied, clap, tape pied', 'clap', 'saute', 'assis'],
              ['grand, petit, grand, petit', 'grand', 'moyen', 'petit petit'],
              ['triangle, triangle, cercle, triangle, triangle, cercle', 'triangle', 'carre', 'etoile'],
              ['lundi, mardi, lundi, mardi', 'lundi', 'samedi', 'vendredi'],
              ['chaud, froid, chaud, froid', 'chaud', 'tiere', 'frais'],
              ['5, 10, 5, 10', '5', '15', '20'],
              ['saute, tourne, saute, tourne', 'saute', 'dors', 'mange'],
              ['coeur, carre, coeur, carre', 'coeur', 'lune', 'nuage'],
            ]
          : [
              ['star, circle, star, circle', 'star', 'triangle', 'square'],
              ['red, blue, red, blue', 'red', 'green', 'yellow'],
              ['1, 2, 1, 2', '1', '3', '4'],
              ['A, B, A, B', 'A', 'C', 'D'],
              ['clap, stomp, clap, stomp', 'clap', 'jump', 'sit'],
              ['big, small, big, small', 'big', 'medium', 'tiny'],
              ['triangle, triangle, circle, triangle, triangle, circle', 'triangle', 'square', 'star'],
              ['Monday, Tuesday, Monday, Tuesday', 'Monday', 'Saturday', 'Friday'],
              ['hot, cold, hot, cold', 'hot', 'warm', 'cool'],
              ['5, 10, 5, 10', '5', '15', '20'],
              ['jump, spin, jump, spin', 'jump', 'sleep', 'eat'],
              ['heart, square, heart, square', 'heart', 'moon', 'cloud'],
            ];
      return List.generate(10, (i) {
        final row = patterns[(lessonNo + i) % patterns.length];
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Quel element vient ensuite ? (${row[0]}, ...)"
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}What comes next? (${row[0]}, ...)",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('compare_size')) {
      final rows = fr
          ? [
              ['elephant', 'grand'],
              ['fourmi', 'petit'],
              ['bus', 'grand'],
              ['piece', 'petit'],
              ['baleine', 'grand'],
              ['graine', 'petit'],
              ['maison', 'grand'],
              ['stylo', 'petit'],
              ['avion', 'grand'],
              ['tasse', 'petit'],
              ['ballon de plage', 'grand'],
              ['perle', 'petit'],
            ]
          : [
              ['elephant', 'big'],
              ['ant', 'small'],
              ['bus', 'big'],
              ['coin', 'small'],
              ['whale', 'big'],
              ['seed', 'small'],
              ['house', 'big'],
              ['pen', 'small'],
              ['airplane', 'big'],
              ['cup', 'small'],
              ['beach ball', 'big'],
              ['bead', 'small'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        final right = row[1];
        final wrong1 = fr
            ? (right == 'grand' ? 'petit' : 'grand')
            : (right == 'big' ? 'small' : 'big');
        final wrong2 = fr ? 'moyen' : 'medium';
        final options = [right, wrong1, wrong2]..shuffle(rand);
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]} est plutot..."
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}$row[0] is usually...",
          'choices': options,
          'answerIndex': options.indexOf(right),
        };
      });
    }

    if (chapterSlug.contains('kindness')) {
      final rows = fr
          ? [
              [
                'Ton ami tombe. Que fais-tu ?',
                'Je l aide',
                'Je ris',
                'Je pars'
              ],
              ['Quel choix est gentil ?', 'Partager', 'Pousser', 'Crier'],
              ['Un ami est triste. Tu...', 'Consoles', 'Ignores', 'Te moques'],
              ['En classe, on parle...', 'Doucement', 'Fort', 'Jamais'],
              ['Quand tu empruntes...', 'Tu rends', 'Tu caches', 'Tu jettes'],
              ['Au jeu, tu...', 'Attends ton tour', 'Triches', 'Bouscules'],
              ['Quel mot est gentil ?', 'Merci', 'Va t en', 'N importe quoi'],
              ['Quel geste montre le respect ?', 'Ecouter', 'Couper la parole', 'Se moquer'],
              ['Un nouveau arrive. Tu...', 'Dis bonjour', 'Tournes le dos', 'Critiques'],
              ['Dans une file, tu...', 'Patientes', 'Pousses', 'Cris'],
              ['Si quelqu un oublie son crayon, tu...', 'Pretes un crayon', 'Caches les crayons', 'Ricanes'],
              ['En equipe, tu...', 'Encourages', 'Refuses tout', 'Commandes toujours'],
            ]
          : [
              [
                'A friend falls. What do you do?',
                'Help them',
                'Laugh',
                'Walk away'
              ],
              ['Which choice is kind?', 'Share', 'Push', 'Yell'],
              ['A friend is sad. You...', 'Comfort', 'Ignore', 'Mock'],
              ['In class we speak...', 'Softly', 'Loudly', 'Never'],
              ['When you borrow...', 'Return it', 'Hide it', 'Throw it'],
              ['During games you...', 'Take turns', 'Cheat', 'Shove'],
              ['Which word is kind?', 'Please', 'Go away', 'Whatever'],
              ['Which action shows respect?', 'Listen', 'Interrupt', 'Tease'],
              ['A new student arrives. You...', 'Say hello', 'Turn away', 'Judge them'],
              ['In a line, you...', 'Wait your turn', 'Push', 'Shout'],
              ['If someone forgot a pencil, you...', 'Share one', 'Hide pencils', 'Laugh'],
              ['In teamwork, you...', 'Encourage others', 'Quit early', 'Boss everyone'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('sight_words')) {
      final words = fr
          ? [
              'le',
              'la',
              'et',
              'est',
              'dans',
              'sur',
              'avec',
              'pour',
              'un',
              'une'
            ]
          : ['the', 'and', 'is', 'in', 'on', 'you', 'said', 'can', 'we', 'to'];
      return List.generate(10, (i) {
        final idx = (lessonNo * 2 + i) % words.length;
        final target = words[idx];
        final wrong1 = words[(idx + 1) % words.length];
        final wrong2 = words[(idx + 2) % words.length];
        final options = [target, wrong1, wrong2]..shuffle(rand);
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Touche le mot: $target"
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Tap the sight word: $target",
          'choices': options,
          'answerIndex': options.indexOf(target),
        };
      });
    }

    if (chapterSlug.contains('word_families')) {
      final fam = fr
          ? [
              '-at',
              '-an',
              '-op',
              '-ig',
              '-un',
              '-en',
              '-it',
              '-ap',
              '-ed',
              '-og',
              '-ell',
              '-ake'
            ]
          : [
              '-at',
              '-an',
              '-op',
              '-ig',
              '-un',
              '-en',
              '-it',
              '-ap',
              '-ed',
              '-og',
              '-ell',
              '-ake'
            ];
      final options = fr
          ? {
              '-at': ['chat', 'soleil', 'livre'],
              '-an': ['fan', 'boite', 'stylo'],
              '-op': ['hop', 'arbre', 'lune'],
              '-ig': ['pig', 'etoile', 'tasse'],
              '-un': ['sun', 'chapeau', 'cap'],
              '-en': ['pen', 'main', 'voiture'],
              '-it': ['kit', 'lait', 'porte'],
              '-ap': ['map', 'fleur', 'chaise'],
              '-ed': ['red', 'bleu', 'table'],
              '-og': ['dog', 'nuage', 'papier'],
              '-ell': ['bell', 'voiture', 'mur'],
              '-ake': ['cake', 'pierre', 'rideau'],
            }
          : {
              '-at': ['cat', 'sun', 'book'],
              '-an': ['fan', 'box', 'pen'],
              '-op': ['hop', 'tree', 'moon'],
              '-ig': ['pig', 'star', 'cup'],
              '-un': ['sun', 'hat', 'cap'],
              '-en': ['pen', 'lamp', 'car'],
              '-it': ['kit', 'ship', 'dog'],
              '-ap': ['map', 'flower', 'chair'],
              '-ed': ['red', 'blue', 'table'],
              '-og': ['dog', 'cloud', 'paper'],
              '-ell': ['bell', 'window', 'stone'],
              '-ake': ['cake', 'door', 'leaf'],
            };
      return List.generate(10, (i) {
        final key = fam[(lessonNo + i) % fam.length];
        final row = options[key]!;
        return {
          'prompt': fr
              ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Choisis un mot de la famille $key."
              : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Choose a word from family $key.",
          'choices': [row[0], row[1], row[2]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('measurement_time')) {
      final rows = fr
          ? [
              ['Un metre mesure...', 'la longueur', 'le son', 'la couleur'],
              [
                'On lit l heure avec...',
                'une horloge',
                'une brosse',
                'une tasse'
              ],
              ['Lequel est plus long ?', 'crayon', 'gomme', 'piece'],
              ['Le matin, on...', 'se reveille', 'dort', 'eteint le soleil'],
              ['Une semaine a...', '7 jours', '5 jours', '10 jours'],
              ['Un kilo mesure...', 'la masse', 'la temperature', 'la lumiere'],
              ['Une heure a...', '60 minutes', '30 minutes', '100 minutes'],
              ['Le soir, on voit souvent...', 'la lune', 'le soleil de midi', 'un arc en ciel noir'],
              ['Quel outil mesure une longueur ?', 'regle', 'cuillere', 'gomme'],
              ['Quel moment vient apres midi ?', 'apres midi', 'matin', 'nuit debut'],
              ['Pour mesurer un livre, tu utilises...', 'centimetres', 'litres', 'watts'],
              ['Quel intervalle est le plus court ?', '1 minute', '1 heure', '1 jour'],
            ]
          : [
              ['A meter measures...', 'length', 'sound', 'color'],
              ['We read time with...', 'a clock', 'a brush', 'a cup'],
              ['Which is usually longer?', 'pencil', 'eraser', 'coin'],
              ['In the morning we...', 'wake up', 'sleep', 'turn off sun'],
              ['A week has...', '7 days', '5 days', '10 days'],
              ['A kilogram measures...', 'mass', 'temperature', 'light'],
              ['One hour has...', '60 minutes', '30 minutes', '100 minutes'],
              ['In the evening we often see...', 'the moon', 'midday sun', 'a black rainbow'],
              ['Which tool measures length?', 'ruler', 'spoon', 'eraser'],
              ['Which part comes after noon?', 'afternoon', 'morning', 'early night'],
              ['To measure a book, you use...', 'centimeters', 'liters', 'watts'],
              ['Which interval is shortest?', '1 minute', '1 hour', '1 day'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('science_world')) {
      final rows = fr
          ? [
              ['De quoi une plante a besoin ?', 'eau', 'plastique', 'fumee'],
              ['Quel animal vit dans l eau ?', 'poisson', 'lion', 'girafe'],
              ['Le soleil donne...', 'lumiere', 'glace', 'nuit'],
              ['Les abeilles font...', 'miel', 'chocolat', 'fromage'],
              [
                'Pour respirer on utilise...',
                'les poumons',
                'les mains',
                'les pieds'
              ],
              ['Un arbre est un etre...', 'vivant', 'en carton', 'metal'],
              ['Lequel est une partie de plante ?', 'racine', 'roue', 'antenne'],
              ['Quand il pleut, on peut voir...', 'des nuages', 'des etoiles de jour', 'de la neige chaude'],
              ['Quel animal pond des oeufs ?', 'poule', 'chat', 'chien'],
              ['Le vent peut...', 'deplacer les feuilles', 'peindre un mur seul', 'allumer une tele'],
              ['Pour grandir, le corps a besoin de...', 'nourriture saine', 'seulement bonbons', 'aucune eau'],
              ['Une graine devient...', 'une plante', 'une pierre', 'du metal'],
            ]
          : [
              ['What does a plant need?', 'water', 'plastic', 'smoke'],
              ['Which animal lives in water?', 'fish', 'lion', 'giraffe'],
              ['The sun gives us...', 'light', 'ice', 'night'],
              ['Bees make...', 'honey', 'chocolate', 'cheese'],
              ['We breathe with...', 'lungs', 'hands', 'feet'],
              ['A tree is a...', 'living thing', 'cardboard', 'metal'],
              ['Which is a plant part?', 'root', 'wheel', 'antenna'],
              ['When it rains we can see...', 'clouds', 'daytime stars', 'hot snow'],
              ['Which animal lays eggs?', 'hen', 'cat', 'dog'],
              ['Wind can...', 'move leaves', 'paint walls alone', 'turn on TV'],
              ['To grow, our body needs...', 'healthy food', 'only candy', 'no water'],
              ['A seed can become...', 'a plant', 'a rock', 'metal'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('nature_animals') ||
        chapterSlug.contains('animals_ecosystems')) {
      final rows = fr
          ? [
              ['Quel animal vit surtout dans la mer ?', 'dauphin', 'cheval', 'lapin'],
              ['Le desert est l habitat de...', 'chameau', 'pingouin', 'grenouille'],
              ['Un oiseau se deplace souvent en...', 'volant', 'nageant sous terre', 'roulant'],
              ['Quel animal a des rayures ?', 'zebre', 'tortue', 'mouton'],
              ['Les poissons respirent avec...', 'branchies', 'ailes', 'sabots'],
              ['Quel habitat est tres froid ?', 'region polaire', 'desert chaud', 'jungle tropicale'],
              ['Une chaine alimentaire commence souvent par...', 'plante', 'voiture', 'rocher peint'],
              ['Quel animal est un insecte ?', 'abeille', 'chat', 'vache'],
              ['Les abeilles aident les fleurs en...', 'pollinisant', 'gelant', 'sechant'],
              ['Quel animal hiberne souvent ?', 'ours', 'poule', 'chevre'],
              ['Un ecosysteme est...', 'des etres vivants et leur milieu', 'seulement des jouets', 'juste une route'],
              ['Quel animal vit dans la ferme ?', 'vache', 'requin', 'dauphin'],
            ]
          : [
              ['Which animal lives mostly in the sea?', 'dolphin', 'horse', 'rabbit'],
              ['The desert is home to a...', 'camel', 'penguin', 'frog'],
              ['A bird often moves by...', 'flying', 'digging underwater', 'rolling'],
              ['Which animal has stripes?', 'zebra', 'turtle', 'sheep'],
              ['Fish breathe with...', 'gills', 'wings', 'hooves'],
              ['Which habitat is very cold?', 'polar region', 'hot desert', 'tropical jungle'],
              ['A food chain often starts with a...', 'plant', 'car', 'painted rock'],
              ['Which animal is an insect?', 'bee', 'cat', 'cow'],
              ['Bees help flowers by...', 'pollinating', 'freezing', 'drying'],
              ['Which animal often hibernates?', 'bear', 'hen', 'goat'],
              ['An ecosystem is...', 'living things and their environment', 'only toys', 'just one road'],
              ['Which animal lives on a farm?', 'cow', 'shark', 'dolphin'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('body_parts_senses') ||
        chapterSlug.contains('body_senses_health')) {
      final rows = fr
          ? [
              ['On voit avec...', 'les yeux', 'les oreilles', 'les coudes'],
              ['On entend avec...', 'les oreilles', 'les genoux', 'les cheveux'],
              ['On sent avec...', 'le nez', 'les doigts', 'les epaules'],
              ['On goute avec...', 'la langue', 'le pied', 'le coude'],
              ['On touche avec...', 'la peau', 'les dents', 'les cils'],
              ['Pour courir, on utilise surtout...', 'les jambes', 'les oreilles', 'les sourcils'],
              ['Pour attraper un ballon, on utilise...', 'les mains', 'les chevilles', 'les dents'],
              ['Quel organe aide a penser ?', 'cerveau', 'ongle', 'chaussure'],
              ['Pour garder des dents saines, on...', 'se brosse les dents', 'mange des crayons', 'evite l eau'],
              ['Quel sens aide a reconnaitre une chanson ?', 'ouie', 'odorat', 'toucher'],
              ['Quel sens aide a sentir un parfum ?', 'odorat', 'vue', 'gout'],
              ['Le coeur aide a...', 'faire circuler le sang', 'faire pousser les cheveux', 'fabriquer des chaussures'],
            ]
          : [
              ['We see with...', 'eyes', 'ears', 'elbows'],
              ['We hear with...', 'ears', 'knees', 'hair'],
              ['We smell with...', 'nose', 'fingers', 'shoulders'],
              ['We taste with...', 'tongue', 'foot', 'elbow'],
              ['We touch with...', 'skin', 'teeth', 'eyelashes'],
              ['To run, we mainly use...', 'legs', 'ears', 'eyebrows'],
              ['To catch a ball, we use...', 'hands', 'ankles', 'teeth'],
              ['Which organ helps us think?', 'brain', 'nail', 'shoe'],
              ['To keep teeth healthy, we...', 'brush teeth', 'eat crayons', 'avoid water'],
              ['Which sense helps us know a song?', 'hearing', 'smell', 'touch'],
              ['Which sense helps us smell perfume?', 'smell', 'sight', 'taste'],
              ['The heart helps to...', 'pump blood', 'grow hair', 'make shoes'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('world_shape_path') ||
        chapterSlug.contains('world_geography')) {
      final rows = fr
          ? [
              ['La Terre ressemble surtout a...', 'une sphere', 'un cube', 'une ligne'],
              ['Sur une carte du monde, le bleu montre...', 'les oceans', 'les deserts', 'les routes'],
              ['Un globe est...', 'une maquette ronde de la Terre', 'une regle', 'un tableau'],
              ['Les grandes terres du monde sont des...', 'continents', 'chaises', 'fenetres'],
              ['Pour trouver un pays sur la carte, on regarde...', 'sa position', 'la meteo seulement', 'sa chanson'],
              ['La ligne de l equateur se trouve...', 'au milieu de la Terre', 'au pole nord', 'dans la mer seulement'],
              ['Le Sahara est surtout...', 'un desert', 'un ocean', 'une montagne glacee'],
              ['L Afrique est un...', 'continent', 'village', 'planete'],
              ['L ocean Pacifique est...', 'un grand ocean', 'une petite rue', 'un jouet'],
              ['Un itineraire de voyage montre...', 'des etapes dans un ordre', 'des couleurs au hasard', 'seulement des chiffres'],
              ['Sur le globe, les poles sont...', 'en haut et en bas', 'au centre', 'sur la lune'],
              ['Pour proteger notre monde, on peut...', 'recycler et economiser l eau', 'jeter partout', 'gaspiller'],
            ]
          : [
              ['Earth is mostly shaped like...', 'a sphere', 'a cube', 'a line'],
              ['On a world map, blue shows...', 'oceans', 'deserts', 'roads'],
              ['A globe is...', 'a round model of Earth', 'a ruler', 'a board'],
              ['Large land areas are called...', 'continents', 'chairs', 'windows'],
              ['To find a country on a map, we check...', 'its location', 'weather only', 'its song'],
              ['The equator is located...', 'around the middle of Earth', 'at the North Pole', 'inside one sea'],
              ['The Sahara is mostly...', 'a desert', 'an ocean', 'an icy mountain'],
              ['Africa is a...', 'continent', 'village', 'planet'],
              ['The Pacific is...', 'a major ocean', 'a small street', 'a toy'],
              ['A travel route shows...', 'steps in order', 'random colors', 'only numbers'],
              ['On a globe, the poles are...', 'at top and bottom', 'in the center', 'on the moon'],
              ['To protect our world, we can...', 'recycle and save water', 'throw trash everywhere', 'waste resources'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('history_culture')) {
      final rows = fr
          ? [
              ['L histoire etudie...', 'le passe', 'seulement demain', 'les nuages'],
              ['Une frise chronologique montre...', 'des evenements dans l ordre', 'des dessins au hasard', 'des recettes'],
              ['Les musees gardent souvent...', 'des objets anciens', 'des nuages', 'des voitures en papier'],
              ['Un monument raconte souvent...', 'une partie de l histoire', 'un jeu video', 'une blague'],
              ['Une tradition familiale est...', 'une habitude transmise', 'un bruit fort', 'un test de maths'],
              ['Quand on compare hier et aujourd hui, on...', 'observe les changements', 'ignore tout', 'ferme les yeux'],
              ['Une source historique peut etre...', 'une photo ancienne', 'un baton de colle', 'un jouet neuf'],
              ['Le respect des cultures veut dire...', 'ecouter et apprendre', 'se moquer', 'copier sans comprendre'],
              ['Un archeologue cherche...', 'des traces du passe', 'des bonbons caches', 'des nuages roses'],
              ['Pourquoi apprendre l histoire ?', 'pour comprendre le present', 'pour oublier les autres', 'pour arreter de lire'],
              ['Un symbole national represente...', 'un pays ou une culture', 'une couleur seule', 'un nombre secret'],
              ['Un ancien outil montre...', 'comment vivaient les gens avant', 'la meteo de demain', 'une chanson au hasard'],
            ]
          : [
              ['History studies...', 'the past', 'only tomorrow', 'clouds'],
              ['A timeline shows...', 'events in order', 'random drawings', 'recipes'],
              ['Museums often keep...', 'objects from long ago', 'clouds', 'paper cars'],
              ['A monument often tells...', 'part of history', 'a video game', 'a joke'],
              ['A family tradition is...', 'a habit passed down', 'a loud sound', 'a math test'],
              ['When comparing past and present, we...', 'notice changes', 'ignore everything', 'close our eyes'],
              ['A historical source can be...', 'an old photo', 'a glue stick', 'a new toy'],
              ['Respecting cultures means...', 'listening and learning', 'making fun', 'copying without understanding'],
              ['An archaeologist looks for...', 'clues from the past', 'hidden candy', 'pink clouds'],
              ['Why learn history?', 'to understand today', 'to forget others', 'to stop reading'],
              ['A national symbol represents...', 'a country or culture', 'just a color', 'a secret number'],
              ['An old tool can show...', 'how people lived before', 'tomorrow weather', 'a random song'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    if (chapterSlug.contains('arts_creativity')) {
      final rows = fr
          ? [
              ['Si on melange bleu et jaune, on obtient...', 'vert', 'rouge', 'noir'],
              ['Une ligne courbe est...', 'arrondie', 'droite', 'invisible'],
              ['Un collage utilise souvent...', 'papier colle', 'eau de mer', 'sable chaud'],
              ['Pour un rythme en art visuel, on...', 'repete des formes', 'efface tout', 'dessine une fois'],
              ['Une couleur chaude est...', 'orange', 'bleu', 'violet froid'],
              ['Une couleur froide est...', 'bleu', 'orange', 'jaune feu'],
              ['Un portrait montre surtout...', 'un visage', 'une montagne', 'une route'],
              ['L ombre rend un dessin...', 'plus en volume', 'plus plat', 'sans couleur toujours'],
              ['Une texture peut etre...', 'lisse ou rugueuse', 'seulement rouge', 'toujours ronde'],
              ['Un motif est...', 'un dessin qui se repete', 'un nombre cache', 'une gomme'],
              ['En art, creer veut dire...', 'imaginer puis fabriquer', 'copier sans regarder', 'arreter vite'],
              ['Signer son oeuvre, c est...', 'mettre son nom', 'effacer le dessin', 'changer de feuille'],
            ]
          : [
              ['If we mix blue and yellow, we get...', 'green', 'red', 'black'],
              ['A curved line is...', 'rounded', 'straight', 'invisible'],
              ['A collage often uses...', 'glued paper pieces', 'sea water', 'hot sand'],
              ['To create rhythm in art, we...', 'repeat shapes', 'erase all', 'draw once only'],
              ['A warm color is...', 'orange', 'blue', 'cool violet'],
              ['A cool color is...', 'blue', 'orange', 'sun yellow'],
              ['A portrait mainly shows...', 'a face', 'a mountain', 'a road'],
              ['Shading makes a drawing...', 'look more 3D', 'look flatter', 'always colorless'],
              ['A texture can be...', 'smooth or rough', 'only red', 'always round'],
              ['A pattern is...', 'a repeated design', 'a hidden number', 'an eraser'],
              ['In art, creating means...', 'imagining then making', 'copying blindly', 'stopping quickly'],
              ['Signing artwork means...', 'adding your name', 'erasing it', 'changing paper'],
            ];
      return List.generate(10, (i) {
        final row = rows[(lessonNo + i) % rows.length];
        return {
          'prompt':
              "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}${row[0]}",
          'choices': [row[1], row[2], row[3]],
          'answerIndex': 0,
        };
      });
    }

    final begin = fr
        ? [
            ['m', 'maman', 'soleil', 'chat'],
            ['s', 'avion', 'savon', 'balle'],
            ['b', 'balle', 'table', 'orange'],
            ['t', 'poisson', 'table', 'lune'],
            ['c', 'chien', 'bus', 'lait'],
            ['p', 'porte', 'nuage', 'arbre'],
            ['l', 'lune', 'pomme', 'bus'],
            ['f', 'fleur', 'train', 'gomme'],
            ['r', 'robe', 'chien', 'velo'],
            ['n', 'nuage', 'table', 'sac'],
            ['d', 'dent', 'mouton', 'chat'],
            ['v', 'velo', 'lampe', 'tasse'],
          ]
        : [
            ['m', 'moon', 'sun', 'cat'],
            ['s', 'apple', 'soap', 'bird'],
            ['b', 'ball', 'tree', 'orange'],
            ['t', 'fish', 'table', 'moon'],
            ['c', 'cat', 'sun', 'book'],
            ['p', 'pen', 'cloud', 'tree'],
            ['l', 'lamp', 'apple', 'bus'],
            ['f', 'frog', 'train', 'cup'],
            ['r', 'rain', 'dog', 'shoe'],
            ['n', 'nest', 'table', 'star'],
            ['d', 'dog', 'moon', 'leaf'],
            ['v', 'van', 'book', 'chair'],
          ];
    return List.generate(10, (i) {
      final row = begin[(lessonNo + i) % begin.length];
      return {
        'prompt': fr
            ? "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Quel mot commence par ${row[0]} ?"
            : "${_exercisePrefix(fr, lessonNo, i, chapterSlug: chapterSlug)}Which word starts with ${row[0]}?",
        'choices': [row[1], row[2], row[3]],
        'answerIndex': 0,
      };
    });
  }

  Future<Map<String, dynamic>> loadReadingMonth(
      String lang, String assetFile) async {
    final raw =
        await rootBundle.loadString('assets/reading_month/$lang/$assetFile');
    return (json.decode(raw) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> loadGamePack(
      String lang, String assetFile) async {
    final raw = await rootBundle.loadString('assets/games/$lang/$assetFile');
    return (json.decode(raw) as Map).cast<String, dynamic>();
  }

  /// Import a JSON file provided by the user.  The [fileName] should be the
  /// desired name within the lessons directory (for example
  /// `k_world3.json` or `worlds_manifest.json`).
  ///
  /// Existing files are overwritten.  After writing the file we bump
  /// [contentVersion] so listeners (screens) can refresh.
  Future<void> importLessonJson(
      String lang, String fileName, Map<String, dynamic> jsonData) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Import JSON is not available on web yet. Use bundled assets.');
    }
    final dir = await _localLessonDir(lang);
    final file = File('${dir.path}/$fileName');
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
    contentVersion.value++;
  }
}
