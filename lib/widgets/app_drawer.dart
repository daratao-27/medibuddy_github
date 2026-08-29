import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/shop_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer();

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      Navigator.of(context).pop(); // close the drawer first
      final service = ref.read(firebaseServiceProvider);
      await service.logOut();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    // saved accent colour + the notifier to change it
    final themeColor = ref.watch(themeProvider);
    final themeController = ref.read(themeProvider.notifier);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // header, background matches the selected theme colour
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            color: themeColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: themeColor, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // profile link
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_outline, color: themeColor),
            ),
            title: const Text('Profile', style: AppTextStyles.bodyBold),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textLight),
            onTap: () {
              Navigator.of(context).pop(); // close drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ProfileScreen()),
              );
            },
          ),

          // shop link
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: themeColor),
            ),
            title: const Text('Shop', style: AppTextStyles.bodyBold),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textLight),
            onTap: () {
              Navigator.of(context).pop(); // close drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ShopScreen()),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16, color: AppColors.divider),

          // theme picker, tap a colour to switch and save it
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_outlined,
                      color: AppColors.textMedium),
                ),
                const SizedBox(width: 14),
                const Text('Theme', style: AppTextStyles.bodyBold),
                const Spacer(),
                _ThemeSwatch(
                  color: AppColors.primaryOrange,
                  isSelected: themeColor == AppColors.primaryOrange,
                  onTap: () => themeController.setTheme(
                      AppColors.primaryOrange, 'orange'),
                ),
                _ThemeSwatch(
                  color: Colors.blue,
                  isSelected: themeColor == Colors.blue,
                  onTap: () => themeController.setTheme(Colors.blue, 'blue'),
                ),
                _ThemeSwatch(
                  color: Colors.green,
                  isSelected: themeColor == Colors.green,
                  onTap: () =>
                      themeController.setTheme(Colors.green, 'green'),
                ),
                _ThemeSwatch(
                  color: AppColors.primaryPurple,
                  isSelected: themeColor == AppColors.primaryPurple,
                  onTap: () => themeController.setTheme(
                      AppColors.primaryPurple, 'purple'),
                ),
                _ThemeSwatch(
                  color: Colors.red,
                  isSelected: themeColor == Colors.red,
                  onTap: () => themeController.setTheme(Colors.red, 'red'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16, color: AppColors.divider),

          // sign out
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.logout, color: Colors.redAccent),
            ),
            title: const Text(
              'Sign out',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}

// one colour circle in the theme picker
class _ThemeSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: CircleAvatar(
          radius: isSelected ? 13 : 11,
          backgroundColor: isSelected ? Colors.white : Colors.transparent,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: color,
            child: isSelected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
