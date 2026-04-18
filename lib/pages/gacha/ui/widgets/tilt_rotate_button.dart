// lib/pages/gacha/ui/widgets/tilt_rotate_button.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tiny "gacha-like" tilt animation for buttons.
///
/// - On tap, rotates the button slightly (default: ~20°) then returns to 0°.
/// - Calls [onPressed] immediately (animation does not block the action).
class TiltRotateButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget child;

  /// Positive values rotate clockwise.
  final double tiltDegrees;

  final Duration forwardDuration;
  final Duration backDuration;

  const TiltRotateButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.tiltDegrees = -20,
    this.forwardDuration = const Duration(milliseconds: 90),
    this.backDuration = const Duration(milliseconds: 140),
  });

  @override
  State<TiltRotateButton> createState() => _TiltRotateButtonState();
}

class _TiltRotateButtonState extends State<TiltRotateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _angle;

  double get _targetAngleRad => widget.tiltDegrees * math.pi / 180.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.forwardDuration + widget.backDuration,
    );
    _rebuildAnimation();
  }

  @override
  void didUpdateWidget(covariant TiltRotateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiltDegrees != widget.tiltDegrees ||
        oldWidget.forwardDuration != widget.forwardDuration ||
        oldWidget.backDuration != widget.backDuration) {
      _controller.duration = widget.forwardDuration + widget.backDuration;
      _rebuildAnimation();
    }
  }

  void _rebuildAnimation() {
    final forwardW = (widget.forwardDuration.inMilliseconds <= 0
            ? 1
            : widget.forwardDuration.inMilliseconds)
        .toDouble();
    final backW =
        (widget.backDuration.inMilliseconds <= 0 ? 1 : widget.backDuration.inMilliseconds)
            .toDouble();
    _angle = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: _targetAngleRad).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: forwardW,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: _targetAngleRad, end: 0).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        weight: backW,
      ),
    ]).animate(_controller);
  }

  void _handlePressed() {
    if (widget.onPressed == null) return;
    _controller.forward(from: 0);
    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _angle.value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.onPressed == null ? null : _handlePressed,
        style: widget.style,
        child: widget.child,
      ),
    );
  }
}


