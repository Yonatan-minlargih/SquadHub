import 'package:flutter/material.dart';

class SlideActionButton extends StatefulWidget {
  final VoidCallback onSubmit;
  final String text;
  final Color outerColor;
  final Color innerColor;
  final double height;
  final double borderRadius;

  const SlideActionButton({
    super.key,
    required this.onSubmit,
    required this.text,
    this.outerColor = const Color(0xFFB91004),
    this.innerColor = Colors.white,
    this.height = 56,
    this.borderRadius = 50,
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with SingleTickerProviderStateMixin {
  double _position = 0;
  double _maxWidth = 0;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetPosition() {
    _resetController.forward(from: 0).then((_) {
      setState(() {
        _position = 0;
      });
      _resetController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth - widget.height;
        final progress = _position / _maxWidth.clamp(0.001, double.infinity);

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.outerColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.outerColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Text Label with fade effect
              Center(
                child: AnimatedOpacity(
                  opacity: (1 - progress * 1.5).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 100),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Draggable Thumb with smooth animation
              AnimatedPositioned(
                duration: _resetController.isAnimating
                    ? _resetController.duration!
                    : const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                left: _resetController.isAnimating
                    ? _resetAnimation.value * _position
                    : _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!_resetController.isAnimating) {
                      setState(() {
                        _position += details.delta.dx;
                        if (_position < 0) _position = 0;
                        if (_position > _maxWidth) _position = _maxWidth;
                      });
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (_position >= _maxWidth * 0.85) {
                      // Trigger Action
                      widget.onSubmit();
                      // Reset position after action
                      _resetPosition();
                    } else {
                      // Snap back with animation
                      _resetPosition();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: widget.height,
                    width: widget.height,
                    decoration: BoxDecoration(
                      color: widget.innerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // Progress indicator background
              if (progress > 0.1)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.1 * progress),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
