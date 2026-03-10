import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tts_service.dart';

typedef OnAnswered = void Function(bool correct);

const Size _guidePatternCanvasSize = Size(320, 180);

double _guideFontSizeForTarget(String text) {
  final trimmed = text.trim();
  if (trimmed.length <= 1) return 122;
  if (trimmed.length <= 3) return 104;
  if (trimmed.length <= 6) return 82;
  if (trimmed.length <= 10) return 66;
  return 56;
}

double _guideLetterSpacingForTarget(String text) {
  final trimmed = text.trim();
  if (trimmed.length <= 1) return 0;
  if (trimmed.length <= 4) return 4;
  return trimmed.contains(' ') ? 2 : 1.5;
}

List<Offset> _legacyGuideDotsNormalized(String target) {
  const source = Size(200, 180);

  List<Offset> normalize(List<Offset> points) {
    return points
        .map((point) => Offset(point.dx / source.width, point.dy / source.height))
        .toList();
  }

  switch (target.trim().toUpperCase()) {
    case '1':
      return normalize(const [
        Offset(100, 50),
        Offset(100, 70),
        Offset(100, 90),
        Offset(100, 110),
        Offset(100, 130),
        Offset(100, 150),
      ]);
    case '2':
      return normalize(const [
        Offset(80, 60),
        Offset(90, 50),
        Offset(110, 50),
        Offset(130, 60),
        Offset(130, 80),
        Offset(110, 100),
        Offset(90, 100),
        Offset(80, 110),
      ]);
    case '3':
      return normalize(const [
        Offset(80, 60),
        Offset(100, 50),
        Offset(120, 60),
        Offset(120, 70),
        Offset(100, 80),
        Offset(120, 90),
        Offset(120, 110),
        Offset(100, 120),
        Offset(80, 110),
      ]);
    case '5':
      return normalize(const [
        Offset(120, 50),
        Offset(100, 50),
        Offset(80, 70),
        Offset(80, 80),
        Offset(100, 80),
        Offset(120, 90),
        Offset(120, 110),
        Offset(100, 120),
        Offset(80, 130),
      ]);
    default:
      return const [];
  }
}

Future<List<Offset>> _generateGuideDotsNormalized(String target) async {
  final trimmed = target.trim();
  if (trimmed.isEmpty) return const [];

  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = _guidePatternCanvasSize.width.toInt();
    final height = _guidePatternCanvasSize.height.toInt();

    final textPainter = TextPainter(
      text: TextSpan(
        text: trimmed,
        style: TextStyle(
          fontSize: _guideFontSizeForTarget(trimmed),
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: _guideLetterSpacingForTarget(trimmed),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: trimmed.length > 8 ? 2 : 1,
    )..layout(maxWidth: _guidePatternCanvasSize.width * 0.86);

    final offset = Offset(
      (_guidePatternCanvasSize.width - textPainter.width) / 2,
      (_guidePatternCanvasSize.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) {
      return _legacyGuideDotsNormalized(trimmed);
    }

    final bytes = byteData.buffer.asUint8List();
    final dots = <Offset>[];
    final gridStep = trimmed.length <= 2 ? 7 : 6;

    for (int y = 0; y < height; y += gridStep) {
      for (int x = 0; x < width; x += gridStep) {
        final alpha = bytes[(((y * width) + x) * 4) + 3];
        if (alpha > 20) {
          dots.add(
            Offset(
              x / _guidePatternCanvasSize.width,
              y / _guidePatternCanvasSize.height,
            ),
          );
        }
      }
    }

    return dots.isEmpty ? _legacyGuideDotsNormalized(trimmed) : dots;
  } catch (e) {
    debugPrint('Guide dot generation error for "$trimmed": $e');
    return _legacyGuideDotsNormalized(trimmed);
  }
}

List<String> _voiceChunks(String text, {int maxChars = 220}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return const [];

  final chunks = <String>[];
  var remaining = normalized;
  while (remaining.isNotEmpty) {
    if (remaining.length <= maxChars) {
      chunks.add(remaining);
      break;
    }

    var splitAt = remaining.lastIndexOf('. ', maxChars);
    splitAt = splitAt < 0 ? remaining.lastIndexOf('! ', maxChars) : splitAt;
    splitAt = splitAt < 0 ? remaining.lastIndexOf('? ', maxChars) : splitAt;
    splitAt = splitAt < 0 ? remaining.lastIndexOf(' ', maxChars) : splitAt;
    if (splitAt < 0 || splitAt < maxChars ~/ 2) {
      splitAt = maxChars;
    }

    final chunk = remaining.substring(0, splitAt).trim();
    if (chunk.isNotEmpty) {
      chunks.add(chunk);
    }
    remaining = remaining.substring(splitAt).trim();
  }

  return chunks;
}

String? _localizedAudioFallbackPath(String path, String lang) {
  if (lang != 'fr') return null;
  final normalized = path.trim();
  if (normalized.isEmpty || !normalized.endsWith('_fr.mp3')) return null;
  return normalized.replaceFirst(RegExp(r'_fr(?=\.mp3$)'), '');
}

List<String> _audioCandidatePaths(String path, String lang) {
  final normalized = path.trim();
  if (normalized.isEmpty) return const [];

  final candidates = <String>[normalized];
  final fallback = _localizedAudioFallbackPath(normalized, lang);
  if (fallback != null && fallback != normalized) {
    candidates.add(fallback);
  }
  return candidates;
}

Future<String?> _resolvePlayableAudioAsset(String path, String lang) async {
  for (final candidate in _audioCandidatePaths(path, lang)) {
    try {
      await rootBundle.load('assets/$candidate');
      return candidate;
    } catch (_) {
      // Try the next bundled asset candidate.
    }
  }
  return null;
}

List<Offset> _fitDotsToCanvas(
  List<Offset> sourceDots,
  Size size, {
  double padding = 28,
}) {
  if (sourceDots.isEmpty) return const [];

  double minX = sourceDots.first.dx;
  double maxX = sourceDots.first.dx;
  double minY = sourceDots.first.dy;
  double maxY = sourceDots.first.dy;

  for (final dot in sourceDots.skip(1)) {
    if (dot.dx < minX) minX = dot.dx;
    if (dot.dx > maxX) maxX = dot.dx;
    if (dot.dy < minY) minY = dot.dy;
    if (dot.dy > maxY) maxY = dot.dy;
  }

  final sourceWidth = (maxX - minX).abs().clamp(1, double.infinity);
  final sourceHeight = (maxY - minY).abs().clamp(1, double.infinity);
  final targetWidth = (size.width - (padding * 2)).clamp(80, double.infinity);
  final targetHeight =
      (size.height - (padding * 2)).clamp(80, double.infinity);
  final scale = (targetWidth / sourceWidth) < (targetHeight / sourceHeight)
      ? targetWidth / sourceWidth
      : targetHeight / sourceHeight;

  final contentWidth = sourceWidth * scale;
  final contentHeight = sourceHeight * scale;
  final offsetX = ((size.width - contentWidth) / 2) - (minX * scale);
  final offsetY = ((size.height - contentHeight) / 2) - (minY * scale);

  return sourceDots
      .map((dot) => Offset((dot.dx * scale) + offsetX, (dot.dy * scale) + offsetY))
      .toList();
}

Widget _buildVisualToken(String visual) {
  final token = visual.trim().toLowerCase();
  switch (token) {
    case 'apple':
      return SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0554A),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: Container(
                width: 2,
                height: 8,
                color: const Color(0xFF7A4A2A),
              ),
            ),
            Positioned(
              top: 3,
              left: 18,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 11,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF53A653),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    case 'triangle':
      return const Icon(
        Icons.change_history_rounded,
        size: 30,
        color: Color(0xFF3A78D6),
      );
    case 'hand':
      return const Icon(
        Icons.back_hand_rounded,
        size: 30,
        color: Color(0xFFE29B2F),
      );
    case 'cat':
      return const Icon(
        Icons.pets_rounded,
        size: 30,
        color: Color(0xFF8B5E3C),
      );
    case 'ball':
      return const Icon(
        Icons.sports_baseball_rounded,
        size: 30,
        color: Color(0xFFDE6A57),
      );
    case 'plant':
      return const Icon(
        Icons.local_florist_rounded,
        size: 30,
        color: Color(0xFF47A36B),
      );
    case 'sun':
      return const Icon(
        Icons.wb_sunny_rounded,
        size: 30,
        color: Color(0xFFE2A93B),
      );
    case 'water':
      return const Icon(
        Icons.water_drop_rounded,
        size: 30,
        color: Color(0xFF3F8CE6),
      );
    case 'bird':
      return const Icon(
        Icons.air_rounded,
        size: 30,
        color: Color(0xFF5B87C8),
      );
    case 'caterpillar':
      return const Icon(
        Icons.bug_report_rounded,
        size: 30,
        color: Color(0xFF57A85B),
      );
    case 'butterfly':
      return const Icon(
        Icons.auto_awesome_rounded,
        size: 30,
        color: Color(0xFF9B6AD8),
      );
    case 'letter_m':
      return const Text(
        'M',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4569C7),
        ),
      );
    default:
      return Text(
        visual.trim().isEmpty ? '?' : visual.trim().toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF31527A),
        ),
      );
  }
}

class InfoStep extends StatelessWidget {
  final String text;
  const InfoStep({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, height: 1.35));
  }
}

class PromptStep extends StatefulWidget {
  final String prompt;
  final String hint;
  final bool inputEnabled;
  final String inputLabel;
  final String inputHint;
  final String submitLabel;
  final String displayPrefix;
  final String emptyInputMessage;
  const PromptStep({
    super.key,
    required this.prompt,
    required this.hint,
    this.inputEnabled = false,
    this.inputLabel = '',
    this.inputHint = '',
    this.submitLabel = 'Enter',
    this.displayPrefix = 'You typed:',
    this.emptyInputMessage = 'Please type a response first.',
  });

  @override
  State<PromptStep> createState() => _PromptStepState();
}

class _PromptStepState extends State<PromptStep> {
  final TextEditingController _controller = TextEditingController();
  String _submittedText = '';
  String _errorText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitText() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = widget.emptyInputMessage;
        _submittedText = '';
      });
      return;
    }
    setState(() {
      _submittedText = value;
      _errorText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.prompt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Text(widget.hint, style: const TextStyle(fontSize: 14)),
        ),
        if (widget.inputEnabled) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submitText(),
            decoration: InputDecoration(
              labelText: widget.inputLabel.isEmpty ? null : widget.inputLabel,
              hintText: widget.inputHint.isEmpty ? null : widget.inputHint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitText,
            child: Text(widget.submitLabel),
          ),
          if (_errorText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorText,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_submittedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                "${widget.displayPrefix} $_submittedText",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class McqStep extends StatefulWidget {
  final String question;
  final List<String> choices;
  final int answerIndex;
  final List<String> visuals;
  final OnAnswered onAnswered;

  const McqStep({
    super.key,
    required this.question,
    required this.choices,
    required this.answerIndex,
    this.visuals = const [],
    required this.onAnswered,
  });

  @override
  State<McqStep> createState() => _McqStepState();
}

class _McqStepState extends State<McqStep> {
  int? selected;
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (widget.visuals.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: widget.visuals
                  .map(
                    (visual) => Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: _buildVisualToken(visual),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...List.generate(widget.choices.length, (i) {
          final isSel = selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: locked
                  ? null
                  : () {
                      final ok = i == widget.answerIndex;
                      setState(() {
                        selected = i;
                        if (ok) locked = true;
                      });
                      widget.onAnswered(ok);
                      if (!ok) {
                        Future.delayed(const Duration(milliseconds: 450), () {
                          if (!mounted || locked) return;
                          setState(() => selected = null);
                        });
                      }
                    },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(
                  color: isSel
                      ? (locked ? Colors.green : Colors.orange)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(widget.choices[i], style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  if (isSel && locked) const Icon(Icons.check_circle, size: 18),
                  if (isSel && !locked) const Icon(Icons.refresh, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class MatchStep extends StatefulWidget {
  final String instruction;
  final List<Map<String, String>> pairs; // [{left:"A", right:"Apple"}]
  final OnAnswered onAnswered;

  const MatchStep(
      {super.key,
      required this.instruction,
      required this.pairs,
      required this.onAnswered});

  @override
  State<MatchStep> createState() => _MatchStepState();
}

class _MatchStepState extends State<MatchStep> {
  String? leftPick;
  final Map<String, String> matched = {};
  late List<String> shuffledRights;

  @override
  void initState() {
    super.initState();
    shuffledRights = widget.pairs.map((e) => e['right']!).toList()..shuffle();
  }

  @override
  void didUpdateWidget(covariant MatchStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePairs(oldWidget.pairs, widget.pairs)) {
      shuffledRights = widget.pairs.map((e) => e['right']!).toList()..shuffle();
      matched.clear();
      leftPick = null;
    }
  }

  bool _samePairs(List<Map<String, String>> a, List<Map<String, String>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['left'] != b[i]['left'] || a[i]['right'] != b[i]['right']) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final lefts = widget.pairs.map((e) => e['left']!).toList();

    bool done = matched.length == widget.pairs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.instruction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: lefts.map((l) {
                  final isMatched = matched.containsKey(l);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed:
                          isMatched ? null : () => setState(() => leftPick = l),
                      child: Row(
                        children: [
                          Text(l, style: const TextStyle(fontSize: 15)),
                          const Spacer(),
                          if (isMatched) const Icon(Icons.lock, size: 16),
                          if (!isMatched && leftPick == l)
                            const Icon(Icons.touch_app, size: 16),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: shuffledRights.map((r) {
                  final isUsed = matched.values.contains(r);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: isUsed
                          ? null
                          : () {
                              if (leftPick == null) return;
                              final correct = widget.pairs.any((p) =>
                                  p['left'] == leftPick && p['right'] == r);
                              if (correct) {
                                setState(() {
                                  matched[leftPick!] = r;
                                  leftPick = null;
                                });
                                if (matched.length == widget.pairs.length) {
                                  widget.onAnswered(true);
                                }
                              } else {
                                widget.onAnswered(false);
                              }
                            },
                      child: Row(
                        children: [
                          Text(r, style: const TextStyle(fontSize: 15)),
                          const Spacer(),
                          if (isUsed) const Icon(Icons.lock, size: 16),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (done)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Text("Nice work! You matched them all."),
          ),
      ],
    );
  }
}

class DrawStep extends StatefulWidget {
  final String prompt;
  final String guide;
  final String target;
  final OnAnswered onAnswered;
  final String lang;

  const DrawStep({
    super.key,
    required this.prompt,
    required this.guide,
    required this.target,
    required this.onAnswered,
    required this.lang,
  });

  @override
  State<DrawStep> createState() => _DrawStepState();
}

class _DrawStepState extends State<DrawStep> {
  final List<Offset?> _points = <Offset?>[];
  List<Offset> _normalizedGuideDots = const [];
  bool _donePressed = false;
  int _rating = 0;
  int _guideRequestId = 0;
  Size _boardSize = const Size(320, 220);

  @override
  void initState() {
    super.initState();
    _prepareGuideDots();
  }

  @override
  void didUpdateWidget(covariant DrawStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _prepareGuideDots();
    }
  }

  Future<void> _prepareGuideDots() async {
    final requestId = ++_guideRequestId;
    final dots = await _generateGuideDotsNormalized(widget.target);
    if (!mounted || requestId != _guideRequestId) return;
    setState(() => _normalizedGuideDots = dots);
  }

  List<Offset> _guideDotsFor(Size size) {
    if (_normalizedGuideDots.isEmpty) return const [];
    return _normalizedGuideDots
        .map((dot) => Offset(dot.dx * size.width, dot.dy * size.height))
        .toList();
  }

  void _storeBoardSize(Size size) {
    if ((size.width - _boardSize.width).abs() < 1 &&
        (size.height - _boardSize.height).abs() < 1) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _boardSize = size);
    });
  }

  double get _traceProgress {
    final guideDots = _guideDotsFor(_boardSize);
    if (guideDots.isEmpty) return 0.0;
    int covered = 0;
    for (final dot in guideDots) {
      bool isCovered = _points.any((p) => p != null && (p - dot).distance < 20);
      if (isCovered) covered++;
    }
    return covered / guideDots.length;
  }

  void _addPoint(Offset p) {
    setState(() => _points.add(p));
  }

  void _endStroke() {
    if (_points.isNotEmpty && _points.last != null) {
      setState(() => _points.add(null));
    }
  }

  void _onDone() {
    final progress = _traceProgress;
    int rating;
    if (progress >= 0.9) {
      rating = 5;
    } else if (progress >= 0.7) {
      rating = 4;
    } else if (progress >= 0.5) {
      rating = 3;
    } else if (progress >= 0.3) {
      rating = 2;
    } else {
      rating = 1;
    }
    setState(() {
      _donePressed = true;
      _rating = rating;
    });
    widget.onAnswered(progress >= 0.5); // Pass if at least half covered
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final containerHeight = isSmallScreen ? 180.0 : 220.0;
    final fontSize = isSmallScreen ? 14.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.prompt,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
        if (widget.guide.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(widget.guide, style: const TextStyle(fontSize: 14)),
        ],
        const SizedBox(height: 12),
        Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = Size(
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
                  containerHeight,
                );
                _storeBoardSize(boardSize);
                return GestureDetector(
                  onPanStart:
                      _donePressed ? null : (d) => _addPoint(d.localPosition),
                  onPanUpdate:
                      _donePressed ? null : (d) => _addPoint(d.localPosition),
                  onPanEnd: _donePressed ? null : (_) => _endStroke(),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TraceBoardPainter(
                      points: _points,
                      target: widget.target,
                      guideDots: _guideDotsFor(boardSize),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (!_donePressed) ...[
          LinearProgressIndicator(
            value: _traceProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _traceProgress > 0.5 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(_points.clear),
                icon: const Icon(Icons.refresh),
                label: Text(widget.lang == 'fr' ? 'Effacer' : 'Clear'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _onDone,
                icon: const Icon(Icons.check),
                label: Text(widget.lang == 'fr' ? 'Termine' : 'Done'),
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.lang == 'fr' ? 'Note: $_rating/5' : 'Rating: $_rating/5',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => widget.onAnswered(true),
            icon: const Icon(Icons.arrow_forward),
            label: Text(widget.lang == 'fr' ? 'Continuer' : 'Continue'),
          ),
        ],
      ],
    );
  }
}

class _TraceBoardPainter extends CustomPainter {
  final List<Offset?> points;
  final String target;
  final List<Offset> guideDots;

  _TraceBoardPainter(
      {required this.points, required this.target, required this.guideDots});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF7FAFF);
    canvas.drawRect(Offset.zero & size, bg);

    final guidePaint = Paint()
      ..color = Colors.blueGrey.shade100
      ..strokeWidth = 1;
    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    // Draw guide dots
    final dotPaint = Paint()..color = Colors.blue.shade300;
    for (final dot in guideDots) {
      canvas.drawCircle(dot, guideDots.length > 120 ? 3.2 : 4.8, dotPaint);
    }

    if (target.isNotEmpty && guideDots.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: target,
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: Color(0x22000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final pos =
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2);
      tp.paint(canvas, pos);
    }

    final stroke = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TraceBoardPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.target != target ||
        oldDelegate.guideDots != guideDots;
  }
}

class AudioStep extends StatefulWidget {
  final String title;
  final String audioPath;
  final String lang;
  final String fallbackText;

  const AudioStep({
    super.key,
    required this.title,
    required this.audioPath,
    required this.lang,
    this.fallbackText = '',
  });

  @override
  State<AudioStep> createState() => _AudioStepState();
}

class _AudioStepState extends State<AudioStep> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _tts = TtsService();
  bool _isPlaying = false;
  bool _usingTtsFallback = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
    } catch (e) {
      debugPrint('Audio player init error: $e');
    }
  }

  @override
  void deactivate() {
    _tts.stop();
    _audioPlayer.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _errorMessage = null;
        _usingTtsFallback = false;
        _statusIsError = false;
      });
      final playablePath =
          await _resolvePlayableAudioAsset(widget.audioPath, widget.lang);
      if (playablePath == null) {
        throw StateError('Missing bundled audio asset: ${widget.audioPath}');
      }
      await _audioPlayer.play(AssetSource(playablePath));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      if (widget.fallbackText.trim().isNotEmpty) {
        await _playVoiceFallback(widget.fallbackText);
        return;
      }
      setState(() {
        _statusIsError = true;
        _errorMessage = widget.lang == 'fr'
            ? 'Fichier audio absent. Ajoute le MP3 ou utilise la lecture vocale.'
            : 'Audio file missing. Add the MP3 or use voice playback.';
      });
    }
  }

  Future<void> _pauseAudio() async {
    try {
      if (_usingTtsFallback) {
        await _tts.stop();
        if (mounted) {
          setState(() => _isPlaying = false);
        }
        return;
      }
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Audio pause error: $e');
    }
  }

  Future<void> _playVoiceFallback(String text) async {
    try {
      setState(() {
        _usingTtsFallback = true;
        _isPlaying = true;
        _statusIsError = false;
        _errorMessage = widget.lang == 'fr'
            ? 'Lecture vocale en cours. Le MP3 n est pas encore inclus.'
            : 'Playing with built-in voice. The MP3 is not bundled yet.';
      });
      await _tts.init(lang: widget.lang);
      _tts.registerUserInteraction();
      for (final chunk in _voiceChunks(text)) {
        await _tts.speak(chunk, fromUserAction: true);
      }
    } catch (e) {
      debugPrint('Audio voice fallback error: $e');
      if (mounted) {
        setState(() {
          _statusIsError = true;
          _errorMessage = widget.lang == 'fr'
              ? 'Lecture vocale indisponible.'
              : 'Voice fallback unavailable.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDuration = _duration.inSeconds > 0 && !_usingTtsFallback;
    final sliderMax = hasDuration ? _duration.inSeconds.toDouble() : 1.0;
    final sliderValue = _position.inSeconds
        .clamp(0, hasDuration ? _duration.inSeconds : 1)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_isPlaying) {
                        await _pauseAudio();
                      } else {
                        await _playAudio();
                      }
                    },
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 32,
                  ),
                  Expanded(
                    child: Slider(
                      value: sliderValue,
                      max: sliderMax,
                      onChanged: hasDuration
                          ? (value) async {
                              await _audioPlayer
                                  .seek(Duration(seconds: value.toInt()));
                            }
                          : null,
                    ),
                  ),
                  Text(
                      '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.lang == 'fr'
                    ? 'Ecoute la chanson et amuse-toi!'
                    : 'Listen to the song and enjoy!',
                style: const TextStyle(fontSize: 16),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusIsError
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusIsError
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: _statusIsError
                          ? Colors.red.shade700
                          : Colors.blue.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class StoryStep extends StatefulWidget {
  final String title;
  final String text;
  final String? audioPath;
  final String lang;

  const StoryStep({
    super.key,
    required this.title,
    required this.text,
    this.audioPath,
    required this.lang,
  });

  @override
  State<StoryStep> createState() => _StoryStepState();
}

class _StoryStepState extends State<StoryStep> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _tts = TtsService();
  bool _isPlaying = false;
  bool _usingTtsFallback = false;
  String? _errorMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
    } catch (e) {
      debugPrint('Story audio player init error: $e');
    }
  }

  @override
  void deactivate() {
    _tts.stop();
    _audioPlayer.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playStoryAudio() async {
    try {
      if ((widget.audioPath ?? '').isNotEmpty) {
        setState(() {
          _errorMessage = null;
          _usingTtsFallback = false;
          _statusIsError = false;
        });
        final playablePath = await _resolvePlayableAudioAsset(
          widget.audioPath!,
          widget.lang,
        );
        if (playablePath == null) {
          throw StateError(
            'Missing bundled story audio asset: ${widget.audioPath}',
          );
        }
        await _audioPlayer.play(AssetSource(playablePath));
        return;
      }
      await _playStoryFallback();
    } catch (e) {
      debugPrint('Story audio playback error: $e');
      await _playStoryFallback();
    }
  }

  Future<void> _playStoryFallback() async {
    final storyText = widget.text.trim();
    if (storyText.isEmpty) {
      setState(() {
        _statusIsError = true;
        _errorMessage = widget.lang == 'fr'
            ? 'Histoire indisponible.'
            : 'Story text unavailable.';
      });
      return;
    }
    try {
      setState(() {
        _usingTtsFallback = true;
        _isPlaying = true;
        _statusIsError = false;
        _errorMessage = widget.lang == 'fr'
            ? 'Lecture vocale en cours pour raconter l histoire.'
            : 'Playing the story with built-in voice.';
      });
      await _tts.init(lang: widget.lang);
      _tts.registerUserInteraction();
      for (final chunk in _voiceChunks(storyText)) {
        await _tts.speak(chunk, fromUserAction: true);
      }
    } catch (e) {
      debugPrint('Story voice fallback error: $e');
      if (mounted) {
        setState(() {
          _statusIsError = true;
          _errorMessage = widget.lang == 'fr'
              ? 'Lecture vocale indisponible.'
              : 'Voice playback unavailable.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canListen = (widget.audioPath ?? '').isNotEmpty || widget.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Column(
            children: [
              if (canListen) ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        if (_isPlaying) {
                          if (_usingTtsFallback) {
                            await _tts.stop();
                            if (mounted) {
                              setState(() => _isPlaying = false);
                            }
                          } else {
                            await _audioPlayer.pause();
                          }
                        } else {
                          await _playStoryAudio();
                        }
                      },
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 32,
                    ),
                    Text(widget.lang == 'fr'
                        ? 'Ecouter l\'histoire'
                        : 'Listen to the story'),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text(
                widget.text,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _statusIsError
                        ? Colors.red.shade700
                        : Colors.blue.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ExternalStep extends StatelessWidget {
  final String title;
  final String url;
  final String description;
  final String lang;

  const ExternalStep({
    super.key,
    required this.title,
    required this.url,
    required this.description,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Column(
            children: [
              Text(description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: Text(lang == 'fr'
                    ? 'Ouvrir dans le navigateur'
                    : 'Open in Browser'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TraceDotsStep extends StatefulWidget {
  final String prompt;
  final List<Map<String, dynamic>> dots;
  final String target;
  final OnAnswered onAnswered;
  final String lang;

  const TraceDotsStep({
    super.key,
    required this.prompt,
    required this.dots,
    required this.target,
    required this.onAnswered,
    required this.lang,
  });

  @override
  State<TraceDotsStep> createState() => _TraceDotsStepState();
}

class _TraceDotsStepState extends State<TraceDotsStep> {
  final List<Offset?> _points = <Offset?>[];
  bool _donePressed = false;
  Size _boardSize = const Size(320, 220);
  List<Offset> _generatedDots = const [];
  bool _loadingGeneratedDots = false;

  @override
  void initState() {
    super.initState();
    _prepareGuideDots();
  }

  @override
  void didUpdateWidget(covariant TraceDotsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target || oldWidget.dots != widget.dots) {
      _prepareGuideDots();
    }
  }

  Future<void> _prepareGuideDots() async {
    if (widget.dots.isNotEmpty || widget.target.trim().isEmpty) {
      if (_generatedDots.isNotEmpty || _loadingGeneratedDots) {
        setState(() {
          _generatedDots = const [];
          _loadingGeneratedDots = false;
        });
      }
      return;
    }

    setState(() => _loadingGeneratedDots = true);
    final generated = await _generateGuideDotsNormalized(widget.target);
    if (!mounted) return;
    setState(() {
      _generatedDots = generated;
      _loadingGeneratedDots = false;
    });
  }

  List<Offset> get _dotOffsets => widget.dots.isNotEmpty
      ? widget.dots
          .map((d) => Offset(d['x'].toDouble(), d['y'].toDouble()))
          .toList()
      : _generatedDots;

  List<Offset> _dotsForBoard(Size size) => _fitDotsToCanvas(_dotOffsets, size);

  void _storeBoardSize(Size size) {
    if ((size.width - _boardSize.width).abs() < 1 &&
        (size.height - _boardSize.height).abs() < 1) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _boardSize = size);
    });
  }

  double get _traceProgress {
    final fittedDots = _dotsForBoard(_boardSize);
    if (fittedDots.isEmpty) return 0.0;
    var covered = 0;
    for (final dot in fittedDots) {
      final isCovered = _points.any((point) {
        return point != null && (point - dot).distance < 24;
      });
      if (isCovered) {
        covered++;
      }
    }
    return covered / fittedDots.length;
  }

  void _addPoint(Offset p) {
    setState(() => _points.add(p));
  }

  void _endStroke() {
    if (_points.isNotEmpty && _points.last != null) {
      setState(() => _points.add(null));
    }
  }

  void _onDone() {
    final passed = _traceProgress >= 0.5;
    if (!passed) {
      widget.onAnswered(false);
      return;
    }
    setState(() => _donePressed = true);
    widget.onAnswered(true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final containerHeight = isSmallScreen ? 200.0 : 250.0;
    final fontSize = isSmallScreen ? 14.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.prompt,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = Size(
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
                  containerHeight,
                );
                _storeBoardSize(boardSize);
                return GestureDetector(
                  onPanStart:
                      _donePressed ? null : (d) => _addPoint(d.localPosition),
                  onPanUpdate:
                      _donePressed ? null : (d) => _addPoint(d.localPosition),
                  onPanEnd: _donePressed ? null : (_) => _endStroke(),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _TraceDotsPainter(
                          points: _points,
                          dots: _dotsForBoard(boardSize),
                          target: widget.target,
                        ),
                      ),
                      if (_loadingGeneratedDots && _dotOffsets.isEmpty)
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (!_donePressed) ...[
          LinearProgressIndicator(
            value: _traceProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _traceProgress >= 0.5 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(_points.clear),
                icon: const Icon(Icons.refresh),
                label: Text(widget.lang == 'fr' ? 'Effacer' : 'Clear'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _onDone,
                icon: const Icon(Icons.check),
                label: Text(widget.lang == 'fr' ? 'Termine' : 'Done'),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => widget.onAnswered(true),
            icon: const Icon(Icons.arrow_forward),
            label: Text(widget.lang == 'fr' ? 'Continuer' : 'Continue'),
          ),
        ],
      ],
    );
  }
}

class _TraceDotsPainter extends CustomPainter {
  final List<Offset?> points;
  final List<Offset> dots;
  final String target;

  _TraceDotsPainter(
      {required this.points, required this.dots, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF7FAFF);
    canvas.drawRect(Offset.zero & size, bg);

    final guidePaint = Paint()
      ..color = Colors.blueGrey.shade100
      ..strokeWidth = 1;
    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final pathPaint = Paint()
      ..color = const Color(0x994CA3D9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < dots.length - 1; i++) {
      canvas.drawLine(dots[i], dots[i + 1], pathPaint);
    }

    final dotPaint = Paint()..color = Colors.blue.shade500;

    for (final dot in dots) {
      canvas.drawCircle(dot, dots.length > 40 ? 6.2 : 7.8, dotPaint);
    }

    if (target.isNotEmpty && dots.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: target,
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: Color(0x22000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final pos =
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2);
      tp.paint(canvas, pos);
    }

    final stroke = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TraceDotsPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.dots != dots ||
        oldDelegate.target != target;
  }
}
