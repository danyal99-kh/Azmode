import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../responsive.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'پروفایل',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: _buildBody(context, auth),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider auth) {
    if (auth.isLoading || auth.status == AuthStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!auth.isAuthenticated || auth.user == null) {
      return _buildUnauthenticated(context);
    }

    return _buildProfile(context, auth);
  }

  Widget _buildProfile(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
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
                'پروفایل کاربری',
                textAlign: TextAlign.center,
                style: context.textStyles.headlineMedium,
              ),

              SizedBox(height: rs.lg),

              _InfoRow(
                icon: Icons.person_outline,
                label: 'نام کاربری',
                value: user.username,
              ),

              SizedBox(height: rs.md),

              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'شماره تماس',
                value: user.phone,
              ),

              SizedBox(height: rs.md),

              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'شناسه کاربر',
                value: user.id.toString(),
              ),

              SizedBox(height: rs.xl),

              // فعلاً ویرایش را فعال نمی‌کنیم؛
              // چون API ویرایش پروفایل در بک‌اند هنوز وجود ندارد.
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.edit),
                label: const Text('ویرایش اطلاعات'),
              ),

              SizedBox(height: rs.md),

              ElevatedButton.icon(
                onPressed: () async {
                  await auth.logout();

                  if (!context.mounted) return;

                  context.go('/login');
                },
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

  Widget _buildUnauthenticated(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 96,
              color: AppColors.outlineGray,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'برای مشاهده پروفایل وارد حساب خود شوید.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('ورود به حساب'),
            ),
          ],
        ),
      ),
    );
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
