// conversation_context_menu.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import '../providers/direct_chat_provider.dart';
import '../screens/direct/direct_chat_screen.dart';
import '../screens/direct/user_profile_screen.dart';
import '../core/utils/avatar_helper.dart';
import 'premium_toast.dart';
import 'avatar_preview_helper.dart'; // Centralized avatar preview helper - SV

/// A premium context menu for conversations, matching the exact visual architecture of MessageContextMenu.
class ConversationContextMenu extends StatelessWidget {
  final ConversationModel conversation;

  const ConversationContextMenu({super.key, required this.conversation});

  /// Static helper to trigger the context menu dialog beautifully.
  static void show(BuildContext context, {required ConversationModel conversation}) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Context Menu',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return ConversationContextMenu(conversation: conversation);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * anim1.value,
            sigmaY: 8.0 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: anim1,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final provider = context.watch<DirectChatProvider>();
    final isFav = provider.isFavorite(conversation.otherUserId);
    final displayName = (conversation.otherUserFullName != null && conversation.otherUserFullName!.isNotEmpty)
        ? conversation.otherUserFullName!
        : conversation.otherUsername;

    // Resolve yukiImpression reactively
    UserModel? userModel;
    try {
      userModel = provider.users.firstWhere((u) => u.id == conversation.otherUserId);
    } catch (_) {}
    final impression = userModel?.yukiImpression;
    final profilePic = userModel?.profilePic ?? conversation.otherUserProfilePic; // Dynamic live resolution - SV

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Glassmorphic Action Menu Card
              Container(
                width: screenWidth - 48,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Section 1: Conversation details header (matching message context style!)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surfaceHigh.withOpacity(0.5),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (profilePic != null && profilePic.isNotEmpty) {
                                  Navigator.pop(context); // Dismiss context menu before opening overlay - SV
                                  AvatarPreviewHelper.show(
                                    context,
                                    profilePic: profilePic,
                                    displayName: displayName,
                                  );
                                }
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceHigh,
                                      border: Border.all(color: AppColors.border, width: 1.2),
                                      image: profilePic != null 
                                          ? DecorationImage(image: AvatarHelper.getAvatarProvider(profilePic), fit: BoxFit.cover) 
                                          : null,
                                    ),
                                    child: profilePic == null ? Center(
                                      child: Text(
                                        displayName[0].toUpperCase(),
                                        style: TextStyle(color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ) : null,
                                  ),
                                  if (conversation.otherUserIsOnline)
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.background, width: 2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CONVERSATION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${conversation.otherUsername}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: AppColors.border, height: 1),

                      // Section 2: Actions list (exact same _MenuActionItem architecture!)
                      _MenuActionItem(
                        icon: PhosphorIconsRegular.chatCircle,
                        label: 'Direct Chat',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectChatScreen(
                                otherUserId: conversation.otherUserId,
                                otherUsername: conversation.otherUsername,
                                otherUserFullName: conversation.otherUserFullName,
                              ),
                            ),
                          );
                        },
                      ),
                      _MenuActionItem(
                        icon: PhosphorIconsRegular.user,
                        label: 'View Full Profile',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: conversation.otherUserId,
                                username: conversation.otherUsername,
                                fullName: conversation.otherUserFullName,
                                email: conversation.otherUserEmail,
                              ),
                            ),
                          );
                        },
                      ),
                      _MenuActionItem(
                        icon: isFav ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        label: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                        iconColor: isFav ? Colors.amber : null,
                        onTap: () {
                          Navigator.pop(context);
                          provider.toggleFavorite(conversation.otherUserId);
                          PremiumToast.show(
                            context,
                            message: isFav ? 'Removed from favorites' : 'Added to favorites!',
                            icon: isFav ? PhosphorIconsRegular.star : PhosphorIconsFill.star,
                          );
                        },
                      ),

                      // Section 3: Yuki's Vibe Check Capsule (matching delivery stats design style!)
                      if (impression != null && impression.isNotEmpty) ...[
                        Divider(color: AppColors.border, height: 1),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: AppColors.background.withOpacity(0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(PhosphorIconsFill.sparkle, color: AppColors.accent, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    "YUKI'S VIBE CHECK",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '“$impression”',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Section 4: Deletion
                      Divider(color: AppColors.border, height: 1),
                      _MenuActionItem(
                        icon: PhosphorIconsRegular.trash,
                        label: 'Delete Chat History',
                        color: AppColors.danger,
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(context, provider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tap anywhere outside indicator
              Text(
                'Tap anywhere outside to close',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  /// Verification prompt to verify safety of chat deletion
  void _showDeleteConfirmation(BuildContext context, DirectChatProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Chat?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete all messages? This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                provider.clearChat(conversation.otherUserId);
                Navigator.pop(ctx);
                PremiumToast.show(
                  context,
                  message: 'Chat history cleared.',
                  icon: PhosphorIconsRegular.trash,
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom context menu action button designed with glassmorphic touch states.
class _MenuActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _MenuActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashColor: AppColors.accent.withOpacity(0.1),
        highlightColor: AppColors.accent.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? color ?? AppColors.textPrimary, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                PhosphorIconsRegular.caretRight,
                color: (color ?? AppColors.textMuted).withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
