import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import 'world_screen.dart';
import 'worksheet_builder_screen.dart';
import 'reading_month_screen.dart';
import 'settings_screen.dart';
import 'language_screen.dart';

class HomeScreen extends StatefulWidget {
  final String initialLang;
  const HomeScreen({super.key, required this.initialLang});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  late String lang;
  final store = ProgressStore();

  @override
  void initState() {
    super.initState();
    lang = widget.initialLang;
  }

  void _onTab(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      WorldScreen(lang: lang),
      WorksheetBuilderScreen(lang: lang),
      ReadingMonthScreen(lang: lang),
      SettingsScreen(
        lang: lang,
        onChangeLang: () async {
          await store.setLanguage(''); // force picker
          if (!context.mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'fr' ? "TeacherDolly (Hors‑ligne)" : "TeacherDolly (Offline)"),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.route), label: lang == 'fr' ? "Parcours" : "Path"),
          NavigationDestination(icon: const Icon(Icons.edit_document), label: lang == 'fr' ? "Fiches" : "Worksheets"),
          NavigationDestination(icon: const Icon(Icons.menu_book), label: lang == 'fr' ? "Lecture" : "Reading"),
          NavigationDestination(icon: const Icon(Icons.settings), label: lang == 'fr' ? "Réglages" : "Settings"),
        ],
      ),
    );
  }
}
