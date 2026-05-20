import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/user_message_bubble.dart';
import '../../widgets/yuki_message_bubble.dart';
import '../../widgets/premium_toast.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend() {
    final text = _inputController.text.trim(); if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text); _inputController.clear();
    if (_scrollController.hasClients) _scrollController.animateTo(0.0, duration: 300.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80), // Header spacer
                Expanded(
                  child: provider.messages.isEmpty && !provider.isSending
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border), image: const DecorationImage(image: AssetImage('assets/images/yuki_icon.png'), fit: BoxFit.cover))).animate().fadeIn(), const SizedBox(height: 16), Text('Say something.', style: TextStyle(color: AppColors.textMuted))]))
                      : ListView.builder(
                          controller: _scrollController, reverse: true, padding: const EdgeInsets.only(top: 16, bottom: 16),
                          itemCount: provider.messages.length + (provider.isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (provider.isSending && index == 0) return const YukiMessageBubble(isTyping: true).animate().fadeIn();
                            final msg = provider.messages[provider.isSending ? index - 1 : index];
                            return msg.isUser ? UserMessageBubble(message: msg) : YukiMessageBubble(message: msg);
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 16, 
                    right: 16, 
                    bottom: (MediaQuery.of(context).viewInsets.bottom + 20).clamp(108.0, 999.0), 
                    top: 8
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08))),
                          child: TextField(
                            controller: _inputController, 
                            maxLines: auth.enterToSend ? null : 5, 
                            minLines: 1, 
                            textInputAction: auth.enterToSend ? TextInputAction.send : TextInputAction.newline,
                            onSubmitted: auth.enterToSend ? (_) => _handleSend() : null,
                            decoration: const InputDecoration(hintText: 'Message Yuki...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(onTap: _handleSend, child: Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(14)), child: Icon(PhosphorIconsFill.paperPlaneTilt, color: AppColors.background))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Glassy Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.7),
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A28),
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/yuki_icon.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Amai Yuki', style: Theme.of(context).textTheme.titleMedium), Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)), const SizedBox(width: 6), Text('online', style: Theme.of(context).textTheme.bodySmall)])])),
                        const SizedBox(width: 12),
                        // Interactive model switch pill on the far right of the header bar
                        _buildModelPill(context, provider),
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

  // --- AI MODEL SELECTOR WIDGETS ---
  // Written by Sehaj Varma (late night sessions + lots of espresso ☕)
  // Intent: Bring the core AI intelligence settings right into the conversational canvas
  // where it actually belongs. This gives our users instant feedback on Yuki's cognitive state.

  /// Returns a shortened, sleek display name for the model pill to keep the app bar minimal.
  String _getModelShortName(String modelId) {
    if (modelId.contains('Chat') || modelId.contains('chat')) return 'Yuki Chat';
    if (modelId.contains('Omni') || modelId.contains('omni')) return 'Yuki Omni';
    if (modelId.contains('2.0')) return 'Yuki 2.0';
    return 'Yuki Core';
  }

  /// Maps the backend model identifier to a descriptive Phosphor icon.
  IconData _getModelIcon(String modelId) {
    if (modelId.contains('Chat') || modelId.contains('chat')) return PhosphorIconsRegular.lightning;
    if (modelId.contains('Omni') || modelId.contains('omni')) return PhosphorIconsRegular.brain;
    if (modelId.contains('2.0')) return PhosphorIconsRegular.flask;
    return PhosphorIconsRegular.cpu;
  }

  /// Elegant glassmorphic pill button displayed on the right of the header bar.
  Widget _buildModelPill(BuildContext context, ChatProvider provider) {
    final activeModel = provider.activeModel;
    final shortName = _getModelShortName(activeModel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showModelSelectionBottomSheet(context, provider),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.accent.withOpacity(0.1),
        highlightColor: AppColors.accent.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getModelIcon(activeModel),
                color: AppColors.accent,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                shortName,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIconsRegular.caretDown,
                color: AppColors.accent,
                size: 11,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  /// Bottom sheet containing beautiful, micro-animated cards for each AI core model.
  void _showModelSelectionBottomSheet(BuildContext context, ChatProvider provider) {
    final auth = context.read<AuthProvider>();
    // Backend returns the dynamic array of model strings. 
    // Fall back to our premium standard selection if it is not populated yet.
    final models = provider.availableModels.isNotEmpty
        ? provider.availableModels
        : const ['LongCat-Flash-Chat-2602-Exp', 'LongCat-Flash-Omni-2603', 'LongCat-2.0-Preview'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.82),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                // Stripped the solid border to achieve a premium, borderless glassmorphism panel.
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative top handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header text
                  Text(
                    'Select AI Core Model',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose the engine that powers Yuki\'s cognitive, emotional, and creative responses.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Map options to rich cards
                  ...models.map((modelId) {
                    final isSelected = provider.activeModel == modelId;
                    return _buildModelSheetCard(
                      context: context,
                      modelId: modelId,
                      isSelected: isSelected,
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Instantly update UI locally
                        provider.setActiveModel(modelId);
                        
                        // Persist setting to storage & send update request to Flask backend
                        final success = await auth.updateSettings(activeModel: modelId);
                        
                        if (context.mounted) {
                          PremiumToast.show(
                            context,
                            message: success 
                              ? 'Yuki\'s cognitive core updated! 🧠' 
                              : 'Core switched locally successfully.',
                            icon: _getModelIcon(modelId),
                          );
                        }
                      },
                    );
                  }),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Renders a luxurious model choice card inside the bottom sheet.
  Widget _buildModelSheetCard({
    required BuildContext context,
    required String modelId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    String title = 'Yuki Core';
    String desc = 'Cognitive processing engine.';
    String badge = 'SYSTEM';
    IconData icon = PhosphorIconsRegular.cpu;
    List<Color> gradientColors = [Colors.blue, Colors.cyan];

    // Setup distinct gradients, descriptors & badges for each model identity
    if (modelId.contains('Chat') || modelId.contains('chat')) {
      title = 'Yuki Chat';
      desc = 'Super fast, witty, and high-performance conversational engine.';
      badge = 'FAST';
      icon = PhosphorIconsRegular.lightning;
      gradientColors = [const Color(0xFFFF9E80), const Color(0xFFFF5252)];
    } else if (modelId.contains('Omni') || modelId.contains('omni')) {
      title = 'Yuki Omni';
      desc = 'Deep intelligence, advanced reasoning, and highly expressive personality.';
      badge = 'SMART';
      icon = PhosphorIconsRegular.brain;
      gradientColors = [const Color(0xFFE040FB), const Color(0xFF651FFF)];
    } else if (modelId.contains('2.0')) {
      title = 'Yuki 2.0';
      desc = 'Experimental preview model. Raw, unfiltered, and highly creative.';
      badge = 'BETA';
      icon = PhosphorIconsRegular.flask;
      gradientColors = [const Color(0xFFFF5252), const Color(0xFFFF1744)];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: gradientColors.first.withOpacity(0.08),
          highlightColor: gradientColors.first.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.accent.withOpacity(0.06) 
                  : AppColors.surfaceHigh.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppColors.accent.withOpacity(0.6) 
                    : AppColors.border.withOpacity(0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Premium Icon Box with linear gradient opacity
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors.map((c) => c.withOpacity(0.22)).toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: gradientColors.first.withOpacity(0.45),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: gradientColors.first,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Info Section containing name and badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Premium category micro-badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: gradientColors.first.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: gradientColors.first,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Dynamic radio/selected state visualizer
                if (isSelected)
                  Icon(
                    PhosphorIconsFill.checkCircle,
                    color: AppColors.accent,
                    size: 22,
                  ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack)
                else
                  Icon(
                    PhosphorIconsRegular.circle,
                    color: AppColors.textMuted.withOpacity(0.35),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
