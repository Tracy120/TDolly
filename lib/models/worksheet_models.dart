class InteractiveWorksheetManifest {
  final List<InteractiveWorksheetRef> worksheets;

  const InteractiveWorksheetManifest({required this.worksheets});

  factory InteractiveWorksheetManifest.fromJson(Map<String, dynamic> json) {
    final items = (json['worksheets'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return InteractiveWorksheetManifest(
      worksheets: items.map(InteractiveWorksheetRef.fromJson).toList(),
    );
  }
}

class InteractiveWorksheetRef {
  final String id;
  final String title;
  final String subtitle;
  final String level;
  final String type;
  final String file;
  final String accent;

  const InteractiveWorksheetRef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.type,
    required this.file,
    required this.accent,
  });

  factory InteractiveWorksheetRef.fromJson(Map<String, dynamic> json) {
    return InteractiveWorksheetRef(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      file: (json['file'] ?? '').toString(),
      accent: (json['accent'] ?? '#7EA5FF').toString(),
    );
  }
}

class InteractiveWorksheet {
  final String id;
  final String title;
  final String subtitle;
  final String level;
  final String type;
  final String instructions;
  final String rewardLabel;
  final List<Map<String, dynamic>> items;

  const InteractiveWorksheet({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.type,
    required this.instructions,
    required this.rewardLabel,
    required this.items,
  });

  factory InteractiveWorksheet.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .cast<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return InteractiveWorksheet(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      rewardLabel: (json['rewardLabel'] ?? 'Stars').toString(),
      items: items,
    );
  }
}
