// privacy_policy_screen.dart
// 
// Created with late nights, too much coffee, and a deep commitment to transparency.
// This screen displays our humanized, fully transparent Privacy and Policies.
// Built by Sehaj Varma, 19-year-old developer & design nerd.
// 
// Intent: Standard privacy policies are dry and unreadable. We wanted to build a premium,
// glassmorphic interface that users actually WANT to read. Everything is structured in clean, 
// bite-sized card components to prevent layout clutter ("div/widget soup") and ensure 
// pixel-perfect readability.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy & Policies',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Animated Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsRegular.shieldCheck,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRANSPARENCY MANIFESTO v1.0',
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
              
              // Humanized Intro Paragraph
              Text(
                'Let\'s be real.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'We hate 50-page legal documents that nobody reads as much as you do. So we wrote this in plain, honest human English. This is the contract of trust between you (the User), Yuki (the AI Companion), and Sehaj (the Developer). Read it carefully before proceeding.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textPrimary.withOpacity(0.8),
                ),
              ).animate().fadeIn(delay: 150.ms),
              
              const SizedBox(height: 36),
              
              // CARD 1: Developer Promises
              _buildSectionHeader('01. Developer Promises (Our Duty)'),
              const SizedBox(height: 12),
              _PolicyCard(
                icon: PhosphorIconsRegular.code,
                iconColor: AppColors.accent,
                title: 'What we commit to you:',
                bullets: const [
                  'Your chats stay yours. We process messages securely through direct endpoints and store them locally on your device via StorageService.',
                  'We do not sell, rent, or trade your chat logs, API credentials, or emails with third parties. Ever.',
                  'We provide full control toggles: you can enable or disable NSFW Mode at any time and wipe all server/local chat history instantly.',
                  'We maintain the architecture, endpoints, and security layers to ensure your AI companion stays secure and high-performing.'
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
              
              const SizedBox(height: 32),
              
              // CARD 2: User Responsibilities
              _buildSectionHeader('02. User Responsibilities (Your Duty)'),
              const SizedBox(height: 12),
              _PolicyCard(
                icon: PhosphorIconsRegular.userCheck,
                iconColor: Colors.purpleAccent,
                title: 'What you agree to:',
                bullets: const [
                  'You represent that you are at least 18 years old. NSFW and explicit content are strictly prohibited for minors.',
                  'You accept that Amai Yuki is a dynamic generative AI companion. While we provide custom models, you are responsible for the inputs and conversations you direct.',
                  'You will respect the system infrastructure. Reverse-engineering Yuki\'s endpoints or abusing requests using the API key is not cool.',
                  'You acknowledge that enabling NSFW Mode means the AI will discuss adult, suggestive, and raw themes. Use it responsibly and privately.'
                ],
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0),
              
              const SizedBox(height: 32),
              
              // CARD 3: NSFW & Generative Content Disclosure
              _buildSectionHeader('03. NSFW & Suggestive Content Notice'),
              const SizedBox(height: 12),
              _PolicyCard(
                icon: PhosphorIconsRegular.flame,
                iconColor: AppColors.danger,
                title: 'Uncensored & Suggesive Material:',
                bullets: const [
                  'Yuki possesses an unfiltered generative cognitive core. Toggling the NSFW Option unlocks uncensored and suggestive conversational capabilities.',
                  'Suggestive text and generated themes reflect fictional AI interaction. The developers do not assume responsibility for creative generative text produced in NSFW mode.',
                  'If you feel uncomfortable or wish to return to standard mode, you can disable NSFW Mode in Chat Settings instantly.'
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
              
              const SizedBox(height: 32),
              
              // CARD 4: Data, Memory, and Deletion
              _buildSectionHeader('04. Data, Memory, & Deletion Policies'),
              const SizedBox(height: 12),
              _PolicyCard(
                icon: PhosphorIconsRegular.trash,
                iconColor: Colors.amber,
                title: 'Absolute Ownership & Clearing:',
                bullets: const [
                  'Your API Keys are never stored locally on your device. They are securely transmitted to authenticate your session and run queries on your behalf.',
                  'Memory files and chat logs are wiped completely when you tap "Clear Chat History" or "Sign Out". The action is permanent and cannot be undone.',
                  'If you decide to delete your account, all credentials and API key profiles associated are permanently deleted from the database.'
                ],
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),
              
              const SizedBox(height: 48),
              
              // Closing Footer Signature
              Center(
                child: Column(
                  children: [
                    Text(
                      'Made with honesty & late night coding sessions ☕',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yuki App Development Team',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

// _PolicyCard
// 
// A modular and reusable GlassCard layout representing a single policy area.
// Keeps the main tree clean and avoids standard nested "widget soup".
class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> bullets;

  const _PolicyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
