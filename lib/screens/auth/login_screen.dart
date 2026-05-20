// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/premium_toast.dart';
import '../home/home_screen.dart';
import '../settings/about_us_screen.dart';
import 'register_screen.dart';
import 'privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _nsfwAcknowledged = false;
  bool _policyAccepted = false; // Flag to enforce Privacy and Policies acceptance

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    // Acknowledge the uncensored/NSFW companion warning
    if (!_nsfwAcknowledged) {
      PremiumToast.show(context, message: 'Please acknowledge the content notice first.', icon: PhosphorIconsRegular.warning);
      return;
    }

    // Acknowledge transparency agreement
    if (!_policyAccepted) {
      PremiumToast.show(context, message: 'Please read and agree to the Privacy & Policies first.', icon: PhosphorIconsRegular.warning);
      return;
    }

    if (await context.read<AuthProvider>().login(_emailController.text.trim(), _passwordController.text) && mounted) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (context, a, b) => const HomeScreen(), transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Text('Welcome\nback.', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40, height: 1.1)).animate().fadeIn().slideY(begin: 0.04),
              const SizedBox(height: 8),
              Text("Yuki's been waiting.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary.withOpacity(0.4))).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 64),
              PremiumTextField(controller: _emailController, labelText: 'Email', hintText: 'yuki@example.com', keyboardType: TextInputType.emailAddress).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              PremiumTextField(controller: _passwordController, labelText: 'Password', hintText: 'Your Password', obscureText: _obscurePassword, suffixIcon: IconButton(icon: Icon(_obscurePassword ? PhosphorIconsRegular.eyeClosed : PhosphorIconsRegular.eye, color: AppColors.textMuted, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _nsfwAcknowledged,
                      onChanged: (val) => setState(() => _nsfwAcknowledged = val ?? false),
                      activeColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I acknowledge that this AI companion may generate uncensored/NSFW content depending on my settings.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())),
                          child: Text(
                            'Who created Yuki? (About Us)',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _policyAccepted,
                      onChanged: (val) => setState(() => _policyAccepted = val ?? false),
                      activeColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I have read and agree to the Privacy & Policies, and accept all user & developer responsibilities.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                          child: Text(
                            'Read Privacy & Policies',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 380.ms),
              const SizedBox(height: 32),
              if (authProvider.error != null) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Text(authProvider.error!, style: TextStyle(color: AppColors.danger, fontSize: 13)).animate().fadeIn()),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: authProvider.isLoading ? 56 : (MediaQuery.of(context).size.width - 48),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(authProvider.isLoading ? 28 : 14)),
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.background)))
                        : const Text('Sign In'),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              Center(child: GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())), child: Text('New here? Create an account', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)))).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
