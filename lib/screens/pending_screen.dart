import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/access_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import '../widgets/islamic_icons.dart';

/// Shown while an account waits for the admin (invite-only early phase), or
/// when access was closed. A personal invite code opens the app straight away.
class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.onApproved, this.preview = false});
  final VoidCallback onApproved;

  /// Admin preview: "what a new person sees". Nothing is changed.
  final bool preview;

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final _db = SupabaseService.instance;
  final _code = TextEditingController();
  bool _busy = false;
  String? _msg;

  Future<void> _redeem() async {
    if (_code.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final r = await _db.redeemInvite(_code.text);
      if (!mounted) return;
      if (r == 'approved') {
        widget.onApproved();
      } else {
        setState(() => _msg = ServerRuleException(r).message);
      }
    } on ServerRuleException catch (e) {
      setState(() => _msg = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      _db.applyProfile(await _db.myProfile());
      if (_db.access == AccessStatus.approved && !widget.preview) {
        widget.onApproved();
      } else {
        setState(() => _msg = tr('Not approved yet. Please check again later.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final closed = !widget.preview && (_db.access == AccessStatus.rejected || _db.access == AccessStatus.removed);
    return Scaffold(
      appBar: widget.preview ? AppBar(title: Text(tr('Preview: new person'))) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              children: [
                Center(child: CrescentIcon(size: 48, color: closed ? AppColors.muted : AppColors.gold)),
                const SizedBox(height: 14),
                Text(
                  closed ? tr('Access closed') : tr('Waiting for approval'),
                  textAlign: TextAlign.center,
                  style: t.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  closed
                      ? tr(
                          'The admin has closed access for this account. If you think this is a mistake, please ask them.',
                        )
                      : tr(
                          'This app is invite only for now. The admin will approve you soon. If someone gave you an invite code, enter it below to start now.',
                        ),
                  textAlign: TextAlign.center,
                  style: t.bodyLarge,
                ),
                if (!closed) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(labelText: tr('Invite code'), hintText: 'ABCD2345'),
                          onSubmitted: (_) => _redeem(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _busy ? null : _redeem, child: Text(tr('Use code'))),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _busy ? null : _check,
                          child: Text(tr('I was approved, check again')),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _msg!,
                      textAlign: TextAlign.center,
                      style: t.bodyLarge?.copyWith(color: AppColors.gold),
                    ),
                  ),
                const SizedBox(height: 24),
                if (!widget.preview && !_db.isDemo) TextButton(onPressed: _db.signOut, child: Text(tr('Sign out'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
