import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import 'edit_account_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen();

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
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
    final medsAsync = ref.watch(medicationsProvider);

    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile', style: AppTextStyles.heading1),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textMedium, size: 18),
                    label: const Text('Back',
                        style: TextStyle(color: AppColors.textMedium)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // user info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE8C8BF),
                      child: Icon(Icons.person,
                          color: Theme.of(context).colorScheme.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: AppTextStyles.heading2),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 14, color: AppColors.textMedium),
                            const SizedBox(width: 4),
                            Text(email, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // stats row
              medsAsync.when(
                data: (meds) {
                  final medCount = meds.where((m) => m.unit == 'mg').length;
                  final supCount = meds.length - medCount;
                  final lowCount = meds.where((m) => m.isLowStock).length;
                  return Row(
                    children: [
                      _StatBox(icon: '💊', value: '$medCount', label: 'Medications'),
                      const SizedBox(width: 10),
                      _StatBox(icon: '🌿', value: '$supCount', label: 'Supplements'),
                      const SizedBox(width: 10),
                      _StatBox(icon: '⚠️', value: '$lowCount', label: 'Low Stock'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // quick links
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.medication_outlined,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: const Text('My Medications',
                          style: AppTextStyles.bodyBold),
                      subtitle: medsAsync.when(
                        data: (meds) =>
                            Text('${meds.length} items', style: AppTextStyles.caption),
                        loading: () =>
                            const Text('Loading…', style: AppTextStyles.caption),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textLight),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: const Text('Edit Account Details',
                          style: AppTextStyles.bodyBold),
                      subtitle: const Text('Update your name, email or password',
                          style: AppTextStyles.caption),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textLight),
                      onTap: () => Navigator.of(context)
                          .pushNamed(EditAccountScreen.routeName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // sign out button
              OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                label: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
