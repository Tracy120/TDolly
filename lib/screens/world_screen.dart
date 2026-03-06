import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../services/lesson_repository.dart';
import '../widgets/ui.dart';
import 'unit_screen.dart';

class WorldScreen extends StatefulWidget {
  final String lang;
  const WorldScreen({super.key, required this.lang});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  final repo = LessonRepository();
  late Future<WorldsManifest> future;
  String _ageFilter = 'All';

  IconData _worldIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('game')) return Icons.sports_esports;
    if (t.contains('music')) return Icons.music_note;
    if (t.contains('science')) return Icons.science_outlined;
    if (t.contains('read') || t.contains('story')) return Icons.menu_book;
    if (t.contains('math') || t.contains('number')) return Icons.calculate;
    return Icons.public;
  }

  @override
  void initState() {
    super.initState();
    future = repo.loadManifest(widget.lang);
    repo.contentVersion.addListener(_reloadManifest);
  }

  void _reloadManifest() {
    setState(() {
      future = repo.loadManifest(widget.lang);
    });
  }

  @override
  void dispose() {
    repo.contentVersion.removeListener(_reloadManifest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorldsManifest>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 34),
                  const SizedBox(height: 10),
                  Text(
                    widget.lang == 'fr'
                        ? "Impossible de charger les parcours."
                        : "Could not load Path content.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'fr'
                        ? "Verifie les fichiers JSON importes puis reessaie."
                        : "Check imported JSON files and try again.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final worlds = snap.data!.worlds;
        final filters =
            <String>{'All', ...worlds.map((w) => w.ageBand)}.toList();
        final filtered = _ageFilter == 'All'
            ? worlds
            : worlds
                .where((w) => w.ageBand.toLowerCase() == _ageFilter.toLowerCase())
                .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.lang == 'fr' ? "Choisis un monde" : "Choose a world",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = filters[i];
                  return ChoiceChip(
                    label: Text(f),
                    selected: _ageFilter == f,
                    onSelected: (_) => setState(() => _ageFilter = f),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ...filtered.map((wref) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DollyCard(
                  onTap: () async {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnitScreen(
                          lang: widget.lang,
                          worldRef: wref,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EEFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _worldIcon(wref.title),
                          size: 26,
                          color: const Color(0xFF3E66D9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wref.title,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              DollyChip(wref.ageBand),
                              DollyChip(widget.lang == 'fr'
                                  ? "Hors-ligne"
                                  : "Offline"),
                            ]),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            }),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  widget.lang == 'fr'
                      ? "Aucun monde pour ce filtre."
                      : "No worlds available for this filter.",
                ),
              ),
          ],
        );
      },
    );
  }
}

