// camera_screen.dart
// Built with love by Sehaj Varma (Late nights, double-shot espresso, and pure focus ☕)
// Intent: A premium, ultra-sleek, gestures-driven custom camera viewport that supports 
// all onboard physical cameras (ultra-wide, telephoto, front, back) with smooth transitions, 
// glassmorphic control overlays, and native snapping capability.

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/premium_toast.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  
  // Flash mode state variables
  FlashMode _currentFlashMode = FlashMode.off;
  bool _showFlashOptions = false;
  
  // Snap review state
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraSystem();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Crucial step: dispose controller to release the device hardware resource - SV
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changes require prompt release or re-initialization of camera streams - SV
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onCameraSelected(cameraController.description);
    }
  }

  /// Queries physical cameras on the board and kicks off the initial stream.
  Future<void> _initializeCameraSystem() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _onCameraSelected(_cameras[_selectedCameraIndex]);
      } else {
        _showError('No physical cameras detected on this hardware.');
      }
    } catch (e) {
      _showError('Failed to initialize cameras: $e');
    }
  }

  /// Instantiates a new camera controller and starts previewing the stream.
  Future<void> _onCameraSelected(CameraDescription description) async {
    // Dispose active controller first to prevent hardware locks - SV
    if (_controller != null) {
      await _controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false, // Disabling audio to speed up snaps & ignore microphone permission requirements
    );

    _controller = cameraController;

    // Watch for controller changes & rebuild preview as soon as it binds
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        _showError('Camera hardware error: ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      // Set default flash mode to off
      await cameraController.setFlashMode(_currentFlashMode);
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      _showError('Camera Exception occurred: ${e.description}');
    }
  }

  /// Cycles through all available lenses found on the device.
  void _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    
    HapticFeedback.selectionClick();
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _onCameraSelected(_cameras[_selectedCameraIndex]);
  }

  /// Cycles through flash modes
  Future<void> _setFlashMode(FlashMode mode) async {
    if (_controller == null || !_isCameraInitialized) return;
    
    try {
      await _controller!.setFlashMode(mode);
      setState(() {
        _currentFlashMode = mode;
        _showFlashOptions = false;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _showError('Failed to change flash mode: $e');
    }
  }

  /// Capture action: triggers the shutter, triggers high-intensity visual snap feedback, 
  /// and switches to review canvas mode.
  void _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    try {
      HapticFeedback.heavyImpact();
      setState(() {
        _isCapturing = true;
      });

      // Shutter snap - SV
      final XFile photoFile = await _controller!.takePicture();

      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedFile = photoFile;
        });
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showError('Snapping photo failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    PremiumToast.show(
      context,
      message: message,
      icon: PhosphorIconsRegular.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Core Camera preview stream / Snapped Photo display
          _capturedFile != null
              ? _buildSnapReviewCanvas()
              : _buildLiveCameraCanvas(),

          // 2. Translucent close button on top-left - SV
          if (_capturedFile == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _buildGlassIconButton(
                icon: PhosphorIconsRegular.x,
                onTap: () => Navigator.pop(context),
              ),
            ),

          // 3. Settings pill on top-right (Flash selector)
          if (_capturedFile == null && _isCameraInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildGlassIconButton(
                    icon: _getFlashIcon(_currentFlashMode),
                    onTap: () => setState(() => _showFlashOptions = !_showFlashOptions),
                    isActive: _showFlashOptions,
                  ),
                  if (_showFlashOptions) ...[
                    const SizedBox(height: 8),
                    _buildFlashOptionsMenu(),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Live view screen layout
  Widget _buildLiveCameraCanvas() {
    if (!_isCameraInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing Camera Core...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    // Scale preview properly to fit full viewport or respect original aspect ratio - SV
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      children: [
        // Camera Viewport
        Positioned.fill(
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ),

        // Animated White Screen flash visual feedback on Shutter snap - SV
        if (_isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ).animate().fadeOut(duration: 250.ms),
          ),

        // Translucent Lower controls dock - SV
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 32,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.0),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera index switch helper / Lens description label - SV
                _cameras.length > 1
                    ? _buildGlassIconButton(
                        icon: PhosphorIconsRegular.cameraRotate,
                        size: 52,
                        onTap: _switchCamera,
                      )
                    : const SizedBox(width: 52),

                // Shutter Snap Button
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0), duration: 2.seconds),
                  ),
                ),

                // Display Lens identifier details nicely - SV
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    '${_selectedCameraIndex + 1}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Snapped photo preview and send review screen
  Widget _buildSnapReviewCanvas() {
    if (_capturedFile == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Display full snapped image preview
        Positioned.fill(
          child: Image.file(
            File(_capturedFile!.path),
            fit: BoxFit.cover,
          ),
        ),

        // Glowing lower action portal (Retake / Send)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 40,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.0),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LOOKING GORGEOUS 📸',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Retake snap - SV
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _capturedFile = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.arrowCounterClockwise, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Retake',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Send to Chat - SV
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            // Pop out captured file details to the trigger portal - SV
                            Navigator.pop(context, _capturedFile);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(PhosphorIconsRegular.paperPlaneTilt, color: AppColors.background, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Photo',
                                  style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Visual helpers: sleek translucent glass button
  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 48,
    bool isActive = false,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: isActive 
              ? AppColors.accent.withOpacity(0.24) 
              : Colors.black.withOpacity(0.35),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive 
                      ? AppColors.accent.withOpacity(0.45) 
                      : Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.accent : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dropdown flash menu styled beautifully
  Widget _buildFlashOptionsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildFlashOptionItem(FlashMode.off, 'Off', PhosphorIconsRegular.lightningSlash),
          _buildFlashOptionItem(FlashMode.auto, 'Auto', PhosphorIconsRegular.lightningA),
          _buildFlashOptionItem(FlashMode.always, 'On', PhosphorIconsRegular.lightning),
          _buildFlashOptionItem(FlashMode.torch, 'Torch', PhosphorIconsRegular.flashlight),
        ],
      ),
    ).animate().fadeIn().scale(alignment: Alignment.topRight, duration: 200.ms);
  }

  Widget _buildFlashOptionItem(FlashMode mode, String label, IconData icon) {
    final isSelected = _currentFlashMode == mode;
    return InkWell(
      onTap: () => _setFlashMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return PhosphorIconsRegular.lightningSlash;
      case FlashMode.auto:
        return PhosphorIconsRegular.lightningA;
      case FlashMode.always:
        return PhosphorIconsRegular.lightning;
      case FlashMode.torch:
        return PhosphorIconsRegular.flashlight;
    }
  }
}
