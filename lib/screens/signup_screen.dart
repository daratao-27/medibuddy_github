// signup_screen.dart
// collects name/email/password, creates the firebase account and
// goes back to the login screen once it's done

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_theme.dart';
import '../providers/firebase_provider.dart';
import '../widgets/medibuddy_logo.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerWidget {
  static const String routeName = '/signup';

  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _email;
  String? _password;
  String? _confirmPassword;

  SignupScreen();

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // check passwords match before hitting firebase
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      final service = ref.read(firebaseServiceProvider);
      await service.register(_fullName!, _email!, _password!);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      // the auth listener in main.dart handles the redirect
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (_) {
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

                // logo & tagline
                const MediBuddyLogo(tagline: 'Your daily medication companion'),
                const SizedBox(height: 36),

                // full name
                TextFormField(
                  decoration: appInputDecoration('Full name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your full name.';
                    return null;
                  },
                  onSaved: (v) => _fullName = v,
                ),
                const SizedBox(height: 16),

                // email
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
                const SizedBox(height: 16),

                // password
                TextFormField(
                  decoration: appInputDecoration('Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password.';
                    if (v.length < 6) return 'Password must be at least 6 characters.';
                    return null;
                  },
                  onSaved: (v) => _password = v,
                ),
                const SizedBox(height: 16),

                // confirm password
                TextFormField(
                  decoration: appInputDecoration('Confirm Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password.';
                    if (v.length < 6) return 'Password must be at least 6 characters.';
                    return null;
                  },
                  onSaved: (v) => _confirmPassword = v,
                ),
                const SizedBox(height: 28),

                // create account button
                ElevatedButton(
                  onPressed: () => _register(context, ref),
                  child: const Text('Create account'),
                ),
                const SizedBox(height: 24),

                // divider + login link
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: AppTextStyles.body),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(LoginScreen.routeName),
                      child: const Text('Sign in here'),
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
