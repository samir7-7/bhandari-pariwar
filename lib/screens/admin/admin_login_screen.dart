import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/screens/auth/auth_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(
      initialMode: AuthMode.signIn,
    );
  }
}
