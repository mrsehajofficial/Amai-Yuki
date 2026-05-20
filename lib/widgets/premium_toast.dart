// premium_toast.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/theme/app_colors.dart';

/// A premium, glassmorphic toast notification that slides from the top-center of the screen.
/// Completely bypasses ScaffoldMessenger, using OverlayEntry for true, high-fidelity overlays.
class PremiumToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = PhosphorIconsRegular.copy,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: AppColors.accent, size: 18)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.08, 1.08), duration: 800.ms, curve: Curves.easeInOut),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .slideY(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 250.ms)
                  .then(delay: 1500.ms)
                  .slideY(begin: 0, end: -0.3, duration: 250.ms, curve: Curves.easeInBack)
                  .fadeOut(duration: 200.ms),
            ),
          ),
        );
      },
    );

    // Insert entry into active screen overlay
    overlayState.insert(overlayEntry);

    // Auto-dispose overlay entry from memory after animation finishes
    Future.delayed(const Duration(milliseconds: 2300), () {
      overlayEntry.remove();
    });
  }
}
