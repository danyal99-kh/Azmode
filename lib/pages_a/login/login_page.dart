import 'package:azmode/providers/auth_provider.dart';
import 'package:azmode/responsive.dart';
import 'package:azmode/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final ui = context.uiScale;
    final rs = context.rs;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(rs.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440 * ui.clamp(0.95, 1.15)),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(rs.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64 * ui.clamp(0.9, 1.15),
                          color: AppColors.deepTeal,
                        ),

                        SizedBox(height: rs.lg),

                        Text(
                          'ورود به آزموده',
                          textAlign: TextAlign.center,
                          style: context.textStyles.headlineSmall,
                        ),

                        SizedBox(height: rs.sm),

                        Text(
                          'برای ادامه وارد حساب کاربری خود شوید.',
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodyMedium,
                        ),

                        SizedBox(height: rs.xl),

                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          enabled: !authProvider.isLoading,
                          decoration: const InputDecoration(
                            labelText: 'نام کاربری',
                            hintText: 'نام کاربری خود را وارد کنید',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'نام کاربری را وارد کنید.';
                            }

                            return null;
                          },
                        ),

                        SizedBox(height: rs.md),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !authProvider.isLoading,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'رمز عبور',
                            hintText: 'رمز عبور خود را وارد کنید',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'نمایش رمز عبور'
                                  : 'مخفی کردن رمز عبور',
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'رمز عبور را وارد کنید.';
                            }

                            return null;
                          },
                        ),

                        if (authProvider.errorMessage != null) ...[
                          SizedBox(height: rs.md),

                          Container(
                            padding: EdgeInsets.all(rs.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: rs.sm),
                                Expanded(
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: context.textStyles.bodyMedium
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: rs.xl),

                        SizedBox(
                          height: 52 * ui.clamp(0.95, 1.1),
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _login,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primaryWhite,
                                    ),
                                  )
                                : const Text('ورود'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
