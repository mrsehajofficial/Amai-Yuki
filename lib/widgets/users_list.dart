// users_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/direct_chat_provider.dart';
import '../screens/direct/direct_chat_screen.dart';
import '../core/utils/avatar_helper.dart';

class UsersList extends StatelessWidget {
  const UsersList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();
    final users = provider.favoriteUsers;

    if (provider.isLoadingUsers && users.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (users.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No favorites added yet. Open a profile to add!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final displayName = (user.fullName != null && user.fullName!.isNotEmpty) ? user.fullName! : user.username;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectChatScreen(
                    otherUserId: user.id,
                    otherUsername: user.username,
                    otherUserFullName: user.fullName,
                  ),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.accent.withOpacity(0.2), AppColors.accent.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: AppColors.borderHigh),
                          image: user.profilePic != null && user.profilePic!.isNotEmpty
                              ? DecorationImage(image: AvatarHelper.getAvatarProvider(user.profilePic!), fit: BoxFit.cover) 
                              : null,
                        ),
                        child: user.profilePic == null || user.profilePic!.isEmpty ? Center(
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ) : null,
                      ),
                      if (user.isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                              boxShadow: [
                                BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
