import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Passwordless sign-in: email -> 6-digit code.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _invite = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (SupabaseService.instance.isDemo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Demo mode active: Signed in as demo user.')),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      await SupabaseService.instance.signInWithGoogle(inviteCode: _invite.text.trim());
    } catch (e) {
      setState(() => _error = tr('That did not work. Check the email or code and try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_codeSent) {
        await SupabaseService.instance.sendEmailOtp(_email.text.trim(), inviteCode: _invite.text.trim());
        setState(() => _codeSent = true);
      } else {
        await SupabaseService.instance.verifyEmailOtp(_email.text.trim(), _code.text.trim());
      }
    } catch (e) {
      setState(() => _error = tr('That did not work. Check the email or code and try again.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SvgPicture.asset('assets/icon/niskaricho_icon.svg', height: 120),
                const SizedBox(height: 20),
                Text(tr('Niskaricho?'), textAlign: TextAlign.center, style: t.headlineLarge),
                Text(
                  tr('Niskaricho? · Did you pray?'),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Pray on time, together. Open-source and ad-free.'),
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
                const SizedBox(height: 32),

                // 1-Click Google Sign-In
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  onPressed: _busy ? null : _signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                        height: 20,
                        width: 20,
                        errorBuilder: (_, _, _) => const Icon(Icons.account_circle, size: 20, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tr('Continue with Google'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.sand.withValues(alpha: 0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        tr('or continue with email'),
                        style: t.bodySmall?.copyWith(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.sand.withValues(alpha: 0.2))),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _email,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: tr('Email'), prefixIcon: Icon(Icons.mail_outline)),
                ),
                if (!_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invite,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: tr('Invite code (if you have one)'),
                      helperText: tr('Without a code, the admin approves you first.'),
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                  ),
                ],
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(labelText: tr('6-digit code from your email')),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_codeSent ? tr('Check code and continue') : tr('Send me a code')),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.missed)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
