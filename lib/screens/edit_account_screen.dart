import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  static const String routeName = '/edit-account';
  const EditAccountScreen();

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  String? _newName;
  String? _newPassword;
  String? _confirmNewPassword;

  Future<void> _updateName() async {
    if (!_nameFormKey.currentState!.validate()) return;
    _nameFormKey.currentState!.save();
    try {
      final service = ref.read(firebaseServiceProvider);
      await service.updateDisplayName(_newName!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    _passwordFormKey.currentState!.save();
    if (_newPassword != _confirmNewPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    try {
      final service = ref.read(firebaseServiceProvider);
      await service.updatePassword(_newPassword!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      _passwordFormKey.currentState!.reset();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final service = ref.read(firebaseServiceProvider);
      await service.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(firebaseServiceProvider);
    final user = service.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // name section
              const Text('Update Name', style: AppTextStyles.heading2),
              const SizedBox(height: 12),
              Form(
                key: _nameFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: user?.displayName ?? '',
                      decoration: appInputDecoration('Full name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter a name.' : null,
                      onSaved: (v) => _newName = v,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _updateName,
                      child: const Text('Update name'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 24),

              // password section
              const Text('Change Password', style: AppTextStyles.heading2),
              const SizedBox(height: 12),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: appInputDecoration('New password'),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password.';
                        if (v.length < 6) return 'At least 6 characters.';
                        return null;
                      },
                      onSaved: (v) => _newPassword = v,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      decoration: appInputDecoration('Confirm new password'),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm your password.';
                        if (v.length < 6) return 'At least 6 characters.';
                        return null;
                      },
                      onSaved: (v) => _confirmNewPassword = v,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _updatePassword,
                      child: const Text('Update password'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 24),

              // email verification section
              const Text('Email Verification', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    user?.emailVerified == true
                        ? Icons.verified
                        : Icons.warning_amber,
                    color: user?.emailVerified == true
                        ? AppColors.takenBadge
                        : AppColors.lowStockBadge,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.emailVerified == true
                        ? 'Email is verified'
                        : 'Email not yet verified',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              if (user?.emailVerified == false) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _sendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send verification email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
