import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'services/demo_backend.dart';
import 'screens/home_shell.dart';
import 'screens/language_screen.dart';
import 'l10n/tr.dart';
import 'theme/app_theme.dart';
import 'theme/look.dart';
import 'widgets/fx.dart';

/// Pass your project values at build time:
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Look.load();
  await L10n.load();
  // Without credentials the app runs in demo mode (sample data, no backend).
  if (!kDemoMode) await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  runApp(const NiskarichoApp());
}

class NiskarichoApp extends StatelessWidget {
  const NiskarichoApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLang>(
    valueListenable: L10n.lang,
    // Changing language rebuilds the whole app in the new language and
    // direction (Arabic is right to left).
    builder: (context, lang, _) => MaterialApp(
      key: ValueKey(lang),
      title: 'Niskaricho?',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: lang.locale,
      supportedLocales: [for (final l in AppLang.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => ListenableBuilder(
        listenable: Listenable.merge([Look.style, Look.lite, L10n.textScale]),
        builder: (context, _) {
          final mq = MediaQuery.of(context);
          // Bigger text for older eyes (on top of the phone's own setting).
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * L10n.textScale.value)),
            child: LookScope(
              style: Look.style.value,
              // Also honour the phone's "remove animations" accessibility setting.
              lite: Look.lite.value || (mq.disableAnimations),
              child: CosmicBackground(child: child ?? const SizedBox()),
            ),
          );
        },
      ),
      home: const _Start(),
    ),
  );
}

/// Language first (shown once), then sign-in or the app.
class _Start extends StatefulWidget {
  const _Start();

  @override
  State<_Start> createState() => _StartState();
}

class _StartState extends State<_Start> {
  @override
  Widget build(BuildContext context) {
    if (!L10n.chosen) return LanguageScreen(onDone: () => setState(() {}));
    return kDemoMode ? const HomeShell() : const _AuthGate();
  }
}

/// Shows the sign-in screen or the app, following the Supabase session.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  Session? _session = Supabase.instance.client.auth.currentSession;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) => setState(() => _session = s.session));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _session == null ? const AuthScreen() : const HomeShell();
}
