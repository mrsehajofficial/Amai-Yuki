// bottom_nav_dock.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class BottomNavItem {
  final IconData iconRegular;
  final IconData iconFill;
  final String label;
  const BottomNavItem({required this.iconRegular, required this.iconFill, required this.label});
}

class BottomNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const BottomNavDock({super.key, required this.currentIndex, required this.onTap, required this.items});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, left: 16, right: 16,
      child: RepaintBoundary(
        child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              height: 72, padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.7),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;
                  return GestureDetector(
                    onTap: () { if (!isActive) { HapticFeedback.selectionClick(); onTap(index); } },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: isActive ? AppColors.accent.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isActive ? item.iconFill : item.iconRegular, color: isActive ? AppColors.accent : AppColors.textPrimary.withOpacity(0.35), size: 24),
                          if (isActive) Text(item.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)).animate().fadeIn(),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
