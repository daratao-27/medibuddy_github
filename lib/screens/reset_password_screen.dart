// reset_password_screen.dart
// sends a password reset email through firebase, then back to login

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerWidget {
  static const String routeName = '/reset';

  final _formKey = GlobalKey<FormState>();
  String? _email;

  ResetPasswordScreen();

  Future<void> _sendResetLink(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final service = ref.read(firebaseServiceProvider);
      await service.forgotPassword(_email!);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Please check your email.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // key icon in circle
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5DDD8),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.asset('images/key.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // two-tone heading
                Center(
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Reset ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        TextSpan(
                          text: 'Password',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "Enter your email and we'll send you\na reset link",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ),
                const SizedBox(height: 32),

                // email field
                TextFormField(
                  decoration: appInputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your email.';
                    if (!v.contains('@')) return 'Enter a valid email address.';
                    return null;
                  },
                  onSaved: (v) => _email = v,
                ),
                const SizedBox(height: 24),

                // send reset link button
                ElevatedButton(
                  onPressed: () => _sendResetLink(context, ref),
                  child: const Text('Send reset link'),
                ),
                const SizedBox(height: 24),

                // divider + back to login
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Remembered it?', style: AppTextStyles.body),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(LoginScreen.routeName),
                      child: const Text('Back to login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
