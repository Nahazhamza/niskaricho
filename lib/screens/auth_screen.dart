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
                const SizedBox(height: 36),
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
