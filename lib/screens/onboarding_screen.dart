import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../widgets/fx.dart';
import '../widgets/islamic_icons.dart';
import '../widgets/profile_form.dart';

/// First open: a short profile so prayer rules fit the person.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                const Center(child: CrescentIcon(size: 44, color: Color(0xFFD4A84B))),
                const SizedBox(height: 10),
                Text(tr('Assalamu alaikum'), textAlign: TextAlign.center, style: t.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  tr('Set up your profile. It takes a minute and you can change it later in Journey.'),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: ProfileForm(onSaved: onDone, saveLabel: tr('Continue')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
