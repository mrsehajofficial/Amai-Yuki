// loading_dots.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class LoadingDots extends StatelessWidget {
  const LoadingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 6, height: 6, decoration: BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0), duration: 400.ms, delay: (index * 150).ms)
            .then(delay: 400.ms);
      }),
    );
  }
}
