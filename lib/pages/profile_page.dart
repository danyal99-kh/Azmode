import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
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

  void _showCreateUserDialog(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد کاربر جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام کاربری',
                hintText: 'نام کاربری جدید',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز عبور',
                hintText: 'رمز عبور دلخواه',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final username = usernameCtrl.text.trim();
              final password = passwordCtrl.text.trim();
              if (username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لطفاً هر دو فیلد را پر کنید.')),
                );
                return;
              }
              try {
                context.read<StoreProvider>().addUser(username, password);
                Navigator.pop(context); // بستن دیالوگ
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('کاربر $username با موفقیت ایجاد شد.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, StoreProvider store) {
    final currentUser = store.currentUser;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: AppColors.outlineGray,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            store.isAdmin ? 'مدیر سیستم' : 'مشتری',
            textAlign: TextAlign.center,
            style: context.textStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'نام کاربری: ${currentUser?.username ?? ''}',
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          // ---- بخش ادمین: ایجاد کاربر جدید ----
          if (store.isAdmin) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('ایجاد کاربر جدید'),
              onPressed: () => _showCreateUserDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // دکمه‌های مدیریت و خروج
          if (store.isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.dashboard),
              label: const Text('پنل مدیریت (ادمین)'),
              onPressed: () => context.push('/admin'),
            ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('خروج', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => store.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogin(BuildContext context, StoreProvider store) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ورود به حساب کاربری',
                  textAlign: TextAlign.center,
                  style: context.textStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری',
                    hintText: 'برای ادمین بنویسید: admin',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'رمز عبور',
                    hintText: 'هر رمزی قبول است',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();
                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('نام کاربری و رمز عبور را وارد کنید.'),
                        ),
                      );
                      return;
                    }
                    try {
                      store.login(username, password);
                      // بعد از ورود موفق، می‌توانید پیام خوش‌آمد نشان دهید یا صفحه را ببندید
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('ورود'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
