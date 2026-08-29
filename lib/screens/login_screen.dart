import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import '../widgets/medibuddy_logo.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerWidget {
  static const String routeName = '/login';

  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _password;

  LoginScreen();

  String _messageForFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      case 'unauthorized-domain':
        return 'This domain is not authorized for Firebase Auth. Add it in Firebase Console > Authentication > Settings > Authorized domains.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _login(
    BuildContext context,
    WidgetRef ref,
    bool isGoogle,
  ) async {
    final bool isValid = isGoogle ? true : _formKey.currentState!.validate();
    if (!isValid) return;
    if (!isGoogle) _formKey.currentState!.save();

    try {
      final service = ref.read(firebaseServiceProvider);
      if (isGoogle) {
        final credential = await service.signInWithGoogle();
        if (credential == null) return;
      } else {
        await service.login(_email!, _password!);
      }

      if (!context.mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForFirebaseError(e))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _loginWithGitHub(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(firebaseServiceProvider);
      await service.signInWithGitHub();
      if (!context.mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );
      Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForFirebaseError(e))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
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
                const MediBuddyLogo(tagline: 'Welcome back!'),
                const SizedBox(height: 36),

                // email field
                TextFormField(
                  decoration: appInputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your email.';
                    if (!v.contains('@')) return 'Enter a valid email address.';
                    return null;
                  },
                  onSaved: (v) => _email = v,
                ),
                const SizedBox(height: 16),

                // password field
                TextFormField(
                  decoration: appInputDecoration('Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please enter your password.';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters.';
                    return null;
                  },
                  onSaved: (v) => _password = v,
                ),
                const SizedBox(height: 8),

                // forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(ResetPasswordScreen.routeName),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),

                // sign in button
                ElevatedButton(
                  onPressed: () => _login(context, ref, false),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 12),

                // Google sign-in button
                OutlinedButton.icon(
                  onPressed: () => _login(context, ref, true),
                  icon: Image.asset('images/google.png', width: 20, height: 20),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.inputBorder),
                    foregroundColor: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // GitHub sign-in button
                OutlinedButton.icon(
                  onPressed: () => _loginWithGitHub(context, ref),
                  icon: Image.asset(
                    'images/github.png',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Sign in with GitHub'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.inputBorder),
                    foregroundColor: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: AppTextStyles.body,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(SignupScreen.routeName),
                      child: const Text('Register here'),
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
