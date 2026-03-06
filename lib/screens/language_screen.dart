import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import 'home_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore();

    Future<void> pick(String lang) async {
      await store.setLanguage(lang);
      if (!context.mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(initialLang: lang)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Choose language")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("Pick learning language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 22)),
              title: const Text("English"),
              subtitle: const Text("Pre‑K and Kindergarten"),
              onTap: () => pick('en'),
            ),
            const Divider(),
            ListTile(
              leading: const Text("🇫🇷", style: TextStyle(fontSize: 22)),
              title: const Text("Français"),
              subtitle: const Text("Pré‑K et Maternelle"),
              onTap: () => pick('fr'),
            ),
          ],
        ),
      ),
    );
  }
}
