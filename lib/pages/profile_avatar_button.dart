import 'package:flutter/material.dart';
import '../../theme.dart';

/// دکمه‌ی پروفایل در AppBar.
///
/// اگر کاربر لاگین کرده باشد ([isLoggedIn] == true)، یک Avatar دایره‌ای
/// با حرف اول نام کاربری نمایش داده می‌شود؛ در غیر این صورت آیکون ساده‌ی
/// «ورود» نشان داده می‌شود. هر دو حالت به یک [onTap] مشترک وصل می‌شوند،
/// چون در هر دو حالت باید صفحه‌ی پروفایل باز شود؛ خودِ آن صفحه است که
/// تصمیم می‌گیرد فرم ورود یا اطلاعات کاربر را نشان دهد (دقیقاً همان کاری
/// که `profile_page.dart` همین الان انجام می‌دهد).
class ProfileAvatarButton extends StatelessWidget {
  final bool isLoggedIn;
  final String? displayName;
  final VoidCallback onTap;

  const ProfileAvatarButton({
    super.key,
    required this.isLoggedIn,
    required this.onTap,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isLoggedIn ? 'پروفایل' : 'ورود / ثبت‌نام',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: isLoggedIn
                  ? CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.deepTeal,
                      child: Text(
                        _initial(displayName),
                        style: const TextStyle(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: AppColors.primaryWhite,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
