// history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/glass_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(24), child: Text('History', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 32)).animate().fadeIn()),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              shape: BoxShape.circle,
                              image: msg.isUser
                                  ? null
                                  : const DecorationImage(
                                      image: AssetImage('assets/images/yuki_icon.png'),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: msg.isUser
                                ? Icon(PhosphorIconsRegular.user, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(msg.content, maxLines: 1, overflow: TextOverflow.ellipsis), Text(DateFormatter.formatHistoryTime(msg.createdAt), style: TextStyle(fontSize: 11, color: AppColors.textMuted))])),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index.clamp(0, 10) * 40).ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
