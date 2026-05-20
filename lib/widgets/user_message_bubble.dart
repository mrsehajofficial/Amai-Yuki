// user_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/message_model.dart';
import '../models/message_status.dart';
import 'message_context_menu.dart';
import 'premium_toast.dart';

class UserMessageBubble extends StatelessWidget {
  final MessageModel message;
  const UserMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isNsfw = authProvider.user?.nsfwMode ?? false;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 48.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Wrapping in GestureDetector for our signature press-and-hold custom context menu.
            GestureDetector(
              onLongPress: () {
                MessageContextMenu.show(
                  context,
                  content: message.content,
                  isMe: true,
                  timestamp: message.createdAt,
                  status: message.status,
                  showReactions: false,
                  messageId: message.id,
                  isPinned: message.isPinned,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: AppColors.accent.withOpacity(0.20), width: 1),
                ),
                child: MarkdownBody(
                  data: message.content,
                  selectable: false, // Turned off selectable inside bubble since context menu handles text copying perfectly
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: message.content));
                    PremiumToast.show(context, message: 'Copied to Clipboard!');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(PhosphorIconsRegular.copy, size: 14, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 6),
                if (message.isPinned) ...[
                  Icon(
                    isNsfw ? PhosphorIconsFill.heart : PhosphorIconsFill.pushPin,
                    size: 12,
                    color: isNsfw ? AppColors.danger : AppColors.accent,
                  ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 6),
                ],
                Text(
                  DateFormatter.formatMessageTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(width: 6),
                // Premium micro-animated status checks for the current user's message bubble
                _buildStatusIndicator(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a highly polished visual indicator showing the delivery and read state of the message.
  Widget _buildStatusIndicator(BuildContext context) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted.withOpacity(0.6)),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          PhosphorIconsRegular.check,
          size: 13,
          color: AppColors.textMuted.withOpacity(0.6),
        );
      case MessageStatus.received:
        return Icon(
          PhosphorIconsRegular.checks,
          size: 13,
          color: AppColors.textMuted.withOpacity(0.6),
        );
      case MessageStatus.seen:
        return Icon(
          PhosphorIconsRegular.checks,
          size: 13,
          color: AppColors.accent, // Neon cyan/accent blue indicating read receipt
        );
    }
  }
}
