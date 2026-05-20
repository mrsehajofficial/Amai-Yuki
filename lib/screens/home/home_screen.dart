// home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/bottom_nav_dock.dart';
import '../chat/chat_screen.dart';
import '../direct/conversations_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/notification_service.dart';
import '../direct/direct_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [ChatScreen(), ConversationsScreen(), SettingsScreen()];
  StreamSubscription<String>? _notificationSubscription;
  
  static const List<BottomNavItem> _navItems = [
    BottomNavItem(
      iconRegular: PhosphorIconsRegular.chatCircle, 
      iconFill: PhosphorIconsFill.chatCircle, 
      label: 'AI Chat'
    ),
    BottomNavItem(
      iconRegular: PhosphorIconsRegular.users, 
      iconFill: PhosphorIconsFill.users, 
      label: 'Direct'
    ),
    BottomNavItem(
      iconRegular: PhosphorIconsRegular.gear, 
      iconFill: PhosphorIconsFill.gear, 
      label: 'Settings'
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initChat();
      
      // Wire up local notification listeners to respond to incoming deep links. - SV
      _notificationSubscription = NotificationService().onNotificationTap.listen((payload) {
        _handleNotificationTapPayload(payload);
      });

      // Scan for any cold start payloads if the app was completely killed when clicked. - SV
      _checkAppLaunchPayload();
    });
  }

  /// Looks up launch payload when app was opened from terminated status. - SV
  Future<void> _checkAppLaunchPayload() async {
    final launchPayload = await NotificationService().getAppLaunchPayload();
    if (launchPayload != null) {
      _handleNotificationTapPayload(launchPayload);
    }
  }

  /// Parses deep link payload and routes the user directly to the targeted conversation. - SV
  void _handleNotificationTapPayload(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String otherUserId = data['otherUserId'];
      final String otherUsername = data['otherUsername'];
      final String? otherUserFullName = data['otherUserFullName'];

      // Seamlessly redirect tab view index to "Direct" to keep bottom nav updated. - SV
      setState(() {
        _currentIndex = 1;
      });

      // Push direct chat onto navigator stack. - SV
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            otherUserId: otherUserId,
            otherUsername: otherUsername,
            otherUserFullName: otherUserFullName,
          ),
        ),
      );
    } catch (e) {
      print('DEBUG: Error processing notification click routing: $e');
    }
  }

  @override
  void dispose() {
    // Unsubscribe from background stream bounds to prevent memory leaks. - SV
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We extend the body so the custom floating dock looks like it's 
      // part of the environment, not just stuck to the bottom.
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Using IndexedStack to keep screen state alive while switching.
          // Nobody likes losing their place in a chat.
          IndexedStack(index: _currentIndex, children: _screens),
          
          // The floating dock needs to be in a Stack at the body level.
          // Putting it in the Scaffold's bottomNavigationBar with a 
          // 0-height Stack was blocking touch events. Fixed that.
          BottomNavDock(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: _navItems,
          ),
        ],
      ),
    );
  }
}
