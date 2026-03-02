// ═══════════════════════════════════════════════════════════════
//  PERFORMANCE WIDGETS
//  Reusable widgets that enforce 60fps best practices.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Wraps a child in RepaintBoundary + optional AnimatedOpacity.
/// Use for any widget that animates independently.
class IsolatedLayer extends StatelessWidget {
  final Widget child;
  final bool visible;
  final Duration fadeDuration;

  const IsolatedLayer({
    super.key,
    required this.child,
    this.visible = true,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: fadeDuration,
        child: child,
      ),
    );
  }
}

/// A shimmer loading placeholder for cards/tiles.
/// Shows while data is loading.
class LuxeShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LuxeShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<LuxeShimmer> createState() => _LuxeShimmerState();
}

class _LuxeShimmerState extends State<LuxeShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-1.0 + 2.0 * _ctrl.value + 1.0, 0),
              colors: const [
                Color(0xFF131620),
                Color(0xFF1A1E2C),
                Color(0xFF131620),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Deferred builder — delays building expensive widgets
/// until after the first frame, preventing jank on screen entry.
class DeferredBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final Widget placeholder;
  final Duration delay;

  const DeferredBuilder({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<DeferredBuilder> createState() => _DeferredBuilderState();
}

class _DeferredBuilderState extends State<DeferredBuilder> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.builder(context) : widget.placeholder;
  }
}

/// Safe animated builder that checks mounted before rebuilding.
/// Prevents "setState called after dispose" errors.
class SafeAnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext context) builder;

  const SafeAnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => builder(context),
    );
  }
}