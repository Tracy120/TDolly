import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> _localLessonDir(String lang) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/lessons/$lang');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<String?> readLocalLessonString(String lang, String fileName) async {
  final dir = await _localLessonDir(lang);
  final file = File('${dir.path}/$fileName');
  if (!await file.exists()) {
    return null;
  }
  return file.readAsString();
}

Future<void> writeLocalLessonString(
  String lang,
  String fileName,
  String contents,
) async {
  final dir = await _localLessonDir(lang);
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(contents);
}
