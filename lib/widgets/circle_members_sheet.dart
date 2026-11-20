import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/access_model.dart';
import '../models/circle_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Circle owner tools: answer join requests, ask before people join, remove members.
Future<void> showCircleMembersSheet(BuildContext context, Circle circle, List<MatrixRow> rows) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MembersSheet(circle: circle, rows: rows),
    );

class _MembersSheet extends StatefulWidget {
  const _MembersSheet({required this.circle, required this.rows});
  final Circle circle;
  final List<MatrixRow> rows;

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  final _db = SupabaseService.instance;
  List<JoinRequest> _requests = [];
  late bool _approve = widget.circle.approveJoins;
  late final _members = {for (final r in widget.rows) r.userId: r.displayName};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _db.joinRequests(widget.circle.id);
    if (mounted) setState(() => _requests = r);
  }

  Future<void> _run(Future<void> Function() f, String done) async {
    try {
      await f();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ServerRuleException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(tr('Members of {circle}', {'circle': widget.circle.name}), style: t.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _approve,
              title: Text(tr('Ask me before people join')),
              subtitle: Text(tr('Anyone with the code sends a request. You say yes or no.')),
              onChanged: (v) async {
                setState(() => _approve = v);
                await _run(() => _db.setApproveJoins(widget.circle.id, v), tr('Saved'));
              },
            ),
            const Divider(),
            Text(tr('Join requests'), style: t.titleMedium),
            if (_requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(tr('No requests.'), style: t.bodyMedium),
              ),
            for (final r in _requests)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.name, style: t.titleMedium),
                subtitle: Text(tr('Wants to join')),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton.filled(
                      tooltip: tr('Accept'),
                      icon: const Icon(Icons.check),
                      onPressed: () => _run(
                        () => _db.answerJoinRequest(widget.circle.id, r.userId, true),
                        tr('{name} joined the circle', {'name': r.name}),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: tr('Decline'),
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          _run(() => _db.answerJoinRequest(widget.circle.id, r.userId, false), tr('Declined')),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Text(tr('Members'), style: t.titleMedium),
            for (final e in _members.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.key == _db.userId ? tr('You') : e.value, style: t.titleMedium),
                subtitle: e.key == widget.circle.createdBy ? Text(tr('Owner')) : null,
                trailing: e.key == _db.userId || e.key == widget.circle.createdBy
                    ? null
                    : TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.missed),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              content: Text(tr('Remove {name} from this circle?', {'name': e.value})),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
                                FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Remove'))),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          await _run(() => _db.removeMember(widget.circle.id, e.key), tr('Removed'));
                          setState(() => _members.remove(e.key));
                        },
                        child: Text(tr('Remove')),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
