import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Global flag to detect whether the user is interacting via a desktop pointer (mouse)
/// or mobile touch interface. Reacting to this allows us to disable native
/// "choppy" mouse wheel scroll physics while preserving touch drag functionality.
final ValueNotifier<bool> isDesktopInputNotifier = ValueNotifier<bool>(true);

/// A globally attachable ScrollBehavior that intercepts PointerScrollEvents (mouse wheel)
/// and translates them into smooth [ScrollController.animateTo] motions.
class CustomSmoothScrollBehavior extends MaterialScrollBehavior {
  const CustomSmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse, // Ensures mouse drag scrolling is supported if desired
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Keep standard scrollbar decorations
    final widget = super.buildScrollbar(context, child, details);

    // Wrap the resulting scrollable to intercept mouse wheel signals smoothly
    return _SmoothScrollWrapper(
      controller: details.controller,
      child: widget,
    );
  }
}

class _SmoothScrollWrapper extends StatefulWidget {
  final ScrollController? controller;
  final Widget child;

  const _SmoothScrollWrapper({
    this.controller,
    required this.child,
  });

  @override
  State<_SmoothScrollWrapper> createState() => _SmoothScrollWrapperState();
}

class _SmoothScrollWrapperState extends State<_SmoothScrollWrapper> {
  double _targetPosition = 0;
  bool _isAnimating = false;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final scrollable = Scrollable.maybeOf(context);
      
      ScrollPosition? position;
      if (widget.controller != null && widget.controller!.hasClients) {
        position = widget.controller!.position;
      } else if (scrollable != null) {
        position = scrollable.position;
      }

      if (position == null) return;
      if (position.maxScrollExtent == 0 && position.minScrollExtent == 0) return; // Cannot scroll
      
      // We only execute animation logic if physics is globally paused for mouse
      // However, if we're capturing this, let's just animate.
      if (event.scrollDelta.dy == 0) return;

      if (!_isAnimating) {
        _targetPosition = position.pixels;
      }

      // Delta amount * multiplier for speed
      _targetPosition += event.scrollDelta.dy * 1.5;
      
      _targetPosition = min(
        max(_targetPosition, position.minScrollExtent),
        position.maxScrollExtent,
      );

      if (position.pixels != _targetPosition) {
        _isAnimating = true;
        position.animateTo(
          _targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ).then((_) {
          _isAnimating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      // Update global pointer tracker on click
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.touch || event.kind == PointerDeviceKind.stylus) {
          if (isDesktopInputNotifier.value) isDesktopInputNotifier.value = false;
        } else {
          if (!isDesktopInputNotifier.value) isDesktopInputNotifier.value = true;
        }
      },
      child: widget.child,
    );
  }
}
