import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Global QVitrin Loader
/// 
/// A premium loading animation that displays the minimal QVitrin SVG logo ('qvitrinmin.svg')
/// with a smooth, pulsing (scale in/out) effect. Used across all applications
/// to replace default CircularProgressIndicators.
class QVitrinLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const QVitrinLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  State<QVitrinLoader> createState() => _QVitrinLoaderState();
}

class _QVitrinLoaderState extends State<QVitrinLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: _buildLogo(),
      ),
    );
  }

  Widget _buildLogo() {
    try {
      if (widget.color != null) {
        return SvgPicture.asset(
          'assets/logo/qvitrinmin.svg',
          width: widget.size,
          colorFilter: ColorFilter.mode(widget.color!, BlendMode.srcIn),
        );
      }
      return SvgPicture.asset(
        'assets/logo/qvitrinmin.svg',
        width: widget.size,
      );
    } catch (e) {
      // Fallback to circular progress indicator if SVG fails or is missing during dev
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          color: widget.color,
          strokeWidth: 2,
        ),
      );
    }
  }
}
