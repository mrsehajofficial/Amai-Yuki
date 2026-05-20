// direct_chat_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/direct_chat_provider.dart';
import '../../models/user_model.dart';
import '../../models/conversation_model.dart';
import '../../models/direct_message_model.dart';
import '../../models/message_status.dart';
import '../../widgets/message_context_menu.dart';
import '../../widgets/premium_toast.dart';
import 'user_profile_screen.dart';
import '../../widgets/avatar_preview_helper.dart'; // Centralized avatar zoom preview helper - SV
import '../../core/utils/date_formatter.dart';
import '../../core/utils/avatar_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../camera/camera_screen.dart';
import 'package:http/http.dart' as http;
import '../../services/file_upload_service.dart';

class DirectChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;
  final String? otherUserFullName;

  const DirectChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserFullName,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late DirectChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DirectChatProvider>().setActiveChat(widget.otherUserId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the provider reference in lifecycle hooks so it is safely accessible inside dispose. - SV
    _chatProvider = Provider.of<DirectChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    // Set active chat to null when leaving. This cleans up unread checks and ensures
    // notifications trigger correctly if they message us later when the chat is closed. - SV
    _chatProvider.setActiveChat(null);
    super.dispose();
  }

  void _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    final success = await context.read<DirectChatProvider>().sendMessage(
      widget.otherUserId,
      text,
    );
    if (success) {
      _inputController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showP2PSharePortal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _P2PSharePortalSheet(
        otherUserId: widget.otherUserId,
        onFileSent: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: 300.ms,
              curve: Curves.easeOut,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();
    final auth = context.watch<AuthProvider>();

    // Find conversation details if available to prioritize the full name
    ConversationModel? convo;
    try {
      convo = provider.conversations.firstWhere(
        (c) => c.otherUserId == widget.otherUserId,
      );
    } catch (_) {}
    final displayName =
        (widget.otherUserFullName != null &&
            widget.otherUserFullName!.isNotEmpty)
        ? widget.otherUserFullName!
        : ((convo?.otherUserFullName != null &&
                  convo!.otherUserFullName!.isNotEmpty)
              ? convo.otherUserFullName!
              : widget.otherUsername);

    // Robustly resolve the profile picture. We check the global user sync cache
    // first so that if they open chat from Search, their avatar is displayed instantly!
    // If not in cache, fallback gracefully to the active conversation object. - SV
    UserModel? companionUser;
    try {
      companionUser = provider.users.firstWhere(
        (u) => u.id == widget.otherUserId,
      );
    } catch (_) {}
    final profilePic = companionUser?.profilePic ?? convo?.otherUserProfilePic;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Chat Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // Header spacer
                Expanded(
                  child:
                      provider.isLoadingHistory &&
                          provider.currentHistory.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : provider.currentHistory.isEmpty
                      ? Center(
                          child: Text(
                            'Start a conversation with $displayName',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: provider.currentHistory.length,
                          itemBuilder: (context, index) {
                            final msg = provider.currentHistory[index];
                            final isMe = msg.isMe(auth.user?.id ?? '');
                            return _DirectMessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                )
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                        ),
                ),
                // Input Area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Direct P2P File Share trigger - SV
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: Icon(
                            PhosphorIconsRegular.plus,
                            color: AppColors.accent,
                            size: 22,
                          ),
                          tooltip: 'Direct P2P File Share',
                          onPressed: _showP2PSharePortal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _inputController,
                            maxLines: auth.enterToSend ? null : 5,
                            minLines: 1,
                            textInputAction: auth.enterToSend
                                ? TextInputAction.send
                                : TextInputAction.newline,
                            onSubmitted: auth.enterToSend
                                ? (_) => _handleSend()
                                : null,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            PhosphorIconsFill.paperPlaneTilt,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Glassy Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 5,
                      bottom: 10,
                      left: 10,
                      right: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.7),
                      border: Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            PhosphorIconsRegular.caretLeft,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {
                            context.read<DirectChatProvider>().setActiveChat(
                              null,
                            );
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final provider = context.read<DirectChatProvider>();
                            // Find conversation details if available
                            final convo = provider.conversations.firstWhere(
                              (c) => c.otherUserId == widget.otherUserId,
                              orElse: () => ConversationModel(
                                otherUserId: widget.otherUserId,
                                otherUsername: widget.otherUsername,
                                otherUserIsOnline: false,
                                lastMessage: '',
                                timestamp: DateTime.now(),
                                unreadCount: 0,
                              ),
                            );

                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => UserProfileSheet(
                                userId: widget.otherUserId,
                                username: widget.otherUsername,
                                fullName: convo.otherUserFullName,
                                email: convo.otherUserEmail,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.surfaceHigh,
                                backgroundImage:
                                    profilePic != null && profilePic.isNotEmpty
                                    ? AvatarHelper.getAvatarProvider(profilePic)
                                    : null,
                                child: profilePic == null || profilePic.isEmpty
                                    ? Text(
                                        displayName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Direct Message',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(
                            PhosphorIconsRegular.dotsThreeVertical,
                            color: AppColors.textPrimary,
                          ),
                          color: AppColors.surfaceHigh,
                          onSelected: (val) {
                            if (val == 'clear')
                              provider.clearChat(widget.otherUserId);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'clear',
                              child: Text(
                                'Clear Chat',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
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

class _DirectMessageBubble extends StatelessWidget {
  final DirectMessageModel message;
  final bool isMe;

  const _DirectMessageBubble({required this.message, required this.isMe});

  /// Resolves the absolute correct Phosphor icon based on file type extensions.
  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return PhosphorIconsRegular.filePdf;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return PhosphorIconsRegular.fileArchive;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'heic':
        return PhosphorIconsRegular.fileImage;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return PhosphorIconsRegular.fileVideo;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return PhosphorIconsRegular.fileAudio;
      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'csv':
        return PhosphorIconsRegular.fileText;
      case 'doc':
      case 'docx':
        return PhosphorIconsRegular.fileDoc;
      case 'xls':
      case 'xlsx':
        return PhosphorIconsRegular.file;
      case 'ppt':
      case 'pptx':
        return PhosphorIconsRegular.file;
      default:
        return PhosphorIconsRegular.file;
    }
  }

  /// Automatically saves files into a categorized Amai Yuki folder without opening the file picker - SV
  Future<void> _saveFileToDisk(
    BuildContext context,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      if (kIsWeb) {
        // On Web, we must still use FilePicker to trigger the browser download
        // since we cannot write to a local file system directly.
        await FilePicker.saveFile(
          dialogTitle: 'Save downloaded file as...',
          fileName: fileName,
          bytes: bytes,
        );
        return;
      }

      Directory? baseDir;
      if (Platform.isAndroid) {
        // Hardcode the public standard Android Download directory to escape the app sandbox
        baseDir = Directory('/storage/emulated/0/');
      } else if (Platform.isIOS) {
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getDownloadsDirectory();
        baseDir ??= await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) {
        throw Exception("Could not resolve a base directory for saving.");
      }

      // Determine category folder
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';
      String category = 'Others';

      if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'].contains(ext)) {
        category = 'Images';
      } else if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) {
        category = 'Videos';
      } else if (['mp3', 'wav', 'm4a', 'flac'].contains(ext)) {
        category = 'Audio';
      } else if ([
        'pdf',
        'doc',
        'docx',
        'txt',
        'md',
        'json',
        'xml',
        'csv',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'zip',
        'rar',
        '7z',
      ].contains(ext)) {
        category = 'Documents';
      }

      // Build path: BaseDir / Amai Yuki Downloads / Category
      final saveDir = Directory(p.join(baseDir.path, 'Yuki Files', category));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Ensure unique filename
      String finalFileName = fileName;
      File saveFile = File(p.join(saveDir.path, finalFileName));
      int counter = 1;

      while (await saveFile.exists()) {
        final nameWithoutExt = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        final extensionPart = fileName.contains('.') ? '.$ext' : '';
        finalFileName = '${nameWithoutExt}_$counter$extensionPart';
        saveFile = File(p.join(saveDir.path, finalFileName));
        counter++;
      }

      await saveFile.writeAsBytes(bytes);

      if (context.mounted) {
        PremiumToast.show(
          context,
          message: 'Saved to $category successfully! 🎉',
          icon: PhosphorIconsRegular.checkCircle,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PremiumToast.show(
          context,
          message: 'Failed to auto-save file: $e',
          icon: PhosphorIconsRegular.warning,
        );
      }
    }
  }

  Future<void> _downloadAndSaveFile(
    BuildContext context,
    String fileName,
    String url,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DownloadProgressDialog(
          url: url,
          fileName: fileName,
          onDownloadComplete: (bytes) async {
            Navigator.pop(dialogContext); // Close progress dialog
            await _saveFileToDisk(context, fileName, bytes);
          },
          onDownloadFailed: (error) {
            Navigator.pop(dialogContext); // Close progress dialog
            PremiumToast.show(
              context,
              message: 'Download failed: $error',
              icon: PhosphorIconsRegular.warning,
            );
          },
        );
      },
    );
  }

  String _sanitizeUrl(String url) {
    if (url.startsWith('https:/') && !url.startsWith('https://')) {
      return url.replaceFirst('https:/', 'https://');
    }
    if (url.startsWith('http:/') && !url.startsWith('http://')) {
      return url.replaceFirst('http:/', 'http://');
    }
    return url;
  }

  void _downloadDirectFile(
    BuildContext context,
    String fileName,
    String payload,
  ) {
    try {
      final isUrl = payload.startsWith('http');
      final sanitizedPayload = isUrl ? _sanitizeUrl(payload) : payload;
      final Uint8List bytes = isUrl
          ? Uint8List(0)
          : base64Decode(sanitizedPayload);
      final ext = fileName.split('.').last.toLowerCase();
      final isImage = [
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
        'heic',
      ].contains(ext);

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          title: Row(
            children: [
              Icon(_getFileIcon(fileName), color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  PhosphorIconsRegular.x,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: isUrl
                        ? Image.network(
                            sanitizedPayload,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.accent,
                                ),
                              );
                            },
                          )
                        : Image.memory(bytes, fit: BoxFit.contain),
                  ),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    _getFileIcon(fileName),
                    color: AppColors.accent,
                    size: 48,
                  ),
                ),
              const SizedBox(height: 16),
              if (!isImage) ...[
                Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                isUrl
                    ? 'Cloud stored secure file link.'
                    : 'Direct-transferred encrypted data in-memory.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: Icon(
                PhosphorIconsRegular.downloadSimple,
                color: AppColors.accent,
              ),
              label: Text(
                'Save to Device',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                if (isUrl) {
                  await _downloadAndSaveFile(
                    context,
                    fileName,
                    sanitizedPayload,
                  );
                } else {
                  await _saveFileToDisk(context, fileName, bytes);
                }
              },
            ),
            TextButton.icon(
              icon: Icon(PhosphorIconsRegular.check, color: AppColors.success),
              label: Text(
                'Done',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
      );

      PremiumToast.show(
        context,
        message: 'File preview opened successfully!',
        icon: PhosphorIconsRegular.checkCircle,
      );
    } catch (e) {
      PremiumToast.show(
        context,
        message: 'Failed to parse file: $e',
        icon: PhosphorIconsRegular.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? systemData;
    if (message.content.startsWith('{"__yuki_system__":')) {
      try {
        systemData = jsonDecode(message.content) as Map<String, dynamic>;
      } catch (_) {}
    }

    final isP2PShare =
        systemData != null && systemData['type'] == 'p2p_file_share';

    if (isP2PShare) {
      final fileName = systemData['fileName'] as String? ?? 'Shared File';
      final fileSizeInt = systemData['fileSize'] as int? ?? 0;
      final payload = systemData['payload'] as String? ?? '';

      // Format file size nicely
      String fileSizeStr = '${(fileSizeInt / 1024).toStringAsFixed(1)} KB';
      if (fileSizeInt > 1024 * 1024) {
        fileSizeStr = '${(fileSizeInt / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            MessageContextMenu.show(
              context,
              content: message.content,
              isMe: isMe,
              timestamp: message.timestamp,
              status: isMe ? message.status : null,
              onReactionSelected: (emoji) {
                context.read<DirectChatProvider>().reactToMessage(
                  message.id,
                  emoji,
                );
              },
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 16,
                  right: isMe ? 16 : 64,
                  bottom: 8,
                ),
                width: 280,
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.surfaceHigh.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMe
                        ? AppColors.accent.withOpacity(0.25)
                        : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File name and details - SV
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Icon(
                                  _getFileIcon(fileName),
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileSizeStr,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Download or View trigger - SV
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.background,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                PhosphorIconsRegular.eye,
                                size: 16,
                              ),
                              label: const Text(
                                'View File',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => _downloadDirectFile(
                                context,
                                fileName,
                                payload,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (message.reaction != null && message.reaction!.isNotEmpty)
                Positioned(
                  bottom: 2,
                  right: isMe ? 24 : null,
                  left: !isMe ? 24 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.reaction!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Wrap bubble in GestureDetector for custom press-and-hold context menu
          GestureDetector(
            onLongPress: () {
              MessageContextMenu.show(
                context,
                content: message.content,
                isMe: isMe,
                timestamp: message.timestamp,
                status: isMe ? message.status : null,
                onReactionSelected: (emoji) {
                  context.read<DirectChatProvider>().reactToMessage(
                    message.id,
                    emoji,
                  );
                },
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    left: isMe ? 64 : 16,
                    right: isMe ? 16 : 64,
                    bottom: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    // Giving user messages a premium glassmorphic feel, matching UserMessageBubble
                    color: isMe
                        ? AppColors.accent.withOpacity(0.15)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? Border.all(
                            color: AppColors.accent.withOpacity(0.20),
                            width: 1,
                          )
                        : Border.all(color: AppColors.border),
                    boxShadow: isMe
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: MarkdownBody(
                    data: message.content,
                    selectable:
                        false, // Context menu handles copy/select perfectly
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isMe
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        color: isMe ? AppColors.accent : AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (message.reaction != null && message.reaction!.isNotEmpty)
                  Positioned(
                    bottom: -2,
                    right: isMe ? 24 : null,
                    left: !isMe ? 24 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.reaction!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Metadata row: timestamp and delivery checks (only for messages sent by current user)
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 20,
              right: isMe ? 20 : 0,
              bottom: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatMessageTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIndicator(context, message.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build checkmarks based on message status (sending, sent, received, seen)
  Widget _buildStatusIndicator(BuildContext context, MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textMuted.withOpacity(0.6),
            ),
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
          color:
              AppColors.accent, // Neon cyan/accent blue indicating read receipt
        );
    }
  }
}

class UserProfileSheet extends StatelessWidget {
  final String userId;
  final String username;
  final String? fullName;
  final String? email;

  const UserProfileSheet({
    required this.userId,
    required this.username,
    this.fullName,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();

    // Resolve conversation details for the user to pull online status and images - SV
    ConversationModel? convo;
    try {
      convo = provider.conversations.firstWhere((c) => c.otherUserId == userId);
    } catch (_) {}

    // Check if the user exists in the local cache, resolving details like custom avatars - SV
    UserModel? userModel;
    try {
      userModel = provider.users.firstWhere((u) => u.id == userId);
    } catch (_) {}

    final profilePic = userModel?.profilePic ?? convo?.otherUserProfilePic;

    // Robustly resolve the email address from either the global user cache,
    // active conversation details, or constructor parameters. - SV
    final resolvedEmail =
        (userModel?.email != null && userModel!.email.isNotEmpty)
        ? userModel.email
        : ((convo?.otherUserEmail != null && convo!.otherUserEmail!.isNotEmpty)
              ? convo.otherUserEmail
              : email);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          // High-end glassmorphic avatar with real-time profile picture sync - SV
          GestureDetector(
            onTap: () {
              if (profilePic != null && profilePic.isNotEmpty) {
                Navigator.pop(context); // Close the bottom sheet summary first - SV
                AvatarPreviewHelper.show(
                  context,
                  profilePic: profilePic,
                  displayName: fullName ?? username,
                );
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceHigh,
                border: Border.all(color: AppColors.accent, width: 2),
                image: profilePic != null && profilePic.isNotEmpty
                    ? DecorationImage(
                        image: AvatarHelper.getAvatarProvider(profilePic),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: profilePic == null || profilePic.isEmpty
                  ? Text(
                      (fullName ?? username)[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName ?? username,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (fullName != null) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),

          // Info List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ProfileInfoRow(
                  icon: PhosphorIconsRegular.user,
                  label: 'Username',
                  value: username,
                ),
                if (fullName != null) ...[
                  Divider(color: AppColors.border, height: 24),
                  _ProfileInfoRow(
                    icon: PhosphorIconsRegular.identificationCard,
                    label: 'Full Name',
                    value: fullName!,
                  ),
                ],
                if (resolvedEmail != null && resolvedEmail.isNotEmpty) ...[
                  Divider(color: AppColors.border, height: 24),
                  _ProfileInfoRow(
                    icon: PhosphorIconsRegular.envelopeSimple,
                    label: 'Email',
                    value: resolvedEmail,
                  ),
                ],
              ],
            ),
          ),

          // Yuki's Vibe Check Card
          Builder(
            builder: (context) {
              final provider = context.watch<DirectChatProvider>();
              UserModel? userModel;
              try {
                userModel = provider.users.firstWhere((u) => u.id == userId);
              } catch (_) {}
              final impression = userModel?.yukiImpression;

              if (impression == null || impression.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.12),
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
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Yuki's Vibe Check",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '“$impression”',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Builder(
            builder: (context) {
              final provider = context.watch<DirectChatProvider>();
              final isFav = provider.isFavorite(userId);

              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
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
                    isFav ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                    color: isFav ? Colors.amber : AppColors.textPrimary,
                  ),
                  label: Text(
                    isFav ? 'Remove from Favorites' : 'Add to Favorites',
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
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(
                      userId: userId,
                      username: username,
                      fullName: fullName,
                      email: email,
                    ),
                  ),
                );
              },
              icon: const Icon(
                PhosphorIconsRegular.identificationCard,
                color: Colors.white,
              ),
              label: const Text(
                'Full Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _P2PSharePortalSheet extends StatefulWidget {
  final String otherUserId;
  final VoidCallback onFileSent;

  const _P2PSharePortalSheet({
    required this.otherUserId,
    required this.onFileSent,
  });

  @override
  State<_P2PSharePortalSheet> createState() => _P2PSharePortalSheetState();
}

class _P2PSharePortalSheetState extends State<_P2PSharePortalSheet> {
  bool _isLoading = false;
  String? _selectedFileName;
  int? _fileSize;
  String? _filePath;
  Uint8List? _fileBytes;

  /// Resolves the absolute correct Phosphor icon based on file type extensions.
  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return PhosphorIconsRegular.filePdf;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return PhosphorIconsRegular.fileArchive;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'heic':
        return PhosphorIconsRegular.fileImage;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return PhosphorIconsRegular.fileVideo;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return PhosphorIconsRegular.fileAudio;
      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'csv':
        return PhosphorIconsRegular.fileText;
      case 'doc':
      case 'docx':
        return PhosphorIconsRegular.fileDoc;
      case 'xls':
      case 'xlsx':
        return PhosphorIconsRegular.file;
      case 'ppt':
      case 'pptx':
        return PhosphorIconsRegular.file;
      default:
        return PhosphorIconsRegular.file;
    }
  }

  /// Select document/generic file type using file_picker - SV
  void _pickDocument() async {
    try {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();

      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final PlatformFile file = result.files.first;

      setState(() {
        _selectedFileName = file.name;
        _fileSize = file.size;
        _filePath = file.path;
        _fileBytes = file.bytes;
        _isLoading = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      PremiumToast.show(
        context,
        message: 'Error picking file: $e',
        icon: PhosphorIconsRegular.warning,
      );
    }
  }

  /// Select image from gallery using file_picker - SV
  void _pickGalleryPhoto() async {
    try {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();

      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final PlatformFile file = result.files.first;

      setState(() {
        _selectedFileName = file.name;
        _fileSize = file.size;
        _filePath = file.path;
        _fileBytes = file.bytes;
        _isLoading = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      PremiumToast.show(
        context,
        message: 'Error picking photo: $e',
        icon: PhosphorIconsRegular.warning,
      );
    }
  }

  /// Open internal high-fidelity custom camera - SV
  void _openYukiCamera() async {
    try {
      HapticFeedback.lightImpact();

      final XFile? capturedFile = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
      );

      if (capturedFile == null) return;

      setState(() => _isLoading = true);

      final bytes = await capturedFile.readAsBytes();

      setState(() {
        _selectedFileName = capturedFile.name;
        _fileSize = bytes.length;
        _filePath = capturedFile.path;
        _fileBytes = bytes;
        _isLoading = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      PremiumToast.show(
        context,
        message: 'Camera capture failed: $e',
        icon: PhosphorIconsRegular.warning,
      );
    }
  }

  void _sendShare() async {
    if (_selectedFileName == null || (_filePath == null && _fileBytes == null))
      return;

    try {
      setState(() => _isLoading = true);

      // Upload file to Catbox storage instead of encoding to base64
      final uploadUrl = await FileUploadService.uploadFile(
        fileName: _selectedFileName!,
        filePath: _filePath,
        fileBytes: _fileBytes,
      );

      if (uploadUrl == null) {
        throw Exception('Failed to upload file to the storage server.');
      }

      // Build the secure URL-based system message payload - SV
      final payload = jsonEncode({
        '__yuki_system__': true,
        'type': 'p2p_file_share',
        'fileName': _selectedFileName,
        'fileSize': _fileSize,
        'payload': uploadUrl,
      });

      await context.read<DirectChatProvider>().sendMessage(
        widget.otherUserId,
        payload,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onFileSent();
        PremiumToast.show(
          context,
          message: 'Direct link share sent!',
          icon: PhosphorIconsRegular.paperPlaneTilt,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      PremiumToast.show(
        context,
        message: 'Send failed: $e',
        icon: PhosphorIconsRegular.warning,
      );
    }
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? customColor,
  }) {
    final activeColor = customColor ?? AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColors.surface.withOpacity(0.4),
          child: InkWell(
            onTap: onTap,
            splashColor: activeColor.withOpacity(0.12),
            highlightColor: activeColor.withOpacity(0.06),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: activeColor.withOpacity(0.24)),
                    ),
                    child: Icon(icon, color: activeColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
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
      ),
    );
  }

  Widget _buildSelectedFileCard(String fileSizeStr) {
    if (_selectedFileName == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  _getFileIcon(_selectedFileName!),
                  color: AppColors.accent,
                  size: 38,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1.02, 1.02),
                duration: 2.seconds,
              ),
          const SizedBox(height: 16),
          Text(
            _selectedFileName!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fileSizeStr,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: Icon(
              PhosphorIconsRegular.trash,
              color: AppColors.danger,
              size: 16,
            ),
            label: Text(
              'Remove File',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedFileName = null;
                _fileSize = null;
                _filePath = null;
                _fileBytes = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectChatProvider>();
    UserModel? companionUser;
    try {
      companionUser = provider.users.firstWhere(
        (u) => u.id == widget.otherUserId,
      );
    } catch (_) {}
    final isOnline = companionUser?.isOnline ?? false;

    // Format file size nicely - SV
    String fileSizeStr = '';
    if (_fileSize != null) {
      fileSizeStr = '${(_fileSize! / 1024).toStringAsFixed(1)} KB';
      if (_fileSize! > 1024 * 1024) {
        fileSizeStr = '${(_fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upper handle - SV
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Portal Header - SV
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsRegular.file,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share File',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select a file to send directly to your chat.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.x,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // RECIPIENT OFFLINE WARNING - SV
                  if (!isOnline) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.cloudSlash,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Recipient is currently offline. Your file will be delivered once they log back online.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Options List or Selected File Card
                  _isLoading
                      ? Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : _selectedFileName != null
                      ? _buildSelectedFileCard(fileSizeStr)
                      : Column(
                          children: [
                            _buildOptionCard(
                              icon: PhosphorIconsFill.camera,
                              title: 'Open Custom Camera',
                              subtitle:
                                  'Snap a picture with in-app dual camera support',
                              onTap: _openYukiCamera,
                              customColor: const Color(0xFFFF5252),
                            ),
                            _buildOptionCard(
                              icon: PhosphorIconsFill.image,
                              title: 'Choose from Gallery',
                              subtitle:
                                  'Select existing photos or videos from camera roll',
                              onTap: _pickGalleryPhoto,
                              customColor: const Color(0xFFE040FB),
                            ),
                            _buildOptionCard(
                              icon: PhosphorIconsFill.folderOpen,
                              title: 'Upload Any Document',
                              subtitle:
                                  'Send PDFs, Zip, text archives, audio, or other files',
                              onTap: _pickDocument,
                              customColor: AppColors.accent,
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // Send Action button - SV
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedFileName == null
                            ? AppColors.surfaceHigh
                            : AppColors.accent,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: AppColors.surfaceHigh,
                      ),
                      icon: Icon(
                        PhosphorIconsRegular.paperPlaneTilt,
                        size: 18,
                        color: _selectedFileName == null
                            ? AppColors.textMuted
                            : AppColors.background,
                      ),
                      label: Text(
                        'Send File',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _selectedFileName == null
                              ? AppColors.textMuted
                              : AppColors.background,
                        ),
                      ),
                      onPressed: (_selectedFileName == null || _isLoading)
                          ? null
                          : _sendShare,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    const double dashWidth = 8;
    const double dashSpace = 6;
    double distance = 0.0;

    for (var pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final Function(Uint8List) onDownloadComplete;
  final Function(String) onDownloadFailed;

  const _DownloadProgressDialog({
    required this.url,
    required this.fileName,
    required this.onDownloadComplete,
    required this.onDownloadFailed,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  final List<int> _bytes = [];

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        widget.onDownloadFailed(
          'Server returned status ${response.statusCode}',
        );
        return;
      }

      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      response.stream.listen(
        (chunk) {
          _bytes.addAll(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            setState(() {
              _progress = downloaded / contentLength;
            });
          }
        },
        onDone: () {
          client.close();
          widget.onDownloadComplete(Uint8List.fromList(_bytes));
        },
        onError: (e) {
          client.close();
          widget.onDownloadFailed(e.toString());
        },
        cancelOnError: true,
      );
    } catch (e) {
      widget.onDownloadFailed(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.cloudArrowDown,
                  color: AppColors.accent,
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  'Downloading File',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
