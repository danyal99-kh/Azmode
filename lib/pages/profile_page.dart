import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../responsive.dart';
import '../store_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'پروفایل',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: store.isAuthenticated
          ? _buildProfile(context, store)
          : _buildLogin(context, store),
    );
  }

  Widget _buildProfile(BuildContext context, StoreProvider store) {
    final user = store.currentUser;
    final rs = context.rs;
    final ui = context.uiScale;

    final avatarIconSize =
        context.responsive<double>(mobile: 100, tablet: 112, desktop: 128) *
        ui.clamp(0.9, 1.15);

    return context.centerMaxWidth(
      SingleChildScrollView(
        padding: EdgeInsets.all(rs.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.account_circle,
                size: avatarIconSize,
                color: AppColors.outlineGray,
              ),
              SizedBox(height: rs.md),
              Text(
                store.isAdmin ? 'مدیر سیستم' : 'مشتری',
                textAlign: TextAlign.center,
                style: context.textStyles.headlineMedium,
              ),
              SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'نام کاربری',
                value: user?.username ?? '',
              ),
              SizedBox(height: rs.md),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'شماره تماس',
                value: user?.phone ?? '',
              ),
              SizedBox(height: rs.xl),

              // فعلاً ویرایش را فعال نمی‌کنیم؛ چون API ویرایش پروفایل
              // در بک‌اند هنوز وجود ندارد (مرحله‌ی بعدی).
              const OutlinedButton(
                onPressed: null,
                child: Text('ویرایش اطلاعات'),
              ),
              SizedBox(height: rs.md),

              if (store.isAdmin)
                ElevatedButton.icon(
                  icon: const Icon(Icons.dashboard),
                  label: const Text('پنل مدیریت (ادمین)'),
                  onPressed: () => context.push('/admin'),
                ),
              SizedBox(height: rs.md),

              OutlinedButton.icon(
                onPressed: () => store.logout(),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'خروج',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
      maxWidth: context.isMobile ? double.infinity : 500 * ui.clamp(0.95, 1.15),
    );
  }

  Widget _buildLogin(BuildContext context, StoreProvider store) {
    final rs = context.rs;
    final ui = context.uiScale;
    final cardMaxWidth = (420.0 * ui).clamp(380.0, 520.0);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(rs.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardMaxWidth),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(rs.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ورود به حساب کاربری',
                    textAlign: TextAlign.center,
                    style: context.textStyles.headlineSmall,
                  ),
                  SizedBox(height: rs.lg),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'نام کاربری'),
                  ),
                  SizedBox(height: rs.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'رمز عبور'),
                  ),
                  SizedBox(height: rs.xl),
                  ElevatedButton(
                    onPressed: store.isAuthLoading
                        ? null
                        : () => _onLoginPressed(context, store),
                    child: store.isAuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryWhite,
                            ),
                          )
                        : const Text('ورود'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed(
    BuildContext context,
    StoreProvider store,
  ) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام کاربری و رمز عبور را وارد کنید.')),
      );
      return;
    }
    try {
      await store.login(username, password);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineGray.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.outlineGray),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'ثبت نشده' : value,
                  style: context.textStyles.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
