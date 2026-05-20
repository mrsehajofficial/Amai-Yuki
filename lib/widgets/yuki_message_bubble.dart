// yuki_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/message_model.dart';
import 'loading_dots.dart';
import 'message_context_menu.dart';
import 'premium_toast.dart';

class YukiMessageBubble extends StatelessWidget {
  final MessageModel? message;
  final bool isTyping;
  const YukiMessageBubble({super.key, this.message, this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isNsfw = authProvider.user?.nsfwMode ?? false;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 48.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12, top: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A28),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/yuki_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: isTyping || message == null
                        ? null
                        : () {
                            MessageContextMenu.show(
                              context,
                              content: message!.content,
                              isMe: false,
                              timestamp: message!.createdAt,
                              showReactions: false,
                              messageId: message!.id,
                              isPinned: message!.isPinned,
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: isTyping
                          ? const Padding(padding: EdgeInsets.symmetric(vertical: 6.0), child: LoadingDots())
                          : MarkdownBody(
                              data: message!.content,
                              selectable: false, // Context menu handles copying and details perfectly
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                p: Theme.of(context).textTheme.bodyLarge,
                                strong: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.accent),
                                code: const TextStyle(backgroundColor: Colors.black26, fontFamily: 'monospace', fontSize: 13),
                              ),
                            ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.02, end: 0, curve: Curves.easeOut),
                  if (!isTyping && message != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(message!.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (message!.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            isNsfw ? PhosphorIconsFill.heart : PhosphorIconsFill.pushPin,
                            size: 12,
                            color: isNsfw ? AppColors.danger : AppColors.accent,
                          ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                        ],
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message!.content));
                            PremiumToast.show(context, message: 'Copied to Clipboard!');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(PhosphorIconsRegular.copy, size: 14, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
