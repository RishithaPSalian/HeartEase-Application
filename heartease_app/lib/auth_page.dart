// auth_page.dart — Material-only Auth + Admin Settings (fixed)

import 'package:flutter/material.dart'; // Material UI [web:92]
import 'package:email_validator/email_validator.dart'; // Email validation [web:92]
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client [web:24]
import 'emergency.dart'; // Your post-login screen [web:34]

// Single global supabase client reference (avoid duplicates)
final supabase = Supabase.instance.client; // [web:24]

// -------------------- Auth types --------------------
enum AuthScreen { welcome, login, signup } // [web:92]

// -------------------- Auth Page --------------------
class AuthPage extends StatefulWidget {
  const AuthPage({super.key}); // add const + key for consistency [web:92]
  @override
  State<AuthPage> createState() => _AuthPageState(); // [web:92]
}

class _AuthPageState extends State<AuthPage> {
  AuthScreen currentScreen = AuthScreen.welcome; // [web:92]
  bool showPassword = false; // [web:92]
  bool showConfirmPassword = false; // [web:92]

  final _formKey = GlobalKey<FormState>(); // [web:92]
  final nameController = TextEditingController(); // [web:92]
  final emailController = TextEditingController(); // [web:92]
  final passwordController = TextEditingController(); // [web:92]
  final confirmPasswordController = TextEditingController(); // [web:92]
  final phoneController = TextEditingController(); // [web:92]
  final cityController = TextEditingController(); // [web:92]
  final stateController = TextEditingController(); // [web:92]
  final countryController = TextEditingController(); // [web:92]

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password'; // [web:92]
    if (value.length < 6) return 'At least 6 characters'; // [web:92]
    if (!RegExp(r'[0-9]').hasMatch(value))
      return 'Include a number'; // [web:92]
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value))
      return 'Include a special character'; // [web:92]
    return null; // [web:92]
  }

  String? validateConfirmPassword(String? value) {
    if (value != passwordController.text)
      return 'Passwords do not match'; // [web:92]
    return null; // [web:92]
  }

  // -------------------- Sign Up --------------------
  Future<void> _signUp() async {
    final email = emailController.text.trim().toLowerCase(); // [web:24]
    final password = passwordController.text.trim(); // [web:24]
    final name = nameController.text.trim(); // [web:24]

    try {
      // For web, redirect back to /auth-callback on same origin during dev
      final redirectUrl = '${Uri.base.origin}/auth-callback'; // ✅ fixed here

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectUrl,
      );

      final user = res.user;
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'name': name,
          // IMPORTANT: do not store plaintext passwords in production, remove this field from DB
          'password': password,
          'phone': phoneController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'country': countryController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We sent a confirmation email. Please confirm to complete signup.',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signup initiated. Check your email to confirm your account.',
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message))); // [web:24]
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Signup error: $e'))); // [web:92]
      }
    }
  }

  // -------------------- Sign In --------------------
  Future<void> _signIn() async {
    final email = emailController.text; // [web:24]
    final password = passwordController.text; // [web:24]
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ); // [web:24]
      final user = res.user; // [web:24]
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyScreen(adminEmail: email, userId: user.id),
          ),
        ); // [web:34]
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed!')),
          ); // [web:92]
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      final msg = e.code == 'invalid_credentials'
          ? 'Invalid credentials'
          : e.message; // fallback for other auth errors

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  //-------------------- Welcome/Login/Signup UI --------------------
  Widget getWelcomeCard() => Center(
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_services,
              size: 90,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to HeartEase',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your trusted ambulance and emergency medical response platform.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => setState(() => currentScreen = AuthScreen.login),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Login'),
            ),

            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () =>
                  setState(() => currentScreen = AuthScreen.signup),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    ),
  ); // [web:92]

  Widget getLoginForm() => Center(
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Login to HeartEase",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Access emergency medical services instantly.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => EmailValidator.validate(value ?? '')
                    ? null
                    : 'Enter a valid email address',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
                obscureText: !showPassword,
                validator: validatePassword,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter your email first')),
                      ); // [web:92]
                      return;
                    }
                    await supabase.auth.resetPasswordForEmail(
                      emailController.text.trim(),
                    ); // [web:33]
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent'),
                        ),
                      ); // [web:33]
                    }
                  },
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _signIn();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Sign in'),
              ),

              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    setState(() => currentScreen = AuthScreen.welcome),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    ),
  ); // [web:92][web:33]

  Widget getSignupForm() => Center(
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Create HeartEase Account",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Register to request ambulance assistance and health support.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length < 3
                    ? 'Enter full name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => EmailValidator.validate(value ?? '')
                    ? null
                    : 'Enter a valid email address',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
                obscureText: !showPassword,
                validator: validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => showConfirmPassword = !showConfirmPassword,
                    ),
                  ),
                ),
                obscureText: !showConfirmPassword,
                validator: validateConfirmPassword,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length < 10
                    ? 'Enter valid phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length < 2
                    ? 'Enter valid city'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length < 2
                    ? 'Enter valid state'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.length < 2
                    ? 'Enter valid country'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _signUp();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Sign up'),
              ),

              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    setState(() => currentScreen = AuthScreen.welcome),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    ),
  ); // [web:92]

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // [web:92]

    if (screenWidth > 600) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: Center(
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                currentScreen == AuthScreen.login
                    ? getLoginForm()
                    : currentScreen == AuthScreen.signup
                    ? getSignupForm()
                    : getWelcomeCard(),
              ],
            ),
          ),
        ),
      ); // [web:92]
    } else {
      final Widget child = currentScreen == AuthScreen.welcome
          ? getWelcomeCard()
          : currentScreen == AuthScreen.login
          ? getLoginForm()
          : getSignupForm(); // [web:92]
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: Center(child: SingleChildScrollView(child: child)),
      ); // [web:92]
    }
  }
}

// ================== Admin Settings (Material) ==================

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          _AccountSectionMaterial(),
          _PrivacySectionMaterial(),
          _NotificationsSectionMaterial(),
          _SupportSectionMaterial(),
        ],
      ),
    ); // [web:92]
  }
}

// -------- Account --------
class _AccountSectionMaterial extends StatelessWidget {
  const _AccountSectionMaterial();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(title: Text('Account'), dense: true),
        ListTile(
          title: const Text('Two‑Step Verification'),
          subtitle: const Text('Authenticator app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TwoStepVerificationPage()),
          ),
        ),
        ListTile(
          title: const Text('Change email address'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
          ),
        ),
        ListTile(
          title: const Text('Change password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
          ),
        ),
        ListTile(
          title: const Text('Log out'),
          leading: const Icon(Icons.logout),
          onTap: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth', (r) => false);
            }
          },
        ),
        const Divider(height: 0),
      ],
    ); // [web:92]
  }
}

// -------- Privacy --------
class _PrivacySectionMaterial extends StatefulWidget {
  const _PrivacySectionMaterial();
  @override
  State<_PrivacySectionMaterial> createState() =>
      _PrivacySectionMaterialState();
}

class _PrivacySectionMaterialState extends State<_PrivacySectionMaterial> {
  bool profilePublic = false;
  bool dataSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(title: Text('Privacy'), dense: true),
        SwitchListTile(
          title: const Text('Public profile'),
          value: profilePublic,
          onChanged: (v) async {
            setState(() => profilePublic = v);
            await supabase.from('user_settings').upsert({
              'user_id': supabase.auth.currentUser!.id,
              'profile_public': v,
            });
          },
        ),
        SwitchListTile(
          title: const Text('Data sharing'),
          value: dataSharing,
          onChanged: (v) async {
            setState(() => dataSharing = v);
            await supabase.from('user_settings').upsert({
              'user_id': supabase.auth.currentUser!.id,
              'data_sharing': v,
            });
          },
        ),
        ListTile(
          title: const Text('Blocked users'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(height: 0),
      ],
    ); // [web:77][web:88]
  }
}

// -------- Notifications --------
class _NotificationsSectionMaterial extends StatefulWidget {
  const _NotificationsSectionMaterial();
  @override
  State<_NotificationsSectionMaterial> createState() =>
      _NotificationsSectionMaterialState();
}

class _NotificationsSectionMaterialState
    extends State<_NotificationsSectionMaterial> {
  bool pushAlerts = true;
  bool emailAlerts = true;
  bool smsAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(title: Text('Notifications'), dense: true),
        SwitchListTile(
          title: const Text('Emergency alerts'),
          value: pushAlerts,
          onChanged: (v) async {
            setState(() => pushAlerts = v);
            await _savePref('push_emergency', v);
          },
        ),
        SwitchListTile(
          title: const Text('Email updates'),
          value: emailAlerts,
          onChanged: (v) async {
            setState(() => emailAlerts = v);
            await _savePref('email_updates', v);
          },
        ),
        SwitchListTile(
          title: const Text('SMS alerts'),
          value: smsAlerts,
          onChanged: (v) async {
            setState(() => smsAlerts = v);
            await _savePref('sms_emergency', v);
          },
        ),
        const Divider(height: 0),
      ],
    ); // [web:77]
  }

  Future<void> _savePref(String key, bool value) async {
    await supabase.from('user_settings').upsert({
      'user_id': supabase.auth.currentUser!.id,
      key: value,
    }); // Ensure RLS owner policies on user_settings [web:91]
  }
}

// -------- Support --------
class _SupportSectionMaterial extends StatelessWidget {
  const _SupportSectionMaterial();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(title: Text('Support'), dense: true),
        ListTile(
          title: const Text('Help & FAQ'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          title: const Text('About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    ); // [web:88]
  }
}

// ================== Two‑Step Verification (MFA TOTP) ==================
class TwoStepVerificationPage extends StatefulWidget {
  const TwoStepVerificationPage({super.key});
  @override
  State<TwoStepVerificationPage> createState() =>
      _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  bool loading = false;
  String? secret;
  String? uri;
  String? factorId;
  final codeCtrl = TextEditingController();

  Future<void> _enroll() async {
    setState(() => loading = true);
    final res = await supabase.auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'HeartEase',
      friendlyName: 'Authenticator',
    ); // [web:13][web:10]
    factorId = res.id;
    secret = res.totp?.secret;
    uri = res.totp?.uri;
    setState(() => loading = false);
  }

  Future<void> _verify() async {
    if (factorId == null) return; // ensure enroll ran [web:13]
    setState(() => loading = true); // UI state [web:92]

    // 1) Create a challenge for this factor
    final challenge = await supabase.auth.mfa.challenge(
      factorId: factorId!,
    ); // returns challengeId [web:13]

    // 2) Verify using challengeId + factorId + code
    await supabase.auth.mfa.verify(
      challengeId: challenge.id, // required as per current API [web:13]
      factorId: factorId!, // enrolled factor [web:13]
      code: codeCtrl.text.trim(), // 6-digit from authenticator [web:13]
    );

    setState(() => loading = false); // UI state [web:92]
    if (!mounted) return; // safety [web:92]
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Two‑step verification enabled')),
    ); // feedback [web:92]
  }

  Future<void> _disable() async {
    setState(() => loading = true);
    final list = await supabase.auth.mfa.listFactors();
    final factors = list.totp; // already a List by your SDK typing
    for (final f in factors) {
      await supabase.auth.mfa.unenroll(f.id);
    }

    setState(() => loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Two‑step verification disabled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two‑Step Verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (secret == null)
            FilledButton(
              onPressed: loading ? null : _enroll,
              child: const Text('Set up authenticator'),
            ),
          if (uri != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Scan the QR in your authenticator app, then enter the 6‑digit code.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: '6‑digit code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : _verify,
              child: const Text('Verify & Enable'),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: loading ? null : _disable,
            child: const Text('Disable two‑step verification'),
          ),
        ],
      ),
    ); // [web:13]
  }
}

// ================== Change Email ==================
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});
  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> _submit() async {
    final newEmail = emailCtrl.text.trim();
    if (newEmail.isEmpty) return;
    setState(() {
      loading = true;
      message = null;
    });

    await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    ); // remove emailRedirectTo

    setState(() {
      loading = false;
      message =
          'Check your inbox to confirm the email change.'; // Supabase will email if secure change enabled
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'New email address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: const Text('Send confirmation'),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!),
            ],
          ],
        ),
      ),
    ); // [web:24]
  }
}

// ================== Change Password ==================
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> _submit() async {
    final p1 = passCtrl.text;
    final p2 = confirmCtrl.text;
    if (p1.isEmpty || p1 != p2) {
      setState(() => message = 'Passwords do not match');
      return;
    } // [web:33]
    setState(() {
      loading = true;
      message = null;
    });
    await supabase.auth.updateUser(
      UserAttributes(password: p1),
    ); // [web:24][web:33]
    setState(() {
      loading = false;
      message = 'Password updated';
    }); // [web:24]
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: const Text('Update password'),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!),
            ],
          ],
        ),
      ),
    ); // [web:24][web:33]
  }
}
