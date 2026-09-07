// SPEC.md §6 §3.1's fill-in table, as one pure function.
//
// Filling in absent fields is what the chain mostly does, and the table is
// mostly a list of decisions somebody already made about what a missing value
// MEANT. `vehicles[].status` is the one worth reading twice: the old `archived`
// boolean is read and then dropped, so a vehicle the user archived years ago
// does not come back into their garage as active.
//
// Two rules from §3.1 govern every line here. Rule 1: never delete a user
// value — which is why `whichever_last` keeps both intervals and is COUNTED
// rather than having one of them cleared. Rule 2: never fail on missing data —
// which is why every read is a lookup with a default and never a cast.
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/time/civil_date.dart';

/// [document] with every absent field from §6 §3.1 filled in.
///
/// Never overwrites a value the file already carries. A file that says
/// `quiet_hours_from: "23:30"` came from a user who set it, and a default that
/// won over a stated value would be the app editing somebody's settings.
Map<String, Object?> fillDefaults(Map<String, Object?> document) => {
  ...document,
  'settings': _settings(_mapAt(document, 'settings')),
  'vehicles': _each(document, 'vehicles', _vehicle),
  'reminders': _each(document, 'reminders', _reminder),
  'services': _each(document, 'services', _service),
};

/// How many reminders used the retired `whichever_last` rule.
///
/// Counted rather than corrected, because it is the one retired value that
/// CHANGES BEHAVIOUR: an item that warned at whichever came last now warns at
/// whichever comes first, and the user has to be told so they can check it.
/// The other two rules only clear an interval that was already being ignored.
int countDroppedRules(Map<String, Object?> document) =>
    _rows(document, 'reminders')
        .whereType<Map<String, Object?>>()
        .where((reminder) => reminder['rule'] == 'whichever_last')
        .length;

Map<String, Object?> _vehicle(Map<String, Object?> vehicle) {
  final out = {...vehicle}..remove('archived');
  return {
    ...out,
    // The boolean only decides the status when the file has no status of its
    // own: `sold` is a third value the boolean cannot express, and a file
    // carrying both is newer than the boolean it also carries.
    'status':
        vehicle['status'] ??
        (vehicle['archived'] == true ? 'archived' : 'active'),
    'type': vehicle['type'] ?? 'car',
    'is_business': vehicle['is_business'] ?? false,
    'notifications_muted': vehicle['notifications_muted'] ?? false,
  };
}

Map<String, Object?> _reminder(Map<String, Object?> reminder) {
  final rule = reminder['rule'];
  final out = {...reminder}..remove('rule');
  return {
    ...out,
    // `distance_only` and `date_only` clear the interval the rule was already
    // suppressing, so nothing the user could see is lost. `whichever_last`
    // keeps both and is counted instead — clearing one would delete a value
    // the user entered, which §3.1 rule 1 forbids.
    if (rule == 'distance_only') 'interval_months': null,
    if (rule == 'date_only') 'interval_distance_m': null,
    'notify': reminder['notify'] ?? true,
    'repeats': reminder['repeats'] ?? true,
    'is_active': reminder['is_active'] ?? true,
    'is_tracked': reminder['is_tracked'] ?? true,
    'priority': reminder['priority'] ?? 'normal',
    'rollover': reminder['rollover'] ?? 'from_actual',
    'snooze_count': reminder['snooze_count'] ?? 0,
  };
}

Map<String, Object?> _service(Map<String, Object?> service) => {
  ...service,
  'odometer_estimated': service['odometer_estimated'] ?? false,
  'cost_estimated': service['cost_estimated'] ?? false,
};

Map<String, Object?> _settings(Map<String, Object?> settings) => {
  ...settings,
  'quiet_hours_from':
      settings['quiet_hours_from'] ??
      wallClockOfMinutes(kDefaultQuietFromMinutes),
  'quiet_hours_to':
      settings['quiet_hours_to'] ?? wallClockOfMinutes(kDefaultQuietToMinutes),
  'weekdays_only': settings['weekdays_only'] ?? false,
  'notify_service': settings['notify_service'] ?? true,
  'notify_odometer': settings['notify_odometer'] ?? true,
  'notify_backup': settings['notify_backup'] ?? true,
  // §5's one locale-dependent default. A Persian file written before the field
  // existed came from a phone where the amounts were being read as toman, and
  // defaulting it to `none` would silently multiply every displayed price by
  // ten.
  'currency_display':
      settings['currency_display'] ??
      (settings['language'] == 'fa' ? 'toman' : 'none'),
};

Map<String, Object?> _mapAt(Map<String, Object?> document, String key) =>
    document[key] is Map<String, Object?>
    ? document[key]! as Map<String, Object?>
    : const {};

List<Object?> _rows(Map<String, Object?> document, String array) =>
    document[array] is List ? document[array]! as List : const <Object?>[];

List<Object?> _each(
  Map<String, Object?> document,
  String array,
  Map<String, Object?> Function(Map<String, Object?>) fill,
) => [
  for (final row in _rows(document, array))
    if (row is Map<String, Object?>) fill(row) else row,
];
