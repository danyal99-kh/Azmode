import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../responsive.dart';

/// دکمه‌ی پروفایل در AppBar.
///
/// اگر کاربر لاگین کرده باشد، Avatar دایره‌ای با حرف اول نام کاربری نمایش
/// داده می‌شود؛ در غیر این صورت آیکون «ورود». هر دو حالت به یک [onTap]
/// مشترک وصل می‌شوند.
///
/// ابعاد کاملاً ریسپانسیو: Touch target، شعاع Avatar، سایز آیکون و فونت
/// حرف اول همه با `uiScale`/`fontScale` هماهنگ می‌شوند تا روی گوشی
/// کوچک و ویندوز یکدست باشند.
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
    final ui = context.uiScale;
    final fs = context.fontScale;

    // Touch target — هماهنگ با AppBarIconButton
    final hitSize =
        context.responsive<double>(mobile: 44, tablet: 46, desktop: 48) *
        ui.clamp(0.98, 1.08);

    // Avatar و آیکون
    final avatarRadius = (15.0 * ui).clamp(13.0, 18.0);
    final iconSize = (24.0 * ui).clamp(21.0, 27.0);
    final initialFontSize = (13.0 * fs).clamp(11.5, 15.0);

    return Tooltip(
      message: isLoggedIn ? 'پروفایل' : 'ورود / ثبت‌نام',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Center(
              child: isLoggedIn
                  ? CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.deepTeal,
                      child: Text(
                        _initial(displayName),
                        style: TextStyle(
                          color: AppColors.primaryWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: initialFontSize,
                          height: 1.0,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: AppColors.primaryWhite,
                      size: iconSize,
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
