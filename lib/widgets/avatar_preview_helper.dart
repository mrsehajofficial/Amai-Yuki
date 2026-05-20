// avatar_preview_helper.dart
//
// Created by Sehaj Varma, 19-year-old Frontend Developer & Design Nerd.
// Made with late night vibes and strong coffee. ☕
//
// Intent: Centralized avatar zoom preview system that supports pinch-to-zoom (up to 5x)
// and dynamic, animated double-tap-to-zoom centered on touch coordinates.
// Can be triggered from any profile avatar, context menu, or header across the app.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/avatar_helper.dart';

class AvatarPreviewHelper {
  /// Static method to trigger the premium double-tap zoom avatar preview dial. - SV
  static void show(
    BuildContext context, {
    required String? profilePic,
    required String displayName,
  }) {
    if (profilePic == null || profilePic.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _AvatarPreviewDialogContent(
        profilePic: profilePic,
        displayName: displayName,
      ),
    );
  }
}

/// A premium, high-performance, custom stateful dialog content to handle
/// animated double-tap-to-zoom on the user's avatar. - SV
class _AvatarPreviewDialogContent extends StatefulWidget {
  final String profilePic;
  final String displayName;

  const _AvatarPreviewDialogContent({
    required this.profilePic,
    required this.displayName,
  });

  @override
  State<_AvatarPreviewDialogContent> createState() =>
      _AvatarPreviewDialogContentState();
}

class _AvatarPreviewDialogContentState
    extends State<_AvatarPreviewDialogContent>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          _transformationController.value = _zoomAnimation!.value;
        });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Smoothly zoom in (to 2.5x) centered on the tapped location, or zoom back out to 1.0x - SV
  void _handleDoubleTap(TapDownDetails details) {
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final double targetScale = currentScale > 1.1 ? 1.0 : 2.5;
    final Offset localPosition = details.localPosition;

    final Matrix4 targetMatrix;
    if (targetScale == 1.0) {
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom in centered perfectly on the double-tapped point - SV
      targetMatrix = Matrix4.identity()
        ..translate(
          -localPosition.dx * (targetScale - 1),
          -localPosition.dy * (targetScale - 1),
        )
        ..scale(targetScale);
    }

    _zoomAnimation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    TapDownDetails? doubleTapDetails;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 1. Background Tap Dismiss Layer (Covers entire screen behind image) - SV
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            // 2. Full-Screen Zoomable Image - SV
            Center(
              child: GestureDetector(
                onDoubleTapDown: (details) {
                  doubleTapDetails = details;
                },
                onDoubleTap: () {
                  if (doubleTapDetails != null) {
                    _handleDoubleTap(doubleTapDetails!);
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  clipBehavior: Clip.none,
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Hero(
                    tag: 'avatar_preview_${widget.profilePic.hashCode}',
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Image(
                        image: AvatarHelper.getAvatarProvider(
                          widget.profilePic,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Floating Premium Top Navigation Overlay - SV
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.x,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
