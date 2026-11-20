import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/circle_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';
import 'circle_matrix_screen.dart';

/// Create a circle, join one with a 6-digit code, or open a circle's live
/// matrix. Codes are generated and checked on the server (10 wrong tries per
/// hour at most). Owners approve new members by default.
class CircleManagerScreen extends StatefulWidget {
  const CircleManagerScreen({super.key});

  @override
  State<CircleManagerScreen> createState() => _CircleManagerScreenState();
}

class _CircleManagerScreenState extends State<CircleManagerScreen> {
  final _db = SupabaseService.instance;
  List<Circle> _circles = [];
  List<String> _waiting = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _db.myCircles();
    final w = await _db.myJoinRequests();
    if (mounted) {
      setState(() {
        _circles = c;
        _waiting = w;
        _loading = false;
      });
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
      await _load();
    } on ServerRuleException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _create() async {
    final name = TextEditingController();
    var requirePhoto = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(c).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('New circle'), style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                autofocus: true,
                maxLength: 40,
                decoration: InputDecoration(labelText: tr('Name (for example: Family, Hostel Room 4)')),
              ),
              SwitchListTile(
                value: requirePhoto,
                onChanged: (v) => set(() => requirePhoto = v),
                title: Text('📸 ${tr('Photo proof')}'),
                subtitle: Text(
                  tr('Members take a photo of their prayer mat after each prayer. Best for close family.'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Create'))),
            ],
          ),
        ),
      ),
    );
    if (ok == true && name.text.trim().length >= 2) {
      await _run(() async {
        final circle = await _db.createCircle(name.text.trim(), requirePhoto: requirePhoto);
        _toast(tr('Circle created. Code: {code}', {'code': circle.inviteCode}));
      });
    }
  }

  Future<void> _join() async {
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Join a circle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('Enter the 6-digit code you were given.')),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: code,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 10),
                decoration: const InputDecoration(hintText: '000000', counterText: ''),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Join'))),
        ],
      ),
    );
    if (ok == true && code.text.length == 6) {
      await _run(() async {
        final r = await _db.joinCircle(code.text);
        _toast(
          r.joined
              ? tr('You joined {circle} 🤝', {'circle': r.circleName})
              : tr('Request sent to the owner of {circle}. You will be added when they accept.', {
                  'circle': r.circleName,
                }),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Circles')), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: Text(tr('Create')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _join,
                            icon: const Icon(Icons.pin_outlined),
                            label: Text(tr('Join with code')),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final w in _waiting)
                    GlassCard(
                      glow: AppColors.gold,
                      child: Row(
                        children: [
                          const Text('⏳', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('Waiting for the owner of {circle} to accept you', {'circle': w}),
                              style: t.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_circles.isEmpty && _waiting.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        tr('No circles yet.\nCreate one and share the code with your family or friends.'),
                        textAlign: TextAlign.center,
                        style: t.bodyLarge,
                      ),
                    ),
                  for (final c in _circles) _circleTile(c),
                ],
              ),
            ),
    );
  }

  Widget _circleTile(Circle c) {
    final isOwner = c.createdBy == _db.userId;
    return GlassCard(
      glow: c.requirePhoto ? AppColors.gold : AppColors.emerald,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emerald.withValues(alpha: 0.15),
            boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.4), blurRadius: 12)],
          ),
          child: const Text('🕌', style: TextStyle(fontSize: 20)),
        ),
        title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${tr('Code {code}', {'code': c.inviteCode})}${c.requirePhoto ? ' · 📸 ${tr('Photo proof')}' : ''}',
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CircleMatrixScreen(circle: c))),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => switch (v) {
            'copy' => Clipboard.setData(
              ClipboardData(
                text: tr('Join my prayer circle "{circle}" on Niskaricho? (നിസ്കരിച്ചോ?) with code {code}', {
                  'circle': c.name,
                  'code': c.inviteCode,
                }),
              ),
            ).then((_) => _toast(tr('Invite copied'))),
            'photo' => _run(() => _db.updateCircle(c.id, requirePhoto: !c.requirePhoto)),
            'code' => _run(() => _db.updateCircle(c.id, regenerateCode: true)),
            'leave' => _run(() => _db.leaveCircle(c.id)),
            _ => null,
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'copy', child: Text(tr('Copy invite'))),
            if (isOwner) ...[
              PopupMenuItem(
                value: 'photo',
                child: Text(c.requirePhoto ? tr('Turn off photo proof') : tr('Turn on photo proof')),
              ),
              PopupMenuItem(value: 'code', child: Text(tr('New invite code'))),
            ],
            PopupMenuItem(value: 'leave', child: Text(tr('Leave circle'))),
          ],
        ),
      ),
    );
  }
}
