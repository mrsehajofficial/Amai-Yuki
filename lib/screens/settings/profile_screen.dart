// profile_screen.dart
// 
// Created by Sehaj Varma, 19-year-old Frontend Developer & Design Nerd.
// Made with late night vibes and strong coffee. ☕
// 
// Intent: Default avatar upload screens are boring and prone to compile limits. 
// I designed this to support three gorgeous states:
// 1. Handcrafted AI Character Presets (fast, server-friendly network URLs).
// 2. Custom HTTPS Web URLs (instant external avatar binding).
// 3. Native Gallery Pick (using image_picker, parsed to secure Base64).
// Fully modular to avoid nested "widget soup" and provide immediate results.

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_toast.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  String? _selectedProfilePic;
  bool _isSaving = false;
  bool _isGeneratingImpression = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _selectedProfilePic = user?.profilePic;
    _promptController = TextEditingController();
    _loadCustomPrompt();
  }

  Future<void> _loadCustomPrompt() async {
    final prompt = await context.read<AuthProvider>().getCustomPrompt();
    if (mounted) {
      setState(() {
        _promptController.text = prompt ?? '';
      });
    }
  }

  Future<void> _refreshImpression() async {
    setState(() => _isGeneratingImpression = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.generateYukiImpression();
    if (mounted) {
      setState(() => _isGeneratingImpression = false);
      if (result != null) {
        PremiumToast.show(
          context,
          message: 'My vibe check updated! 💓',
          icon: PhosphorIconsFill.heart,
        );
      } else {
        PremiumToast.show(
          context,
          message: auth.error ?? 'Failed to update vibe check.',
          icon: PhosphorIconsRegular.warning,
        );
      }
    }
  }

  // Pick local image, resize, and convert to base64
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _selectedProfilePic = 'data:image/jpeg;base64,$base64String';
        });
        if (mounted) {
          PremiumToast.show(
            context,
            message: 'Gallery image selected!',
            icon: PhosphorIconsRegular.image,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        PremiumToast.show(
          context,
          message: 'Failed to access native gallery.',
          icon: PhosphorIconsRegular.warning,
        );
      }
    }
  }

  // Direct, safe image provider resolver (base64 memory or network HTTP)
  ImageProvider _getAvatarImageProvider(String avatar) {
    if (avatar.startsWith('data:image')) {
      final base64Content = avatar.split(',').last;
      return MemoryImage(base64Decode(base64Content));
    }
    return NetworkImage(avatar);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final auth = context.read<AuthProvider>();
    
    // Save Name and Profile Pic to Flask Backend
    final success = await auth.updateSettings(
      fullName: _nameController.text.trim(),
      profilePic: _selectedProfilePic,
    );

    // Save Custom Prompt locally
    await auth.saveCustomPrompt(_promptController.text.trim());

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        PremiumToast.show(
          context, 
          message: 'Profile updated successfully!', 
          icon: PhosphorIconsRegular.userCheck,
        );
      } else {
        PremiumToast.show(
          context, 
          message: auth.error ?? 'Failed to update profile', 
          icon: PhosphorIconsRegular.warning,
        );
      }
    }
  }

  // Opens a beautiful glass drawer sheet to let users choose upload styles
  void _showAvatarSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          // border: Border.all(color: AppColors.border.withOpacity(0.4)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Avatar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 20),
              
              // Upload Styles
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(PhosphorIconsRegular.image, color: AppColors.accent, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                'Pick Gallery',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showUrlInputDialog();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(PhosphorIconsRegular.link, color: AppColors.textSecondary, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                'Custom URL',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Text(
                'HANDCRAFTED AI PRESETS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              
              // Preset list
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPresetOption(
                      'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&h=800&fit=crop',
                      'Yuki',
                    ),
                    _buildPresetOption(
                      'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800&h=800&fit=crop',
                      'Sapphire',
                    ),
                    _buildPresetOption(
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&h=800&fit=crop',
                      'Cyber',
                    ),
                    _buildPresetOption(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=800&fit=crop',
                      'Pastel',
                    ),
                    _buildPresetOption(
                      'https://images.unsplash.com/photo-1566753323558-f4e0952af115?w=800&h=800&fit=crop',
                      'Chibi',
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

  // Renders a sleek preset circle with active indicator border
  Widget _buildPresetOption(String url, String name) {
    final isSelected = _selectedProfilePic == url;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfilePic = url;
        });
        Navigator.pop(context);
        PremiumToast.show(
          context,
          message: '$name Avatar selected!',
          icon: PhosphorIconsRegular.userCheck,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 2.5,
                ),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Elegant text field dialog for custom image link pasting
  void _showUrlInputDialog() {
    final controller = TextEditingController(
      text: _selectedProfilePic != null && !_selectedProfilePic!.startsWith('data:') ? _selectedProfilePic : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'https://example.com/avatar.jpg',
            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  _selectedProfilePic = url;
                });
                Navigator.pop(context);
                PremiumToast.show(
                  context,
                  message: 'Custom URL set!',
                  icon: PhosphorIconsRegular.link,
                );
              }
            },
            child: Text('Apply', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Selector Stack with camera trigger
            Center(
              child: GestureDetector(
                onTap: _showAvatarSelectorSheet,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        image: _selectedProfilePic != null && _selectedProfilePic!.isNotEmpty
                            ? DecorationImage(
                                image: _getAvatarImageProvider(_selectedProfilePic!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedProfilePic == null || _selectedProfilePic!.isEmpty
                          ? const Center(
                              child: Icon(
                                PhosphorIconsFill.user,
                                color: Colors.white,
                                size: 50,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.camera,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
              ),
            ),
            const SizedBox(height: 40),

            // Full Name Input
            _buildSectionTitle('Full Name'),
            _buildTextField(
              controller: _nameController,
              hint: 'How should I call you?',
              icon: PhosphorIconsRegular.user,
            ),
            const SizedBox(height: 24),

            // Custom Prompt
            _buildSectionTitle('Yuki\'s Personality'),
            _buildTextField(
              controller: _promptController,
              hint: 'Define how I should behave (e.g. "You are a helpful assistant who loves cats")',
              icon: PhosphorIconsRegular.sparkle,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Yuki's Vibe Check Card
            Builder(
              builder: (context) {
                final user = context.watch<AuthProvider>().user;
                final impression = user?.yukiImpression;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('My Vibe Check of You 💓'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.05),
                            Colors.pink.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (impression != null && impression.isNotEmpty)
                                ? '“$impression”'
                                : '“I haven\'t formed a complete impression of you yet... Let\'s chat more so I can understand your heart! 💕”',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _isGeneratingImpression ? null : _refreshImpression,
                              icon: _isGeneratingImpression
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                  : const Icon(PhosphorIconsFill.sparkle, size: 14),
                              label: const Text('Refresh Vibe Check', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.pinkAccent,
                                side: BorderSide(color: Colors.pinkAccent.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.accent.withOpacity(0.5),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
