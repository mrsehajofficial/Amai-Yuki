// longcat_key_guide_screen.dart
// 
// Created by Sehaj Varma, 19-year-old Frontend Developer & Design Nerd.
// Made with late night vibes and strong coffee. ☕
// 
// Intent: Isolated cards look standard. I redesigned this guide into a unified, 
// futuristic vertical timeline screen. It utilizes glowing circular gradient 
// step badges, vertical glowing flow lines connecting them, and soft background 
// radial blur blobs that add tremendous visual depth. Zero-fail native URL launches.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_toast.dart';

class LongcatKeyGuideScreen extends StatelessWidget {
  const LongcatKeyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIconsRegular.caretLeft,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'API Key Guide',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
      ),
      body: Stack(
        children: [
          // Background Neon Ambient Blobs for deep visual space
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.06),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox(),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glow Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.key,
                            color: AppColors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LONGCAT INTEGRATION METHOD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Get your API Key.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                  ).animate().fadeIn(delay: 100.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Yuki needs a primary API key from Longcat to fuel her neural engine, converse, and execute code queries. Follow these easy steps to generate and bind your own API key in less than a minute.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textPrimary.withOpacity(0.75),
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  
                  const SizedBox(height: 36),
                  
                  // TIMELINE STEPS SECTION
                  _buildTimelineStep(
                    context: context,
                    stepNumber: '01',
                    title: 'Go to Longcat website',
                    lineHeight: 145,
                    customDescription: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open your web browser and navigate to the official platform page:',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final uri = Uri.parse('https://longcat.chat/platform/');
                              try {
                                final success = await launchUrl(
                                  uri,
                                  mode: LaunchMode.platformDefault,
                                );
                                if (!success) {
                                  throw 'Default platform launcher failed';
                                }
                              } catch (_) {
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.inAppWebView,
                                  );
                                } catch (_) {
                                  Clipboard.setData(const ClipboardData(text: 'https://longcat.chat/platform/'));
                                  if (context.mounted) {
                                    PremiumToast.show(
                                      context,
                                      message: 'URL copied! Please open it manually.',
                                      icon: PhosphorIconsRegular.copy,
                                    );
                                  }
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withOpacity(0.12),
                                    Colors.blueAccent.withOpacity(0.04),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.globe,
                                    color: Colors.blueAccent,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Launch Platform Portal',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    PhosphorIconsRegular.arrowSquareOut,
                                    color: Colors.blueAccent.withOpacity(0.7),
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    icon: PhosphorIconsRegular.planet,
                    iconColor: Colors.blueAccent,
                    delay: 200.ms,
                  ),
                  
                  _buildTimelineStep(
                    context: context,
                    stepNumber: '02',
                    title: 'Sign In or Register',
                    lineHeight: 95,
                    description: 'Create a free account or sign in with your active developer credentials to enter the main dashboard.',
                    icon: PhosphorIconsRegular.signIn,
                    iconColor: Colors.purpleAccent,
                    delay: 250.ms,
                  ),
                  
                  _buildTimelineStep(
                    context: context,
                    stepNumber: '03',
                    title: 'Navigate to API Keys',
                    lineHeight: 90,
                    description: 'Head to the Settings or Developer Panel tab and look for the "API Keys" section inside your user dashboard.',
                    icon: PhosphorIconsRegular.identificationCard,
                    iconColor: Colors.amber,
                    delay: 300.ms,
                  ),
                  
                  _buildTimelineStep(
                    context: context,
                    stepNumber: '04',
                    title: 'Generate & Copy Key',
                    isLast: true,
                    description: 'Click on "Create New Secret Key", optionally name it "Yuki App", copy it securely, and paste it directly into the registration field!',
                    icon: PhosphorIconsRegular.copy,
                    iconColor: AppColors.accent,
                    delay: 350.ms,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Sleek Footer Info Banner
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            PhosphorIconsRegular.info,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your API key is transmitted securely via SSL endpoints and is only utilized to directly query secure models on your behalf. We prioritize your ultimate security.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Elegant Timeline Step Builder - No Widget Soup
  Widget _buildTimelineStep({
    required BuildContext context,
    required String stepNumber,
    required String title,
    String? description,
    Widget? customDescription,
    required IconData icon,
    required Color iconColor,
    required Duration delay,
    bool isLast = false,
    double lineHeight = 100,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Step node with custom timeline connecting line
        Column(
          children: [
            // Circular Glowing Gradient Step Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.14),
                    iconColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.06),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: iconColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (!isLast)
              // Sleek vertical flow line
              Container(
                width: 2,
                height: lineHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.35),
                      Colors.purpleAccent.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Right Column: Glass Card step content
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (customDescription != null)
                    customDescription
                  else if (description != null)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay).slideY(begin: 0.04, end: 0);
  }
}
