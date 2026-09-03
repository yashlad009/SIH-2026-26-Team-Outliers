import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/connectivity_banner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signIn(
            _emailCtrl.text,
            _passwordCtrl.text,
          );
      if (user != null && mounted) {
        ref.read(userProfileProvider.notifier).set(user);
      } else if (mounted) {
        setState(() => _error = 'Login failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Invalid email or password.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String email) {
    _emailCtrl.text = email;
    _passwordCtrl.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    // Logo / Branding
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.tagline,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Language toggle
                    GestureDetector(
                      onTap: () => ref.read(localeProvider.notifier).toggle(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          locale == AppLocale.en ? 'मराठी' : 'English',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                strings.login,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SIH26133 · Govt. of Maharashtra',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: strings.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: strings.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: Validators.password,
                                onFieldSubmitted: (_) => _signIn(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.riskHighLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.riskHigh, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                              color: AppColors.riskHigh,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _signIn,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(strings.loginButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Demo accounts
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Demo Accounts (password: demo1234)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DemoTile(
                            role: 'CHW',
                            email: 'chw@carelink.demo',
                            onTap: () => _fillDemo('chw@carelink.demo'),
                          ),
                          _DemoTile(
                            role: 'Doctor',
                            email: 'doctor@carelink.demo',
                            onTap: () => _fillDemo('doctor@carelink.demo'),
                          ),
                          _DemoTile(
                            role: 'Admin',
                            email: 'admin@carelink.demo',
                            onTap: () => _fillDemo('admin@carelink.demo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  final String role;
  final String email;
  final VoidCallback onTap;

  const _DemoTile({
    required this.role,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
