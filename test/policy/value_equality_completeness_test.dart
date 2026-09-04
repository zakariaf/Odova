// Every field of a value type appears in its `props`.
//
// `ValueEquality` removed the duplication between `==` and `hashCode`, but not
// the one between the FIELD LIST and `props`. A field declared and forgotten in
// `props` makes two different records compare equal — and because every watch
// stream in the data layer de-duplicates on that equality, the consequence is
// not a subtle bug: it is a real edit that never reaches the screen, silently,
// with the database already updated.
//
// Counted from the source rather than reflected, because Dart has no mirrors
// outside `dart:mirrors` and the models are deliberately Flutter-free.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

/// A class declaration, its instance fields, and its `props` entries.
typedef ValueClass = ({String name, Set<String> fields, Set<String> props});

/// Every `with ValueEquality` class in [source].
List<ValueClass> valueClassesIn(String source) {
  final classes = <ValueClass>[];

  // Split on every top-level declaration, not only `class`. An `enum` after a
  // class in the same file was absorbed into the class's chunk, so
  // `DistanceUnit`'s `final String wire` was read as a field of `Distance` —
  // and the gate reported a false positive on the first file that put a value
  // type and its unit enum together, which is every units file.
  final chunks = source.split(
    RegExp(
      '^(?=(?:final |sealed |abstract |base |interface )*'
      '(?:class|enum|mixin|extension|typedef) )',
      multiLine: true,
    ),
  );
  for (final chunk in chunks) {
    final header = RegExp(
      r'^(?:final |sealed |abstract )*class (\w+)[^{]*\bwith\b[^{]*ValueEquality',
    ).firstMatch(chunk);
    if (header == null) continue;

    // `final <Type> <name>;` at two-space indent — an instance field. A
    // `static` or a getter is not one.
    final fields = RegExp(
      r'^  final [\w<>?, ]+ (\w+);',
      multiLine: true,
    ).allMatches(chunk).map((m) => m.group(1)!).toSet();

    final propsBody = RegExp(
      r'List<Object\?> get props => (?:const )?\[(.*?)\];',
      dotAll: true,
    ).firstMatch(chunk);

    // Split on commas and take the bare identifiers. A regex over the whole
    // body needed a trailing comma to match, so `[a, b]` on one line yielded
    // only `a` — and the completeness test passed anyway, over a parser that
    // had found half the entries. That is what the guard test below is for.
    final props = propsBody == null
        ? <String>{}
        : propsBody
              .group(1)!
              .split(',')
              .map((entry) => entry.replaceAll('...', '').trim())
              .where((entry) => RegExp(r'^\w+$').hasMatch(entry))
              .toSet();

    classes.add((name: header.group(1)!, fields: fields, props: props));
  }
  return classes;
}

void main() {
  test('every field of every value type is in its props', () {
    // A field whose value is ENCODED into props rather than listed by name.
    // `MoneyTotal` holds two Maps, and a Map in props compares by identity —
    // so two totals built from the same amounts would never be equal. It
    // encodes both as sorted strings instead, which the parser cannot see.
    //
    // Named individually with the reason, not waved through by type: the gate
    // caught a real bug in this very class before the encoding was complete —
    // the row counts were outside equality while `dominantCurrency` read them,
    // so two "equal" totals answered differently.
    const encodedNotListed = {
      // Two Maps. A Map in props compares by IDENTITY, so two totals built
      // from the same amounts would never be equal; both are encoded as
      // sorted strings instead — computed once in the factory and STORED,
      // because `props` is read by both `==` and `hashCode` and re-sorting
      // two maps per read made one comparison four sorts. `props` itself is
      // then a field, which is why it is named here: a field literally called
      // `props` cannot be listed inside itself.
      'lib/core/money/money_total.dart': {'byCurrency', '_counts', 'props'},
      // Same shape, and then some. `props` is computed ONCE in the factory
      // (see `MoneyTotal` above for why), which makes it a field that cannot
      // list itself, and `flaggedFillUpIds` is the sorted key set cached
      // beside it — both are IN the stored encoding rather than named in it.
      // `segments` is spread into it, and `warnings` and `discarded` are the
      // two Maps, encoded because a Map in props compares by identity.
      'lib/core/fuel/fuel_segment.dart': {
        'segments',
        'warnings',
        'discarded',
        'flaggedFillUpIds',
        'props',
      },
      // And a Map of rates per currency, encoded the same way.
      'lib/core/fuel/fuel_money.dart': {'minorPerMetre'},
      // A List of (item, assessment) records. Encoded as `id:assessment`
      // strings, because a record containing a `ServiceItem` compares the
      // whole row — and two snapshots of the same reminders are the same
      // snapshot even if an unrelated column on one item changed.
      'lib/core/due/vehicle_due_snapshot.dart': {'assessments'},
      // A Map of counts per state, encoded over the fixed `DueState.values`
      // so the order cannot vary, plus the item — which is compared by ID
      // rather than by value, because two summaries naming the same item are
      // the same summary whatever else that item's row has changed.
      'lib/core/due/due_summary.dart': {'counts', 'worstItem'},
    };

    final offenders = <String>[];
    var checked = 0;

    for (final file in [
      ...dartFilesUnder('lib/core'),
      ...dartFilesUnder('lib/data'),
    ]) {
      for (final value in valueClassesIn(sourceWithoutLineComments(file))) {
        checked++;
        final missing = value.fields
            .difference(value.props)
            .difference(encodedNotListed[file.path] ?? const {});
        if (missing.isNotEmpty) {
          offenders.add('${file.path}: ${value.name} omits $missing');
        }
      }
    }

    expect(
      checked,
      greaterThanOrEqualTo(10),
      reason:
          'the parser found almost no value classes — it is broken, and a '
          'gate that checks nothing passes',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'a field missing from props makes two different records compare '
          'equal, and every watch stream de-duplicates on that equality — so '
          'a real edit never reaches the screen',
    );
  });

  test('the parser reads fields and props the way it claims to', () {
    // Guard the guard. This test greps, and a grep that matches nothing
    // reports a clean tree.
    const source = '''
class Good with ValueEquality {
  const Good(this.a, this.b);
  final int a;
  final String? b;
  static const c = 1;
  int get derived => a + 1;

  @override
  List<Object?> get props => [a, b];
}

class Bad with ValueEquality {
  const Bad(this.a, this.b);
  final int a;
  final String? b;

  @override
  List<Object?> get props => [a];
}

class NotAValue {
  final int a = 1;
}

enum Unit {
  km('km');

  const Unit(this.wire);
  final String wire;
}
''';

    final classes = valueClassesIn(source);
    expect(classes.map((c) => c.name), ['Good', 'Bad']);

    final good = classes.first;
    expect(good.fields, {'a', 'b'}, reason: 'static and getter are not fields');
    expect(good.props, {'a', 'b'});
    expect(good.fields.difference(good.props), isEmpty);

    final bad = classes.last;
    expect(bad.fields.difference(bad.props), {'b'});
  });

  test('a spread in props counts as covering its field', () {
    // `ServiceRecord` spreads `...lines` so a changed line makes the record
    // unequal. The parser has to see that as coverage, or it reports a false
    // positive on the one model that needs it most.
    const source = '''
class Record with ValueEquality {
  final List<int> lines;
  final int id;

  @override
  List<Object?> get props => [id, ...lines];
}
''';
    final record = valueClassesIn(source).single;
    expect(record.fields.difference(record.props), isEmpty);
  });
}
