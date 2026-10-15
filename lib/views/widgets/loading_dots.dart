import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three dots rising and falling in a wave.
///
/// A lightweight, self-contained loader for gaps where content is being
/// fetched or a platform view is still starting up (e.g. the MapLibre style).
/// All three dots are driven by one [AnimationController]; each dot is
/// phase-shifted so the motion reads as a flowing wave rather than a
/// synchronized bounce.
///
/// The animation is skipped when the platform reports that animations are
/// disabled ([MediaQuery.disableAnimations]), leaving the dots at rest.
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    this.color,
    this.dotSize = 8,
    this.spacing = 8,
    this.amplitude = 8,
    this.duration = const Duration(milliseconds: 600),
  });

  /// Dot colour. Defaults to the theme's accent colour when null.
  final Color? color;

  /// Diameter of each dot.
  final double dotSize;

  /// Gap between adjacent dots.
  final double spacing;

  /// How far (in pixels) each dot travels up from its resting position.
  final double amplitude;

  /// Time for one dot to complete a full up-and-down cycle.
  final Duration duration;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  /// Offset applied to each successive dot so the three move out of phase.
  static const double _phaseOffset = 0.15;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Chargement',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                  child: Transform.translate(
                    offset: Offset(0, _verticalOffset(i)),
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Upward travel for dot [index] at the current point in the cycle.
  ///
  /// A `sin` over the dot's phase gives a smooth up-and-down; the per-dot
  /// [_phaseOffset] staggers the three so they ripple.
  double _verticalOffset(int index) {
    final phase = (_controller.value + index * _phaseOffset) % 1.0;
    return -widget.amplitude * math.sin(math.pi * phase);
  }
}
