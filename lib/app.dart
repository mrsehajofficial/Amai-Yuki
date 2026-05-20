// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/direct_chat_provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/direct_chat_service.dart';
import 'services/storage_service.dart';

class AmaiYukiApp extends StatelessWidget {
  const AmaiYukiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => StorageService()), 
        Provider(create: (_) => AuthService()), 
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => DirectChatService()),
        ChangeNotifierProvider(create: (c) => AuthProvider(c.read<AuthService>(), c.read<StorageService>())),
        ChangeNotifierProvider(create: (c) => ChatProvider(c.read<ChatService>(), c.read<AuthProvider>())),
        ChangeNotifierProvider(create: (c) => DirectChatProvider(c.read<DirectChatService>(), c.read<AuthProvider>(), c.read<StorageService>())),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Resolve actual brightness for AppColors
          final platformBrightness = View.of(context).platformDispatcher.platformBrightness;
          AppColors.applyTheme(auth.themeMode, platformBrightness);
          
          return MaterialApp(
            key: ValueKey('${auth.isAuthenticated ? 'authed' : 'unauthed'}_${auth.themeMode.name}_${platformBrightness.name}'),
            title: 'Amai Yuki',
            debugShowCheckedModeBanner: false, 
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: auth.themeMode,
            home: auth.isInitialized 
                ? (auth.isAuthenticated 
                    ? const HomeScreen(key: ValueKey('HomeScreen')) 
                    : const LoginScreen(key: ValueKey('LoginScreen'))) 
                : const SplashScreen(key: ValueKey('SplashScreen')),
          );
        },
      ),
    );
  }
}
