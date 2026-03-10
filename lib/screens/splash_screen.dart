import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../widgets/app_brand.dart';
import 'home_screen.dart';
import 'language_screen.dart';

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
    if (lang != 'en' && lang != 'fr') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(initialLang: lang)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrand(
              subtitle: 'Offline Pre-K & K Learning',
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
