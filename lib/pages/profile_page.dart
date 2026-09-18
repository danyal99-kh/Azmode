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

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateUserDialog(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // حالت لاگین‌شده
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProfile(BuildContext context, StoreProvider store) {
    final currentUser = store.currentUser;
    final rs = context.rs;
    final ui = context.uiScale;

    // آیکون بزرگ ریسپانسیو
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                'نام کاربری: ${currentUser?.username ?? ''}',
                textAlign: TextAlign.center,
              ),
              Text(
                'نام: ${currentUser?.fullName ?? ''}',
                textAlign: TextAlign.center,
              ),
              Text(
                'شماره تماس: ${currentUser?.phone ?? ''}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('ویرایش نام و شماره تماس'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _EditProfileDialog(
                    initialName: currentUser?.fullName ?? '',
                    initialPhone: currentUser?.phone ?? '',
                  ),
                ),
              ),
              SizedBox(height: rs.xl),

              // بخش ادمین: ایجاد کاربر جدید
              if (store.isAdmin) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('ایجاد کاربر جدید'),
                  onPressed: () => _showCreateUserDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                  ),
                ),
                SizedBox(height: rs.md),
              ],

              // دکمه‌های مدیریت و خروج
              if (store.isAdmin)
                ElevatedButton.icon(
                  icon: const Icon(Icons.dashboard),
                  label: const Text('پنل مدیریت (ادمین)'),
                  onPressed: () => context.push('/admin'),
                ),
              SizedBox(height: rs.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'خروج',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => store.logout(),
              ),
            ],
          ),
        ),
      ),
      // روی گوشی بدون محدودیت، روی دسکتاپ حداکثر 500
      maxWidth: context.isMobile ? double.infinity : 500 * ui.clamp(0.95, 1.15),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // حالت لاگین
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogin(BuildContext context, StoreProvider store) {
    final rs = context.rs;
    final ui = context.uiScale;

    // عرض کارت لاگین — ریسپانسیو
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
                    decoration: const InputDecoration(
                      labelText: 'نام کاربری',
                      hintText: 'برای ادمین بنویسید: admin',
                    ),
                  ),
                  SizedBox(height: rs.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز عبور',
                      hintText: 'هر رمزی قبول است',
                    ),
                  ),
                  SizedBox(height: rs.xl),
                  ElevatedButton(
                    onPressed: () => _onLoginPressed(context, store),
                    child: const Text('ورود'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onLoginPressed(BuildContext context, StoreProvider store) {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام کاربری و رمز عبور را وارد کنید.')),
      );
      return;
    }
    try {
      store.login(username, password);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  const _EditProfileDialog({
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    context.read<StoreProvider>().updateCurrentUserProfile(
      fullName: name,
      phone: phone,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ویرایش اطلاعات'),
      content: SizedBox(
        width: dialogWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام و نام خانوادگی',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'شماره تماس'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('ذخیره')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// دیالوگ ایجاد کاربر جدید (فقط ادمین)
// ═══════════════════════════════════════════════════════════════
class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (username.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً همه‌ی فیلدها را پر کنید.')),
      );
      return;
    }
    try {
      context.read<StoreProvider>().addUser(
        username,
        password,
        fullName: fullName,
        phone: phone,
      );
      Navigator.pop(context);
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
      content: SizedBox(
        width: dialogWidth(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'نام کاربری'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'رمز عبور'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام و نام خانوادگی',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'شماره تماس'),
            ),
          ],
        ),
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
