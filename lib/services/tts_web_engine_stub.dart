class WebTtsEngine {
  bool get supported => false;

  Future<void> init({required String lang}) async {}

  Future<void> speak(String text) async {}

  Future<void> stop() async {}
}

WebTtsEngine createWebTtsEngine() => WebTtsEngine();
