// The day Home computes against, and the two things that change it.
//
// SPEC.md §9's *Recompute triggers* lists seven. Five arrive for free through
// the streams the screen already watches — a write to the vehicle, a switch, a
// locale or unit change, an import commit, and the first read. The two that do
// not are LOCAL MIDNIGHT and APP RESUME, because neither writes a row: the
// calendar moves and the data does not.
//
// So they move a value the screen watches instead. `todayProvider` holds the
// civil date; a timer set to the next local midnight advances it, and a resume
// re-reads it — a phone asleep across midnight gets no timer callback, and
// waking up on yesterday's date is exactly the failure §9's trigger list
// exists to prevent.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/time/civil_date.dart';

/// Whether the midnight timer and the resume observer are armed.
///
/// False by default and true in production, the same way `uiStateProviderStore`
/// is injected. A timer set for up to 24 hours outlives every widget test and
/// `testWidgets` fails the NEXT test over one still pending; and
/// `WidgetsBinding.instance` does not exist in a plain `test`, so registering
/// an observer there throws on dispose.
///
/// The BEHAVIOUR is tested without either — advance the injected clock, call
/// `refresh`, watch the day move. These two are only the schedulers.
final todayTicksProvider = Provider<bool>((ref) => false);

/// The civil date Home is computing against.
class Today extends Notifier<CivilDate?> {
  Timer? _midnight;
  _TodayLifecycle? _observer;

  @override
  CivilDate? build() {
    ref.onDispose(_stop);
    _arm();
    return _read();
  }

  CivilDate? _read() =>
      CivilDate.fromDateTime(ref.read(clockProvider).now().toLocal());

  /// Re-reads the clock, and re-arms if the day moved.
  ///
  /// Idempotent on purpose: a resume that lands on the same day changes
  /// nothing, and a provider that emitted a new-but-equal value would rebuild
  /// Home for every trip to the home screen.
  void refresh() {
    final now = _read();
    if (now != state) state = now;
    _arm();
  }

  void _arm() {
    _midnight?.cancel();
    // BOTH schedulers behind the same flag. The timer outlives a widget test
    // and `WidgetsBinding.instance` does not exist in a plain one, so an
    // unguarded observer throws on dispose — and neither is the behaviour: the
    // behaviour is `refresh`, which the tests call directly.
    if (!ref.read(todayTicksProvider)) return;

    if (_observer == null) {
      _observer = _TodayLifecycle(refresh);
      WidgetsBinding.instance.addObserver(_observer!);
    }

    final now = ref.read(clockProvider).now().toLocal();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    // A DURATION to the next local midnight, not a periodic day: a periodic
    // timer drifts across a daylight-saving change, and the one day of the
    // year it is wrong is the day an hour of it does not exist.
    _midnight = Timer(tomorrow.difference(now), refresh);
  }

  void _stop() {
    _midnight?.cancel();
    _midnight = null;
    final observer = _observer;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
      _observer = null;
    }
  }
}

/// The day Home computes against — local, and never `DateTime.now()`.
final NotifierProvider<Today, CivilDate?> todayProvider =
    NotifierProvider<Today, CivilDate?>(Today.new);

/// Calls back on `resumed`.
///
/// A phone asleep across midnight gets no timer callback, so waking is the
/// other half of the same trigger.
class _TodayLifecycle extends WidgetsBindingObserver {
  _TodayLifecycle(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
