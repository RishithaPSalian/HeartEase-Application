import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  String _status = 'Confirming email...';

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // On web, supabase_flutter processes the hash and sets the session automatically.
      // On mobile deep links, you may parse Uri and call Supabase.instance.client.auth.exchangeCodeForSession if using OTP links.
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        setState(() => _status = 'Email confirmed. Redirecting...');
        await Future.delayed(const Duration(milliseconds: 800));
        // Go back to login/registration page to let user sign in (or straight into app)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthPage()),
            (r) => false,
          );
        }
      } else {
        setState(() => _status = 'Confirmation link processed. Please sign in.');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthPage()),
            (r) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _status = 'Confirmation failed: $e');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthPage()),
          (r) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(_status)),
    );
  }
}
