import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter framework error: ${details.exception}');
        debugPrintStack(stackTrace: details.stack);
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('Uncaught app error: $error');
        debugPrintStack(stackTrace: stack);
        return false;
      };

      runApp(const TeacherDollyApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Zone error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class TeacherDollyApp extends StatelessWidget {
  const TeacherDollyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeacherDolly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const SplashScreen(),
    );
  }
}
