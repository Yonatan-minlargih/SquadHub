import 'package:flutter/material.dart';
import '../constants/text_styles.dart';

class LoadingScreen extends StatefulWidget {
  final String? message;
  const LoadingScreen({super.key, this.message});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(
                        alpha: _opacityAnimation.value,
                      ),
                      width: 3 * _scaleAnimation.value,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 20 * _scaleAnimation.value,
                        spreadRadius: 2 * _scaleAnimation.value,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Center(
                      child: Text(
                        'S',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 40,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Loading Message
            Text(
              widget.message ?? 'Loading your squad...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Progress Indicator
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
