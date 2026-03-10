import 'package:flutter/material.dart';

import '../services/lesson_repository.dart';
import '../services/progress_store.dart';
import '../widgets/app_brand.dart';
import 'language_screen.dart';
import 'reading_month_screen.dart';
import 'settings_screen.dart';
import 'worksheet_builder_screen.dart';
import 'world_screen.dart';

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
  final repo = LessonRepository();
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    lang = widget.initialLang;
    pages = [
      WorldScreen(lang: lang),
      WorksheetBuilderScreen(lang: lang),
      ReadingMonthScreen(lang: lang),
      SettingsScreen(
        lang: lang,
        onChangeLang: _handleChangeLang,
      ),
    ];
    repo.warmHomeContent(lang);
  }

  Future<void> _handleChangeLang() async {
    await store.setLanguage('');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
    );
  }

  void _onTab(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const AppBrand(compact: true),
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _onTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.route),
            label: lang == 'fr' ? 'Parcours' : 'Path',
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_document),
            label: lang == 'fr' ? 'Fiches' : 'Worksheets',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book),
            label: lang == 'fr' ? 'Lecture' : 'Reading',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: lang == 'fr' ? 'Reglages' : 'Settings',
          ),
        ],
      ),
    );
  }
}
