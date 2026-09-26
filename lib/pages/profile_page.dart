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
    final user = auth.user;
    final rs = context.rs;
    final ui = context.uiScale;

    final avatarIconSize =
        context.responsive<double>(mobile: 100, tablet: 112, desktop: 128) *
        ui.clamp(0.9, 1.15);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'پروفایل',
          style: context.textStyles.titleLarge?.withColor(
            AppColors.primaryWhite,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : context.centerMaxWidth(
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
                        auth.isAdmin ? 'مدیر سیستم' : 'مشتری',
                        textAlign: TextAlign.center,
                        style: context.textStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'نام کاربری: ${user.username}',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'نام: ${user.fullName}',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'شماره تماس: ${user.phone}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('ویرایش نام و شماره تماس'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _EditProfileDialog(
                            initialName: user.fullName,
                            initialPhone: user.phone,
                          ),
                        ),
                      ),
                      SizedBox(height: rs.xl),

                      if (auth.isAdmin) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('ایجاد کاربر جدید'),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const _CreateUserDialog(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                          ),
                        ),
                        SizedBox(height: rs.md),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.dashboard),
                          label: const Text('پنل مدیریت (ادمین)'),
                          onPressed: () => context.push('/admin'),
                        ),
                        SizedBox(height: rs.md),
                      ],

                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        label: const Text(
                          'خروج',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () => context.read<AuthProvider>().logout(),
                      ),
                    ],
                  ),
                ),
              ),
              maxWidth: context.isMobile
                  ? double.infinity
                  : 500 * ui.clamp(0.95, 1.15),
            ),
    );
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
  bool _saving = false;

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

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().updateProfile(
      fullName: name,
      phone: phone,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ذخیره'),
        ),
      ],
    );
  }
}

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
  bool _saving = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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

    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().createUser(
      username: username,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('کاربر $username با موفقیت ایجاد شد.'),
        backgroundColor: AppColors.success,
      ),
    );
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('ایجاد'),
        ),
      ],
    );
  }
}
