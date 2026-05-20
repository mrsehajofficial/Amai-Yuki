// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _triggerInit();
  }

  Future<void> _triggerInit() async {
    // Small delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.read<AuthProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Elegant animated ambient glow blob in the background
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.06),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.15, 1.15),
              duration: 4.seconds,
              curve: Curves.easeInOut,
            )
            .blur(
              begin: const Offset(40, 40),
              end: const Offset(80, 80),
              duration: 4.seconds,
            ),
          ),
          
          // Foreground Branding and logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern luxury circular avatar with pulsing, breathing, and shimmer effects
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/images/yuki_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(begin: 0.15, end: 0.0, duration: 800.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2.5.seconds,
                  curve: Curves.easeInOut,
                )
                .then()
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 3.5.seconds, color: Colors.white.withOpacity(0.15)),
                
                const SizedBox(height: 32),
                
                // AMAI YUKI text using AppColors.textPrimary to render perfectly in both dark and light modes
                Text(
                  'AMAI YUKI',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                )
                .animate()
                .fadeIn(duration: 1.seconds)
                .slideY(begin: 0.1, end: 0.0, duration: 1.seconds, curve: Curves.easeOut),
                
                const SizedBox(height: 10),
                
                // Subtitle
                Text(
                  'your AI companion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate()
                .fadeIn(duration: 1.seconds, delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

