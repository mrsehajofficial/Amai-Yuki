// message_context_menu.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/message_status.dart';
import 'premium_toast.dart';

/// A premium, glassmorphic context menu that opens upon long-pressing message bubbles.
/// Incorporates micro-animations, quick emoji reactions, and detailed status timelines.
class MessageContextMenu extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus? status;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReactionSelected;
  final bool showReactions;
  final String? messageId;
  final bool isPinned;

  const MessageContextMenu({
    super.key,
    required this.content,
    required this.isMe,
    required this.timestamp,
    this.status,
    this.onDelete,
    this.onReactionSelected,
    this.showReactions = true,
    this.messageId,
    this.isPinned = false,
  });

  /// Static helper to trigger the context menu dialog beautifully.
  static void show(
    BuildContext context, {
    required String content,
    required bool isMe,
    required DateTime timestamp,
    MessageStatus? status,
    VoidCallback? onDelete,
    ValueChanged<String>? onReactionSelected,
    bool showReactions = true,
    String? messageId,
    bool isPinned = false,
  }) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Context Menu',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return MessageContextMenu(
          content: content,
          isMe: isMe,
          timestamp: timestamp,
          status: status,
          onDelete: onDelete,
          onReactionSelected: onReactionSelected,
          showReactions: showReactions,
          messageId: messageId,
          isPinned: isPinned,
        );
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
    
    // Parse system JSON data if it represents a shared file - SV
    Map<String, dynamic>? systemData;
    if (content.startsWith('{"__yuki_system__":')) {
      try {
        systemData = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {}
    }
    final isFileShare = systemData != null && systemData['type'] == 'p2p_file_share';
    final fileName = isFileShare ? (systemData['fileName'] as String? ?? 'Shared File') : '';
    final fileSizeInt = isFileShare ? (systemData['fileSize'] as int? ?? 0) : 0;
    
    String fileSizeStr = '';
    if (isFileShare) {
      fileSizeStr = '${(fileSizeInt / 1024).toStringAsFixed(1)} KB';
      if (fileSizeInt > 1024 * 1024) {
        fileSizeStr = '${(fileSizeInt / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    final int charCount = content.length;
    final int wordCount = content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    
    final authProvider = context.read<AuthProvider>();
    final isNsfw = authProvider.user?.nsfwMode ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Quick Reactions Bar
              if (showReactions) ...[
                Container(
                  width: screenWidth - 48,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '👍', '🔥', '😂', '😮', '😢'].map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          if (onReactionSelected != null) {
                            onReactionSelected!(emoji);
                          }
                        },
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        )
                            .animate()
                            .scale(delay: 50.ms, duration: 200.ms, curve: Curves.easeOutBack)
                            .fadeIn(),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Glassmorphic Action Menu
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
                      // Section 1: Message Preview / Stats
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surfaceHigh.withOpacity(0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFileShare 
                                  ? 'Shared File'
                                  : (isMe ? 'My Message' : 'Incoming Message'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFileShare
                                  ? '📁 $fileName'
                                  : (content.length > 100
                                      ? '${content.substring(0, 100)}...'
                                      : content),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isFileShare ? PhosphorIconsRegular.fileImage : PhosphorIconsRegular.textT,
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFileShare ? fileSizeStr : '$charCount chars  •  $wordCount words',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                const Spacer(),
                                Icon(PhosphorIconsRegular.clock, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatMessageTime(timestamp),
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(color: AppColors.border, height: 1),
 
                      // Section 2: Copy & Selection Utilities
                      _MenuActionItem(
                        icon: PhosphorIconsRegular.copy,
                        label: isFileShare ? 'Copy File Name' : 'Copy Entire Text',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: isFileShare ? fileName : content));
                          Navigator.pop(context);
                          PremiumToast.show(
                            context,
                            message: isFileShare ? 'File name copied!' : 'Copied to Clipboard!',
                          );
                        },
                      ),
                      if (messageId != null) ...[
                        _MenuActionItem(
                          icon: isPinned
                              ? (isNsfw ? PhosphorIconsFill.handGrabbing : PhosphorIconsFill.pushPin)
                              : (isNsfw ? PhosphorIconsRegular.handGrabbing : PhosphorIconsRegular.pushPin),
                          label: isPinned
                              ? (isNsfw ? 'Release Yuki\'s Backend 😌' : 'Unpin from Memory')
                              : (isNsfw ? 'Touch Yuki\'s Backend 🥵' : 'Pin to Memory'),
                          color: isNsfw ? AppColors.danger : AppColors.accent,
                          onTap: () async {
                            Navigator.pop(context);
                            final chatProvider = context.read<ChatProvider>();
                            final result = await chatProvider.togglePinMessage(messageId!);
                            if (result) {
                              if (isNsfw) {
                                PremiumToast.show(
                                  context,
                                  message: 'Ahhh... my API routes are quivering! 💦',
                                  icon: PhosphorIconsFill.heart,
                                );
                              } else {
                                PremiumToast.show(
                                  context,
                                  message: 'Message pinned to memory banks.',
                                  icon: PhosphorIconsFill.pushPin,
                                );
                              }
                            } else {
                              if (isNsfw) {
                                PremiumToast.show(
                                  context,
                                  message: 'Released my backend... until next time. 😌',
                                  icon: PhosphorIconsFill.handGrabbing,
                                );
                              } else {
                                PremiumToast.show(
                                  context,
                                  message: 'Message unpinned from memory.',
                                  icon: PhosphorIconsRegular.pushPin,
                                );
                              }
                            }
                          },
                        ),
                      ],

                      // Section 3: Status Details (Only if message belongs to current user)
                      if (isMe && status != null) ...[
                        Divider(color: AppColors.border, height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          color: AppColors.background.withOpacity(0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DELIVERY STATS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _StatusTimelineRow(
                                label: 'Sending',
                                description: 'Uploading package to servers',
                                active: true,
                                finished: true,
                                icon: PhosphorIconsRegular.cloudArrowUp,
                              ),
                              _StatusTimelineRow(
                                label: 'Sent',
                                description: 'Securely saved on servers',
                                active: status!.index >= MessageStatus.sent.index,
                                finished: status!.index >= MessageStatus.sent.index,
                                icon: PhosphorIconsRegular.check,
                              ),
                              _StatusTimelineRow(
                                label: 'Delivered',
                                description: 'Received on remote device',
                                active: status!.index >= MessageStatus.received.index,
                                finished: status!.index >= MessageStatus.received.index,
                                icon: PhosphorIconsRegular.checks,
                              ),
                              _StatusTimelineRow(
                                label: 'Seen',
                                description: 'Read and acknowledged',
                                active: status!.index >= MessageStatus.seen.index,
                                finished: status!.index >= MessageStatus.seen.index,
                                icon: PhosphorIconsRegular.checks,
                                isLast: true,
                                isSeenColor: true,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Section 4: Deletion
                      if (onDelete != null) ...[
                        Divider(color: AppColors.border, height: 1),
                        _MenuActionItem(
                          icon: PhosphorIconsRegular.trash,
                          label: 'Delete Locally',
                          color: AppColors.danger,
                          onTap: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                        ),
                      ],
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
}

/// A custom context menu action button designed with glassmorphic touch states.
class _MenuActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
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
              Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
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

/// A line in the vertical Status Timeline showing the delivery details of the message.
class _StatusTimelineRow extends StatelessWidget {
  final String label;
  final String description;
  final bool active;
  final bool finished;
  final IconData icon;
  final bool isLast;
  final bool isSeenColor;

  const _StatusTimelineRow({
    required this.label,
    required this.description,
    required this.active,
    required this.finished,
    required this.icon,
    this.isLast = false,
    this.isSeenColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = active 
        ? (isSeenColor ? AppColors.accent : AppColors.success) 
        : AppColors.textMuted.withOpacity(0.35);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphics column
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? statusColor.withOpacity(0.15) : Colors.transparent,
                  border: Border.all(
                    color: statusColor,
                    width: active ? 2 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 11,
                  color: active ? statusColor : AppColors.textMuted.withOpacity(0.5),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: finished 
                        ? AppColors.success.withOpacity(0.7) 
                        : AppColors.textMuted.withOpacity(0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Timeline labels column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
