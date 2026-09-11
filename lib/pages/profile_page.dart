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
  void dispose() {
    // قبلاً این متد اصلاً وجود نداشت و این دو کنترلر هیچ‌وقت dispose
    // نمی‌شدند (نشتی حافظه‌ی کوچک اما واقعی هر بار که این صفحه از
    // درخت ویجت خارج می‌شد).
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

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateUserDialog(),
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

/// دیالوگ ایجاد کاربر جدید (فقط ادمین).
///
/// قبلاً این دیالوگ داخل یک متد ساده (نه یک StatefulWidget مستقل) ساخته
/// می‌شد و برای هر بار باز شدن، دو TextEditingController جدید می‌ساخت که
/// هیچ‌وقت dispose نمی‌شدند — یعنی هر بار که ادمین این دیالوگ را باز و
/// بسته می‌کرد، دو کنترلر بدون مصرف در حافظه باقی می‌ماند. حالا چون خودِ
/// دیالوگ یک StatefulWidget با چرخه‌ی عمر مشخص است، dispose() آن به‌طور
/// خودکار وقتی دیالوگ بسته می‌شود صدا زده می‌شود.
class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
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
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ایجاد کاربر جدید'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'نام کاربری',
              hintText: 'نام کاربری جدید',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordCtrl,
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
        ElevatedButton(onPressed: _submit, child: const Text('ایجاد')),
      ],
    );
  }
}
