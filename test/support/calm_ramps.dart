/// The seven Calm status families, by name.
///
/// Written once. Three test files wanted this table and each grew its own —
/// two as `Map<String, CalmRamp>` and one as `Map<String, CalmRamp Function>`
/// — which is three places to forget an eighth family.
library;

import 'package:odova/theme/calm/calm_colors.dart';

/// Each family's accessor, keyed by the `DueState` name it belongs to.
///
/// `business` is the odd one out: it is the personal/business split, not a due
/// state, and it has no `DueState` member.
const rampAccessors = <String, CalmRamp Function(CalmColors)>{
  'overdue': _overdue,
  'due': _due,
  'dueSoon': _dueSoon,
  'ok': _ok,
  'unknown': _unknown,
  'needsOdometer': _needsOdometer,
  'business': _business,
};

/// The families of [colours], resolved.
Map<String, CalmRamp> rampsOf(CalmColors colours) => {
  for (final MapEntry(key: name, value: accessor) in rampAccessors.entries)
    name: accessor(colours),
};

CalmRamp _overdue(CalmColors c) => c.overdue;
CalmRamp _due(CalmColors c) => c.due;
CalmRamp _dueSoon(CalmColors c) => c.dueSoon;
CalmRamp _ok(CalmColors c) => c.ok;
CalmRamp _unknown(CalmColors c) => c.unknown;
CalmRamp _needsOdometer(CalmColors c) => c.needsOdometer;
CalmRamp _business(CalmColors c) => c.business;
