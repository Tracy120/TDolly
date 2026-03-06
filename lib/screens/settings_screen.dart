import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../services/progress_store.dart';
import '../services/lesson_repository.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  final String lang;
  final Future<void> Function() onChangeLang;

  const SettingsScreen(
      {super.key, required this.lang, required this.onChangeLang});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final store = ProgressStore();
  final repo = LessonRepository();
  bool voiceOn = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    voiceOn = await store.getVoiceOn();
    if (mounted) setState(() {});
  }

  Future<void> _importLesson() async {
    final t = widget.lang;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final selected = result.files.single.path;
    if (selected == null) return;

    try {
      final file = File(selected);
      final text = await file.readAsString();
      final data = json.decode(text);
      if (data is! Map<String, dynamic>) {
        throw Exception('JSON must be an object');
      }
      final name = path.basename(file.path);
      await repo.importLessonJson(widget.lang, name, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  t == 'fr' ? 'Importation réussie' : 'Import successful')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t == 'fr' ? 'Erreur: $e' : 'Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.lang;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t == 'fr' ? "Réglages" : "Settings",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DollyCard(
          child: SwitchListTile(
            value: voiceOn,
            onChanged: (v) async {
              setState(() => voiceOn = v);
              await store.setVoiceOn(v);
            },
            title: Text(t == 'fr' ? "Assistante vocale" : "Voice Assistant"),
            subtitle: Text(t == 'fr'
                ? "Aide pour prononciation et guidance."
                : "Guidance for pronunciation and learning."),
          ),
        ),
        const SizedBox(height: 12),
        DollyCard(
          onTap: () => widget.onChangeLang(),
          child: Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t == 'fr' ? "Changer la langue" : "Change language",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DollyCard(
          child: Text(
            t == 'fr'
                ? "Tout le contenu est stocké hors‑ligne dans le dossier assets."
                : "All content is stored offline inside the assets folder.",
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
        const SizedBox(height: 12),
        if (!kIsWeb)
          DollyCard(
            onTap: _importLesson,
            child: Row(
              children: [
                const Icon(Icons.upload_file),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t == 'fr' ? "Importer un fichier JSON" : "Import JSON file",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        if (kIsWeb)
          DollyCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t == 'fr'
                        ? "Import JSON non disponible sur Web."
                        : "JSON import is not available on Web.",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        DollyCard(
          child: Row(
            children: [
              const Icon(Icons.route),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t == 'fr'
                      ? "Utilise Parcours pour les ressources enfants"
                      : "Use Path for kid resources",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
