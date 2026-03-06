import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import 'language_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _store = ProgressStore();

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final lang = await _store.getLanguage();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    // If language not set before, show picker; otherwise go home.
    if (lang != 'en' && lang != 'fr') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(initialLang: lang)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("TeacherDolly", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text("Offline Pre‑K & K Learning", style: TextStyle(fontSize: 14)),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
