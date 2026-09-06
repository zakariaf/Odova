/// The four `log.*` forms under the artboard's own data.
///
/// One authority for four captures, because they are one modal with four bodies
/// and four fixtures would be four modals with one name. The vehicle is the
/// artboard's Golf; the readings behind it are what make the helper line and
/// the estimate chip appear.
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/logging/ui/log_modal.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../features/home/home_fixture.dart';

/// The log modal on [type], ready to be a capture's `child`.
///
/// Every stream is SUPPLIED. The forms read the vehicle, its settings and its
/// due snapshot, and a drift stream never delivers inside a widget test's fake
/// async — the capture would photograph the pre-data frame, which is a real
/// state and not this one.
Widget logBackdrop({
  required LogType type,
  required bool rtl,
  required Locale locale,
}) => ProviderScope(
  overrides: <Override>[
    settingsProvider.overrideWith((ref) => Stream.value(homeSettings(golfId))),
    vehiclesProvider.overrideWith(
      (ref) => Stream.value([homeVehicle(golfId, rtl ? 'گلف' : 'The Golf')]),
    ),
    serviceItemsProvider(golfId).overrideWith(
      (ref) => Stream.value([
        homeItem(rtl ? 'روغن و فیلتر' : 'Oil and filter'),
        homeItem(rtl ? 'فیلتر هوا' : 'Air filter', suffix: 'B'),
      ]),
    ),
    vehicleDueSnapshotProvider(golfId).overrideWithValue(
      homeSnapshot(const [], estimate: homeEstimate(187412)),
    ),
    latestFillUpProvider(golfId).overrideWith((ref) => Stream.value(null)),
    serviceRecordsProvider(
      golfId,
    ).overrideWith((ref) => Stream.value(const [])),
    clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 2, 12))),
    deviceLocalesProvider.overrideWithValue([
      Locale(
        locale.languageCode,
        locale.languageCode == 'en' ? 'GB' : 'DE',
      ),
    ]),
  ],
  child: LogModalShell(type: type),
);
