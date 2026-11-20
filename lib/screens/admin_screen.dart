import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/access_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import 'pending_screen.dart';

/// Super admin: who may use the app (invite-only early phase).
/// People: approve, reject, remove, make admin. Invite codes: create, copy, revoke.
/// Everything is checked again on the server (admin_* functions).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _db = SupabaseService.instance;
  List<AdminUser> _users = [];
  List<InviteCode> _codes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await _db.adminUsers();
      final c = await _db.adminInvites();
      if (mounted) {
        setState(() {
          _users = u;
          _codes = c;
          _loading = false;
        });
      }
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run(Future<void> Function() f, String done) async {
    try {
      await f();
      _toast(done);
      await _load();
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _confirmThen(String question, Future<void> Function() f, String done) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(question, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Yes'))),
        ],
      ),
    );
    if (ok == true) await _run(f, done);
  }

  Future<void> _newCode() async {
    var uses = 1;
    var days = 7;
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(tr('New invite code')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: note,
                maxLength: 60,
                decoration: InputDecoration(labelText: tr('Who is it for? (optional)')),
              ),
              Text(tr('How many people can use it')),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: [
                  for (final n in [1, 5, 20]) ButtonSegment(value: n, label: Text('$n')),
                ],
                selected: {uses},
                showSelectedIcon: false,
                onSelectionChanged: (s) => set(() => uses = s.first),
              ),
              const SizedBox(height: 12),
              Text(tr('Works for')),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: [
                  for (final d in [1, 7, 30]) ButtonSegment(value: d, label: Text(trn('1 day', '{n} days', d))),
                ],
                selected: {days},
                showSelectedIcon: false,
                onSelectionChanged: (s) => set(() => days = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Create'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final ic = await _db.adminCreateInvite(maxUses: uses, days: days, note: note.text);
      await _copy(ic);
      await _load();
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _copy(InviteCode ic) async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: tr(
            'Assalamu alaikum! Join our prayer circle app Niskaricho? (നിസ്കരിച്ചോ?). Your invite code: {code}',
            {'code': ic.code},
          ),
        ),
      );
      _toast(tr('Code {code} copied. Send it on WhatsApp.', {'code': ic.code}));
    } catch (_) {
      _toast(ic.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _users.where((u) => u.status == AccessStatus.pending).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('🛡️ ${tr('Admin')}'),
          actions: [
            IconButton(
              tooltip: tr('Preview: new person'),
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PendingScreen(preview: true, onApproved: () => Navigator.of(context).pop()),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: pending.isEmpty ? tr('People') : '${tr('People')} (${pending.length})'),
              Tab(text: tr('Invite codes')),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_people(pending), _invites()]),
      ),
    );
  }

  Widget _people(List<AdminUser> pending) {
    final t = Theme.of(context).textTheme;
    final others = _users.where((u) => u.status != AccessStatus.pending).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              'Only people you approve can use the app. New sign-ups wait here, or join with an invite code you give them.',
            ),
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (pending.isNotEmpty) Text(tr('Waiting for you'), style: t.titleMedium),
          for (final u in pending) _userCard(u, t),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(tr('Nobody is waiting.'), style: t.bodyMedium),
            ),
          const SizedBox(height: 12),
          Text(tr('Everyone'), style: t.titleMedium),
          for (final u in others) _userCard(u, t),
        ],
      ),
    );
  }

  String _statusLabel(AccessStatus s) => switch (s) {
    AccessStatus.pending => tr('Waiting'),
    AccessStatus.approved => tr('Approved'),
    AccessStatus.rejected => tr('Rejected'),
    AccessStatus.removed => tr('Removed'),
  };

  Widget _userCard(AdminUser u, TextTheme t) {
    final color = switch (u.status) {
      AccessStatus.pending => AppColors.gold,
      AccessStatus.approved => AppColors.onTime,
      _ => AppColors.missed,
    };
    final when = DateFormat.yMMMd(L10n.lang.value.name).format(u.createdAt.toLocal());
    return GlassCard(
      glow: u.status == AccessStatus.pending ? AppColors.gold : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${u.name}${u.isAdmin ? ' · 🛡️ ${tr('Admin')}' : ''}', style: t.titleMedium)),
              Text(
                _statusLabel(u.status),
                style: t.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Text(u.email, style: t.bodyMedium),
          Text(
            u.invitedWith == null
                ? tr('Signed up {date}', {'date': when})
                : tr('Signed up {date} with code {code}', {'date': when, 'code': u.invitedWith}),
            style: t.bodySmall,
          ),
          if (!u.isAdmin) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (u.status != AccessStatus.approved)
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(tr('Approve')),
                    onPressed: () => _run(
                      () => _db.adminSetAccess(u.id, AccessStatus.approved),
                      tr('{name} can now use the app', {'name': u.name}),
                    ),
                  ),
                if (u.status == AccessStatus.pending)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: Text(tr('Reject')),
                    onPressed: () => _confirmThen(
                      tr('Reject {name}?', {'name': u.name}),
                      () => _db.adminSetAccess(u.id, AccessStatus.rejected),
                      tr('Rejected'),
                    ),
                  ),
                if (u.status == AccessStatus.approved) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_remove_outlined),
                    label: Text(tr('Remove')),
                    onPressed: () => _confirmThen(
                      tr('Remove {name}? They will be taken out of every circle and cannot use the app.', {
                        'name': u.name,
                      }),
                      () => _db.adminSetAccess(u.id, AccessStatus.removed),
                      tr('Removed'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmThen(
                      tr('Make {name} an admin? Admins can approve and remove people.', {'name': u.name}),
                      () => _db.adminSetAdmin(u.id, true),
                      tr('Done'),
                    ),
                    child: Text(tr('Make admin')),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _invites() {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              'An invite code lets a person in without waiting. Give each family or person their own code. You can stop a code at any time.',
            ),
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _newCode,
              icon: const Icon(Icons.add),
              label: Text(tr('New invite code')),
            ),
          ),
          const SizedBox(height: 8),
          for (final c in _codes)
            GlassCard(
              glow: c.usable(now) ? AppColors.emerald : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(c.code, style: t.titleLarge?.copyWith(letterSpacing: 3)),
                        ),
                      ),
                      Text(
                        c.revokedAt != null
                            ? tr('Stopped')
                            : !c.expiresAt.isAfter(now)
                            ? tr('Expired')
                            : c.used >= c.maxUses
                            ? tr('Used up')
                            : tr('Active'),
                        style: t.bodyMedium?.copyWith(
                          color: c.usable(now) ? AppColors.onTime : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (c.note != null) Text(c.note!, style: t.bodyMedium),
                  Text(
                    tr('Used {used} of {max} · until {date}', {
                      'used': c.used,
                      'max': c.maxUses,
                      'date': DateFormat.MMMd(L10n.lang.value.name).format(c.expiresAt.toLocal()),
                    }),
                    style: t.bodySmall,
                  ),
                  if (c.usable(now))
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copy(c),
                          icon: const Icon(Icons.copy),
                          label: Text(tr('Copy message')),
                        ),
                        TextButton.icon(
                          onPressed: () => _confirmThen(
                            tr('Stop code {code}? Nobody new can use it. People already in stay in.', {'code': c.code}),
                            () => _db.adminRevokeInvite(c.code),
                            tr('Stopped'),
                          ),
                          icon: const Icon(Icons.block),
                          label: Text(tr('Stop code')),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
