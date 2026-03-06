import 'package:flutter/material.dart';

typedef OnAnswered = void Function(bool correct);

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
  final OnAnswered onAnswered;

  const McqStep({
    super.key,
    required this.question,
    required this.choices,
    required this.answerIndex,
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

  const DrawStep({
    super.key,
    required this.prompt,
    required this.guide,
    required this.target,
    required this.onAnswered,
  });

  @override
  State<DrawStep> createState() => _DrawStepState();
}

class _DrawStepState extends State<DrawStep> {
  final List<Offset?> _points = <Offset?>[];

  int get _inkCount => _points.whereType<Offset>().length;

  void _addPoint(Offset p) {
    setState(() => _points.add(p));
  }

  void _endStroke() {
    if (_points.isNotEmpty && _points.last != null) {
      setState(() => _points.add(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.prompt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (widget.guide.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(widget.guide, style: const TextStyle(fontSize: 14)),
        ],
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanStart: (d) => _addPoint(d.localPosition),
              onPanUpdate: (d) => _addPoint(d.localPosition),
              onPanEnd: (_) => _endStroke(),
              child: CustomPaint(
                size: Size.infinite,
                painter: _TraceBoardPainter(
                  points: _points,
                  target: widget.target,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(_points.clear),
              icon: const Icon(Icons.refresh),
              label: const Text("Clear"),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                widget.onAnswered(_inkCount >= 8);
              },
              icon: const Icon(Icons.check),
              label: const Text("Done"),
            ),
          ],
        ),
      ],
    );
  }
}

class _TraceBoardPainter extends CustomPainter {
  final List<Offset?> points;
  final String target;

  _TraceBoardPainter({required this.points, required this.target});

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

    if (target.isNotEmpty) {
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
    return oldDelegate.points != points || oldDelegate.target != target;
  }
}
