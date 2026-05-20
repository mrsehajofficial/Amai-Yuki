// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_toast.dart';
import 'profile_screen.dart';
import 'about_us_screen.dart';
import '../../core/utils/avatar_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Clear all chats?'),
        content: const Text(
          'This will permanently delete your entire conversation history and Yuki\'s memory of you. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ChatProvider>().clearHistory();
              if (context.mounted) {
                PremiumToast.show(
                  context,
                  message: success
                      ? 'Chat history cleared'
                      : 'Failed to clear history',
                  icon: success
                      ? PhosphorIconsRegular.trash
                      : PhosphorIconsRegular.warning,
                );
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium confirmation warning before clearing active session
  void _showSignOutWarning(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Sign Out of Yuki?'),
        content: const Text(
          'Are you sure you want to sign out? This will end your active session and clear your locally cached preferences. You will need to enter your credentials again to resume your chats with Yuki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.logout();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    if (user == null)
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: AppColors.accent.withOpacity(0.1),
                  child: GlassCard(
                    child: Row(
                      children: [
                        // Displaying a high-end profile avatar. If they've bound a custom profile
                        // image, resolve it with high-fidelity scaling. Otherwise, fall back
                        // beautifully to the capitalized first letter. - SV
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            shape: BoxShape.circle,
                            image:
                                user.profilePic != null &&
                                    user.profilePic!.isNotEmpty
                                ? DecorationImage(
                                    image: AvatarHelper.getAvatarProvider(
                                      user.profilePic!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child:
                              user.profilePic == null ||
                                  user.profilePic!.isEmpty
                              ? Text(
                                  (user.fullName ?? user.username)[0]
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName ?? user.username,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIconsRegular.caretRight,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _SettingsTile(
                icon: PhosphorIconsRegular.palette,
                title: 'Appearance',
                subtitle: 'Theme, colors',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppearanceSettingsScreen(),
                  ),
                ),
              ),

              _SettingsTile(
                icon: PhosphorIconsRegular.chatCircleText,
                title: 'Chat Settings',
                subtitle: 'Send behavior, history',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatSettingsScreen()),
                ),
              ),

              _SettingsTile(
                icon: PhosphorIconsRegular.info,
                title: 'About Us',
                subtitle: 'Discover the creators and secrets',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: AppColors.border),
              const SizedBox(height: 16),

              _SettingsTile(
                icon: PhosphorIconsRegular.signOut,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                isDanger: true,
                onTap: () => _showSignOutWarning(context, authProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.accent.withOpacity(0.05),
          highlightColor: AppColors.accent.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? AppColors.danger.withOpacity(0.1)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isDanger ? AppColors.danger : AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDanger
                              ? AppColors.danger
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: AppColors.textMuted.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Theme Mode',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _ThemeTile(
            title: 'Light',
            icon: PhosphorIconsRegular.sun,
            isSelected: authProvider.themeMode == ThemeMode.light,
            onTap: () => authProvider.setThemeMode(ThemeMode.light),
          ),
          _ThemeTile(
            title: 'Dark',
            icon: PhosphorIconsRegular.moon,
            isSelected: authProvider.themeMode == ThemeMode.dark,
            onTap: () => authProvider.setThemeMode(ThemeMode.dark),
          ),
          _ThemeTile(
            title: 'Follow System',
            icon: PhosphorIconsRegular.deviceMobile,
            isSelected: authProvider.themeMode == ThemeMode.system,
            onTap: () => authProvider.setThemeMode(ThemeMode.system),
          ),
          // const SizedBox(height: 32),
          // Text('Special', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          // const SizedBox(height: 16),
          // _PremiumSettingsSwitch(
          //   title: 'AMOLED Dark Mode',
          //   subtitle: 'Use pure black background for OLED screens to save battery',
          //   value: authProvider.isAmoled,
          //   onChanged: (val) => authProvider.setIsAmoled(val),
          // ),
        ],
      ),
    );
  }
}

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Clear all chats?'),
        content: const Text(
          'This will permanently delete your entire conversation history and Yuki\'s memory of you. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ChatProvider>().clearHistory();
              if (context.mounted) {
                PremiumToast.show(
                  context,
                  message: success
                      ? 'Chat history cleared'
                      : 'Failed to clear history',
                  icon: success
                      ? PhosphorIconsRegular.trash
                      : PhosphorIconsRegular.warning,
                );
              }
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium confirmation warning before enabling uncensored interactions
  void _showNsfwWarning(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Enable NSFW Mode?'),
        content: const Text(
          'Warning: Enabling NSFW Mode allows Yuki to generate unfiltered, mature, and suggestive companion interactions. This requires you to be at least 18 years old. Please confirm you accept responsibility for explicit generated content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.updateSettings(nsfwMode: true);
              if (!success && context.mounted) {
                PremiumToast.show(
                  context,
                  message: authProvider.error ?? 'Failed to update NSFW mode',
                  icon: PhosphorIconsRegular.warning,
                );
              }
            },
            child: Text(
              'Enable',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

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
        title: const Text('Chat Settings'),
      ),
      body: user == null
          ? const SizedBox()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // _PremiumSettingsSwitch(
                //   title: 'NSFW Mode',
                //   subtitle: 'Allow unfiltered AI responses',
                //   value: user.nsfwMode,
                //   onChanged: (val) async {
                //     if (val) {
                //       _showNsfwWarning(context, authProvider);
                //     } else {
                //       final success = await authProvider.updateSettings(
                //         nsfwMode: false,
                //       );
                //       if (!success && context.mounted) {
                //         PremiumToast.show(
                //           context,
                //           message:
                //               authProvider.error ??
                //               'Failed to update NSFW mode',
                //           icon: PhosphorIconsRegular.warning,
                //         );
                //       }
                //     }
                //   },
                // ),
                const SizedBox(height: 8),
                _PremiumSettingsSwitch(
                  title: 'Enter to Send',
                  subtitle: 'Send messages by pressing Enter',
                  value: authProvider.enterToSend,
                  onChanged: (val) => authProvider.setEnterToSend(val),
                ),
                const SizedBox(height: 32),
                _SettingsTile(
                  icon: PhosphorIconsRegular.trash,
                  title: 'Clear Chat History',
                  subtitle: 'Wipe all messages and memory',
                  isDanger: true,
                  onTap: () => _showClearConfirmation(context),
                ),
              ],
            ),
    );
  }
}

class _PremiumSettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PremiumSettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.accent.withOpacity(0.05),
        highlightColor: AppColors.accent.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppColors.accent.withOpacity(0.05)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    PhosphorIconsFill.checkCircle,
                    color: AppColors.accent,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
