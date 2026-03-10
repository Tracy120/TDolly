import 'package:flutter/material.dart';

class AppBrand extends StatefulWidget {
  final bool compact;
  final bool animate;
  final String? subtitle;
  final double titleSize;

  const AppBrand({
    super.key,
    this.compact = false,
    this.animate = true,
    this.subtitle,
    this.titleSize = 28,
  });

  @override
  State<AppBrand> createState() => _AppBrandState();
}

class _AppBrandState extends State<AppBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _tilt = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant AppBrand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) {
      return;
    }
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _badge(double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.animate ? _pulse.value : 1.0;
        final angle = widget.animate ? _tilt.value : 0.0;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A7A0), Color(0xFF57C785)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2200A7A0),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
          Positioned(
            top: -4,
            right: -5,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC857),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFF9A5A00),
                size: size * 0.18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final badgeSize = compact ? 28.0 : 72.0;
    final titleStyle = TextStyle(
      fontSize: compact ? 20 : widget.titleSize,
      fontWeight: FontWeight.w800,
      letterSpacing: compact ? 0.1 : 0.2,
      color: const Color(0xFF18334A),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _badge(badgeSize),
          const SizedBox(width: 10),
          Text('TeacherDolly', style: titleStyle),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _badge(badgeSize),
        const SizedBox(height: 14),
        Text('TeacherDolly', style: titleStyle, textAlign: TextAlign.center),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4D6475),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
