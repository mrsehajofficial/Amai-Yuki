// conversation_tile.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/conversation_model.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/avatar_helper.dart';
import 'conversation_context_menu.dart';
import 'package:provider/provider.dart';
import '../providers/direct_chat_provider.dart';
import '../models/user_model.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();

    // Dynamically look up the companion's profile details from the global cached user list
    // to ensure real-time profile picture syncing across the active conversation list. - SV
    UserModel? companionUser;
    try {
      companionUser = provider.users.firstWhere(
        (u) => u.id == conversation.otherUserId,
      );
    } catch (_) {}

    final profilePic =
        companionUser?.profilePic ?? conversation.otherUserProfilePic;

    final displayName =
        (conversation.otherUserFullName != null &&
            conversation.otherUserFullName!.isNotEmpty)
        ? conversation.otherUserFullName!
        : conversation.otherUsername;

    // Clean up P2P file share system JSONs in Messages feed - SV
    String displayLastMessage = conversation.lastMessage;
    if (displayLastMessage.startsWith('{"__yuki_system__":')) {
      displayLastMessage = 'Shared a file';
    }

    // Add reaction prefix if there is an active reaction - SV
    final hasReaction = conversation.lastMessageReaction != null && conversation.lastMessageReaction!.isNotEmpty;
    if (hasReaction) {
      displayLastMessage = '${conversation.lastMessageReaction} $displayLastMessage';
    }

    final hasUnseenReaction = provider.hasUnseenReaction(conversation.otherUserId);
    final isUnread = conversation.unreadCount > 0 || hasUnseenReaction;

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        ConversationContextMenu.show(context, conversation: conversation);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh,
                    border: Border.all(color: AppColors.border),
                    image: profilePic != null && profilePic.isNotEmpty
                        ? DecorationImage(
                            image: AvatarHelper.getAvatarProvider(profilePic),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profilePic == null || profilePic.isEmpty
                      ? Center(
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                if (conversation.otherUserIsOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormatter.formatRelative(conversation.timestamp),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayLastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: conversation.unreadCount > 0 ? 8 : 5,
                            vertical: conversation.unreadCount > 0 ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: conversation.unreadCount > 0 ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: conversation.unreadCount > 0 ? BorderRadius.circular(10) : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: conversation.unreadCount > 0
                              ? Text(
                                  conversation.unreadCount.toString(),
                                  style: TextStyle(
                                    color: AppColors.background,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
