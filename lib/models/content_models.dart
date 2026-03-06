class WorldsManifest {
  final List<WorldRef> worlds;
  WorldsManifest({required this.worlds});

  factory WorldsManifest.fromJson(Map<String, dynamic> json) {
    final items = (json['worlds'] as List).cast<Map<String, dynamic>>();
    return WorldsManifest(
      worlds: items.map((e) => WorldRef.fromJson(e)).toList(),
    );
  }
}

class WorldRef {
  final String id;
  final String title;
  final String ageBand; // "Pre-K" or "K"
  final String coverEmoji;
  final String file; // JSON file path (asset relative)

  WorldRef({
    required this.id,
    required this.title,
    required this.ageBand,
    required this.coverEmoji,
    required this.file,
  });

  factory WorldRef.fromJson(Map<String, dynamic> json) => WorldRef(
        id: json['id'],
        title: json['title'],
        ageBand: json['ageBand'],
        coverEmoji: json['coverEmoji'] ?? 'globe',
        file: json['file'],
      );
}

class World {
  final String id;
  final String title;
  final String description;
  final String ageBand;
  final List<UnitRef> units;

  World({
    required this.id,
    required this.title,
    required this.description,
    required this.ageBand,
    required this.units,
  });

  factory World.fromJson(Map<String, dynamic> json) {
    final units = (json['units'] as List).cast<Map<String, dynamic>>();
    return World(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ageBand: json['ageBand'],
      units: units.map((e) => UnitRef.fromJson(e)).toList(),
    );
  }
}

class UnitRef {
  final String id;
  final String title;
  final String subject; // "Literacy", "Math", etc.
  final String file; // JSON file path (asset relative)

  UnitRef({
    required this.id,
    required this.title,
    required this.subject,
    required this.file,
  });

  factory UnitRef.fromJson(Map<String, dynamic> json) => UnitRef(
        id: json['id'],
        title: json['title'],
        subject: json['subject'],
        file: json['file'],
      );
}

class Unit {
  final String id;
  final String title;
  final String subject;
  final List<LessonRef> lessons;

  Unit({
    required this.id,
    required this.title,
    required this.subject,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    final lessons = (json['lessons'] as List).cast<Map<String, dynamic>>();
    return Unit(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      lessons: lessons.map((e) => LessonRef.fromJson(e)).toList(),
    );
  }
}

class LessonRef {
  final String id;
  final String title;
  final String type; // "lesson" | "worksheet" | "game"
  final String file;

  LessonRef({
    required this.id,
    required this.title,
    required this.type,
    required this.file,
  });

  factory LessonRef.fromJson(Map<String, dynamic> json) => LessonRef(
        id: json['id'],
        title: json['title'],
        type: json['type'],
        file: json['file'],
      );
}

class Lesson {
  final String id;
  final String title;
  final String objective;
  final List<LessonStep> steps;

  Lesson({
    required this.id,
    required this.title,
    required this.objective,
    required this.steps,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List).cast<Map<String, dynamic>>();
    return Lesson(
      id: json['id'],
      title: json['title'],
      objective: json['objective'],
      steps: steps.map((e) => LessonStep.fromJson(e)).toList(),
    );
  }
}

class LessonStep {
  final String kind; // "info" | "mcq" | "match" | "prompt" | "draw"
  final Map<String, dynamic> data;

  LessonStep({required this.kind, required this.data});

  factory LessonStep.fromJson(Map<String, dynamic> json) => LessonStep(
        kind: json['kind'],
        data: (json['data'] as Map).cast<String, dynamic>(),
      );
}

