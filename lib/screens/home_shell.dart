import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/access_model.dart';
import '../models/prayer_model.dart';
import '../services/notification_service.dart';
import '../services/prayer_calculator_service.dart';
import '../services/supabase_service.dart';
import '../services/zones.dart';
import 'circle_manager_screen.dart';
import 'dashboard_screen.dart';
import 'journey_screen.dart';
import 'learn/learn_namaz_hub_screen.dart';
import 'onboarding_screen.dart';
import 'pending_screen.dart';

/// Bottom-nav shell. On start it syncs location with the server, schedules
/// notifications and listens for nudges.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final _calc = PrayerCalculatorService();
  final _db = SupabaseService.instance;
  Unsubscribe? _nudges;
  int _tab = 0;
  int _epoch = 0; // bumped when your location/settings change, rebuilds the tabs
  bool _bootstrapped = false;
  String? _bootError;
  String? _tzWarning;
  Timer? _travelTimer;
  bool _cooldownShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _db.settingsChanged.addListener(refreshAll);
    // Travel detection: check GPS again every 15 minutes while the app is
    // open, and whenever it comes back to the foreground.
    _travelTimer = Timer.periodic(const Duration(minutes: 15), (_) => _checkTravel());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _bootstrapped) _checkTravel();
  }

  Future<void> _bootstrap() async {
    try {
      if (_db.isDemo) {
        // Demo: your browser's location and time zone (Chrome DevTools →
        // Sensors can fake both), else a sample city.
        await _db.demo.locateMe(_calc);
        await _db.demo.restoreLocal();
        _db.applyProfile(await _db.myProfile());
        await _db.loadMyPeriods();
        _checkTimezone(_db.myLocation);
        final loc = _db.myLocation;
        if (loc != null) {
          await NotificationService.instance.init(loc.timezone);
          await _scheduleNotifications();
        }
        setState(() => _bootstrapped = true);
        return;
      }
      _db.applyProfile(await _db.myProfile());
      // Invite-only phase: a pending account only sets up its profile and waits.
      if (_db.access != AccessStatus.approved) {
        setState(() => _bootstrapped = true);
        return;
      }
      try {
        await _db.setMyLocation(await _calc.currentLocation());
      } on ServerRuleException catch (e) {
        // location_cooldown: keep the stored location; the server ignores small moves anyway.
        if (e.code != 'location_cooldown') rethrow;
      }
      _db.applyProfile(await _db.myProfile());
      if (_db.myGender == 'female') await _db.loadMyPeriods();
      final loc = _db.myLocation;
      if (loc == null) {
        throw StateError(tr('Location is needed to work out prayer times. Please allow location and try again.'));
      }
      _checkTimezone(loc);
      await NotificationService.instance.init(loc.timezone);
      await _scheduleNotifications();

      _nudges = _db.watchMyNudges((PrayerName p, String sender) async {
        final name = await _db.displayNameOf(sender);
        await NotificationService.instance.showNudge(p, name);
      });
      setState(() => _bootstrapped = true);
    } catch (e) {
      setState(
        () => _bootError = e is ServerRuleException
            ? e.message
            : e is StateError
            ? e.message
            : '$e',
      );
    }
  }

  /// Adhan + "20 minutes left" alerts for today and tomorrow.
  Future<void> _scheduleNotifications() async {
    final loc = _db.myLocation;
    if (loc == null) return;
    final calc = _db.myCalculator();
    final today = _db.myToday;
    final prayed = (await _db.myLogsFor(today)).where((l) => l.status.isDone).map((l) => l.prayer).toSet();
    await NotificationService.instance.scheduleDays([
      calc.windowsFor(loc, today),
      calc.windowsFor(loc, today.add(const Duration(days: 1))),
    ], alreadyPrayedToday: prayed);
  }

  /// The phone's time-zone setting only affects dates and how times are
  /// shown (windows come from GPS and the server clock), but a wrong one is
  /// confusing, so say so.
  void _checkTimezone(UserLocation? loc) {
    if (loc == null) return;
    final wrong = timezoneLooksWrong(loc.timezone, loc.longitude);
    setState(
      () => _tzWarning = wrong
          ? tr(
              "Your phone's time zone ({zone}) does not match where you are. Prayer times are still correct, "
              "but please fix the time zone in your phone's settings.",
              {'zone': loc.timezone},
            )
          : null,
    );
  }

  /// Moved to a new place (or changed time zone)? Update the server, which
  /// picks the local method and rate-limits moves (anti-cheat).
  Future<void> _checkTravel() async {
    final old = _db.myLocation;
    if (old == null || (_db.isDemo && _db.demo.myself.pinned)) return;
    UserLocation loc;
    try {
      loc = await _calc.currentLocation().timeout(const Duration(seconds: 10));
    } catch (_) {
      return; // no GPS right now: keep the last place
    }
    final moved =
        (loc.latitude - old.latitude).abs() > 0.05 ||
        (loc.longitude - old.longitude).abs() > 0.05 ||
        loc.timezone != old.timezone;
    if (!moved || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _db.setMyLocation(loc, place: tr('Your location'));
      _db.applyProfile(await _db.myProfile());
      _checkTimezone(_db.myLocation);
      await _scheduleNotifications();
      if (!mounted) return;
      setState(() => _epoch++);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '📍 ${tr('New place found. Prayer times now follow {place} ({method}).', {'place': _db.myPlaceLabel, 'method': calcMethodLabels[_db.myMethod] ?? _db.myMethod})}',
          ),
        ),
      );
    } on ServerRuleException catch (e) {
      if (e.code == 'location_cooldown' && !_cooldownShown) {
        _cooldownShown = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '📍 ${tr('New place found. To keep things fair, your place can change once every 6 hours, so your times will switch soon.')}',
            ),
          ),
        );
      }
    }
  }

  /// Called by Journey after you change settings or pick a demo city.
  void refreshAll() => setState(() => _epoch++);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _db.settingsChanged.removeListener(refreshAll);
    _travelTimer?.cancel();
    _nudges?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bootError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(_bootError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _bootError = null);
                    _bootstrap();
                  },
                  child: Text(tr('Try again')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_bootstrapped) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // First open: set up your profile (name, gender, age, madhab...) before
    // anything else. Everything stays editable under Journey.
    if (!_db.onboarded) {
      return OnboardingScreen(onDone: () => setState(() => _epoch++));
    }
    if (_db.access != AccessStatus.approved) {
      return PendingScreen(
        onApproved: () {
          setState(() => _bootstrapped = false);
          _bootstrap();
        },
      );
    }

    return Scaffold(
      body: Column(
        children: [
          if (_tzWarning != null)
            Material(
              color: const Color(0xFF4A1F1F),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text('⚠️ $_tzWarning', style: const TextStyle(fontSize: 12, color: Color(0xFFFFD6D6))),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: KeyedSubtree(
                key: ValueKey('$_tab-$_epoch'),
                child: const [DashboardScreen(), LearnNamazHubScreen(), CircleManagerScreen(), JourneyScreen()][_tab],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.mosque_outlined),
            selectedIcon: const Icon(Icons.mosque),
            label: tr('Today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: tr('Learn'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: tr('Circles'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_graph_outlined),
            selectedIcon: const Icon(Icons.auto_graph),
            label: tr('Journey'),
          ),
        ],
      ),
    );
  }
}
