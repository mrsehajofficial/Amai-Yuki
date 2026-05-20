// user_profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/direct_chat_provider.dart';
import '../../widgets/premium_toast.dart';
import '../../widgets/avatar_preview_helper.dart'; // Centralized animated avatar preview helper - SV
import '../../core/utils/avatar_helper.dart';
import 'direct_chat_screen.dart';

/// An ultra-premium, full-screen profile page for chat companions.
/// Features high-fidelity glassmorphic cards, core memory metrics, and real-time syncing.
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String username;
  final String? fullName;
  final String? email;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    this.fullName,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();
    final isFav = provider.isFavorite(userId);
    final displayName = (fullName != null && fullName!.isNotEmpty)
        ? fullName!
        : username;

    // Check if the user is online from conversation details
    bool isOnline = false;
    ConversationModel? convo;
    try {
      convo = provider.conversations.firstWhere((c) => c.otherUserId == userId);
      isOnline = convo.otherUserIsOnline;
    } catch (_) {}

    UserModel? userModel;
    try {
      userModel = provider.users.firstWhere((u) => u.id == userId);
    } catch (_) {}
    final impression = userModel?.yukiImpression;
    final profilePic = userModel?.profilePic ?? convo?.otherUserProfilePic;

    // Robustly resolve the email address from either the global user cache,
    // active conversation details, or constructor parameters. - SV
    final resolvedEmail =
        (userModel?.email != null && userModel!.email.isNotEmpty)
        ? userModel.email
        : ((convo?.otherUserEmail != null && convo!.otherUserEmail!.isNotEmpty)
              ? convo.otherUserEmail
              : email);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Aesthetic Glows
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Custom Scroll View for Premium Parallax Scroll
          CustomScrollView(
            slivers: [
              // Glassy Custom Top App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 280,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: Icon(
                      PhosphorIconsRegular.caretLeft,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double topPadding = MediaQuery.of(
                      context,
                    ).padding.top;
                    final double appBarHeight = constraints.biggest.height;

                    // The flexible space bar starts at 280.0 height and collapses down to pinned height.
                    const double expandedHeightVal = 280.0;
                    final double collapsedHeightVal =
                        topPadding + kToolbarHeight;

                    // Normalize scroll range to [0.0, 1.0] representing expanded -> collapsed
                    final double collapsePercent =
                        ((expandedHeightVal - appBarHeight) /
                                (expandedHeightVal - collapsedHeightVal))
                            .clamp(0.0, 1.0);

                    // Dynamically calculate opacity and scale to achieve a premium fading zoom effect. - SV
                    final double opacity = (1.0 - (collapsePercent * 1.5))
                        .clamp(
                          0.0,
                          1.0,
                        ); // Fades completely a bit before full collapse
                    final double scale = (1.0 - (collapsePercent * 0.12)).clamp(
                      0.88,
                      1.0,
                    );

                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glassy dynamic backplate with real-time blur transitions. - SV
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: collapsePercent * 12.0,
                                sigmaY: collapsePercent * 12.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.surfaceHigh.withOpacity(
                                        0.6 - (collapsePercent * 0.3),
                                      ),
                                      AppColors.background.withOpacity(
                                        0.9 + (collapsePercent * 0.1),
                                      ),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Large Avatar, status badge, and user tags that dynamically fade and scale - SV
                          Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showAvatarPreview(
                                          context,
                                          profilePic,
                                          displayName,
                                        ),
                                        child: Hero(
                                          tag:
                                              'avatar_preview_${profilePic?.hashCode ?? displayName.hashCode}',
                                          child: Container(
                                            width: 110,
                                            height: 110,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.surfaceHigh,
                                              border: Border.all(
                                                color: AppColors.accent,
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withOpacity(0.3),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                              image: profilePic != null
                                                  ? DecorationImage(
                                                      image:
                                                          AvatarHelper.getAvatarProvider(
                                                            profilePic,
                                                          ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: profilePic == null
                                                ? Text(
                                                    displayName[0]
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 44,
                                                      color: AppColors.accent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (isOnline)
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.background,
                                              width: 3.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.success
                                                    .withOpacity(0.6),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ).animate().scale(
                                    curve: Curves.easeOutBack,
                                    duration: 400.ms,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@$username',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Content Area
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Favorites Toggle Action Button
                    OutlinedButton.icon(
                          onPressed: () {
                            provider.toggleFavorite(userId);
                            PremiumToast.show(
                              context,
                              message: isFav
                                  ? 'Removed from favorites'
                                  : 'Added to favorites!',
                              icon: isFav
                                  ? PhosphorIconsRegular.star
                                  : PhosphorIconsFill.star,
                            );
                          },
                          icon: Icon(
                            isFav
                                ? PhosphorIconsFill.star
                                : PhosphorIconsRegular.star,
                            color: isFav ? Colors.amber : AppColors.textPrimary,
                          ),
                          label: Text(
                            isFav
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isFav
                                  ? Colors.amber.withOpacity(0.5)
                                  : AppColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppColors.surface.withOpacity(0.3),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),

                    // User Details Segment
                    _buildHeadline('Account Information'),
                    const SizedBox(height: 12),
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: PhosphorIconsRegular.user,
                                label: 'Username',
                                value: '@$username',
                              ),
                              if (fullName != null) ...[
                                Divider(color: AppColors.border, height: 28),
                                _buildDetailRow(
                                  icon: PhosphorIconsRegular.identificationCard,
                                  label: 'Full Name',
                                  value: fullName!,
                                ),
                              ],
                              if (resolvedEmail != null &&
                                  resolvedEmail.isNotEmpty) ...[
                                Divider(color: AppColors.border, height: 28),
                                _buildDetailRow(
                                  icon: PhosphorIconsRegular.envelopeSimple,
                                  label: 'Email Address',
                                  value: resolvedEmail,
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms)
                        .slideY(begin: 0.1, end: 0),

                    // Yuki's Vibe Check Card
                    if (impression != null && impression.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildHeadline("Yuki's Vibe Check 💓"),
                      const SizedBox(height: 12),
                      Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border.withOpacity(0.5),
                              ),
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
                                Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsFill.sparkle,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Yuki's Vibe Check",
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '“$impression”',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                    const SizedBox(height: 28),

                    // Stats Grid Section
                    _buildHeadline('Core Connection Statistics'),
                    const SizedBox(height: 12),
                    Row(
                          children: [
                            Expanded(
                              child: _buildStatBlock(
                                icon: PhosphorIconsRegular.shieldCheck,
                                title: 'E2EE Sync',
                                value: 'Active',
                                iconColor: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatBlock(
                                icon: PhosphorIconsRegular.database,
                                title: 'Core Memory',
                                value: '100% Synced',
                                iconColor: AppColors.accent,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),

                    // Bottom Management Buttons
                    Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Direct messaging route
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DirectChatScreen(
                                        otherUserId: userId,
                                        otherUsername: username,
                                        otherUserFullName: fullName,
                                      ),
                                    ),
                                    (route) => route.isFirst,
                                  );
                                },
                                icon: const Icon(
                                  PhosphorIconsRegular.chatCircle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Send Message',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmation(context, provider),
                              icon: Icon(
                                PhosphorIconsRegular.trash,
                                color: AppColors.danger,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.danger.withOpacity(
                                  0.12,
                                ),
                                padding: const EdgeInsets.all(18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppColors.danger.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 450.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBlock({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DirectChatProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Chat?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete all messages? This cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                provider.clearChat(userId);
                Navigator.pop(ctx);
                PremiumToast.show(
                  context,
                  message: 'Chat history cleared.',
                  icon: PhosphorIconsRegular.trash,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPreview(
    BuildContext context,
    String? profilePic,
    String displayName,
  ) {
    AvatarPreviewHelper.show(
      context,
      profilePic: profilePic,
      displayName: displayName,
    );
  }
}
