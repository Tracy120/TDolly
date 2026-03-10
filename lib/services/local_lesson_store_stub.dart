Future<String?> readLocalLessonString(String lang, String fileName) async {
  return null;
}

Future<void> writeLocalLessonString(
  String lang,
  String fileName,
  String contents,
) async {
  throw UnsupportedError(
    'Local lesson storage is not available on this platform.',
  );
}
