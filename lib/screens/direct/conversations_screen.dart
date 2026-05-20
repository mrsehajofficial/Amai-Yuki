// conversations_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/direct_chat_provider.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/users_list.dart';
import '../../core/utils/avatar_helper.dart';
import 'direct_chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DirectChatProvider>().fetchUsers();
      context.read<DirectChatProvider>().refreshConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Header spacer
                
                if (!_showSearch) ...[
                  // Users Horizontal List
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('Favorites', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
                        ),
                        const UsersList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Conversations List
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text('Messages', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),

                  if (provider.isLoadingConversations && provider.conversations.isEmpty)
                    SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
                  else if (provider.conversations.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.chatCircleDots, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No messages yet.', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ).animate().fadeIn(),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = provider.conversations[index];
                          return ConversationTile(
                            conversation: conv,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DirectChatScreen(
                                    otherUserId: conv.otherUserId,
                                    otherUsername: conv.otherUsername,
                                    otherUserFullName: conv.otherUserFullName,
                                  ),
                                ),
                              );
                            },
                          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                        },
                        childCount: provider.conversations.length,
                      ),
                    ),
                ] else ...[
                  // Search Results
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text('Search Results', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                  if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty)
                    SliverFillRemaining(
                      child: Center(child: Text('No users found.', style: TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = provider.searchResults[index];
                          return _SearchUserTile(user: user);
                        },
                        childCount: provider.searchResults.length,
                      ),
                    ),
                ],
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom spacer for dock
              ],
            ),
          ),

          // Glassy Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5, bottom: 15, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.7),
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: AnimatedSwitcher(
                    duration: 300.ms,
                    child: _showSearch 
                      ? Row(
                          key: const ValueKey('searchBar'),
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
                              onPressed: () {
                                setState(() {
                                  _showSearch = false;
                                  _searchController.clear();
                                  provider.clearSearch();
                                });
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(hintText: 'Search users...', hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none),
                                onChanged: (val) => provider.searchUsers(val),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('headerTitle'),
                          children: [
                            Text('Direct Chat', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.textPrimary),
                              onPressed: () => setState(() => _showSearch = true),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchUserTile extends StatelessWidget {
  final UserModel user;
  const _SearchUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = (user.fullName != null && user.fullName!.isNotEmpty) ? user.fullName! : user.username;

    return ListTile(
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
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceHigh,
            backgroundImage: user.profilePic != null ? AvatarHelper.getAvatarProvider(user.profilePic!) : null,
            child: user.profilePic == null ? Text(displayName[0].toUpperCase(), style: TextStyle(color: AppColors.accent)) : null,
          ),
          if (user.isOnline)
            Positioned(
              right: 0, bottom: 0,
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2))),
            ),
        ],
      ),
      title: Text(displayName, style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(user.isOnline ? 'Online' : 'Offline', style: TextStyle(color: user.isOnline ? AppColors.success : AppColors.textMuted, fontSize: 12)),
      trailing: Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted, size: 16),
    );
  }
}
