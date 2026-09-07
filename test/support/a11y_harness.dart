// The accessibility lane: a way to fail a build for an accessibility defect.
//
// SPEC.md §17 treats accessibility as a release blocker rather than polish, and
// this file is what makes that claim checkable. It layers on `pumpApp`, which
// already pins `physicalSize`, `devicePixelRatio` and the three MediaQuery
// flags — what is added here is the MATRIX and the two assertions.
//
// **Nothing here swallows.** There is no `takeException` helper, no
// `ignoreOverflowErrors`, no `withClampedTextScaling`. Every one of those is a
// one-line way to turn a red overflow green, and a harness that offers one is a
// harness that converts a release blocker into a passing suite —
// `test/policy/a11y_bans_test.dart` fails the build if any of them appears.
//
// `expectNoOverflow` READS the pending exception and re-reports it as a
// failure; it deliberately does not clear anything it did not cause.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// `Override` lives in misc.dart in Riverpod 3.x, not the root library — the
// same note `pump_app.dart` carries, for the same reason.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

import 'pump_app.dart';

/// One cell of §17's per-locale gate.
@immutable
class A11yCase {
  /// Creates a case.
  const A11yCase({
    this.locale = const Locale('en'),
    this.textScale = 1.0,
    this.boldText = false,
  });

  /// Which of the six.
  final Locale locale;

  /// 1.0 or 2.0. §17's gate is about 200%.
  final double textScale;

  /// The OS "bold text" setting, which changes metrics independently of scale.
  final bool boldText;

  /// A name a person reads in CI output.
  ///
  /// The matrix is ENUMERATED and named rather than counted, because a dropped
  /// locale hides perfectly well inside an integer and not at all inside a test
  /// name.
  String get name =>
      '${locale.languageCode} at ${(textScale * 100).round()}%'
      '${boldText ? ' bold' : ''}';

  @override
  String toString() => name;
}

/// Six locales x 100%/200% x bold on/off. Twenty-four.
///
/// Built from `odovaSupportedLocales` rather than a literal list, so a locale
/// added to the app cannot be missed here — the matrix grows with the app or
/// the count assertion in the self-test goes red.
/// Unmodifiable, so one test's `sort` cannot change another's matrix under
/// randomized ordering.
final List<A11yCase> a11yMatrix = List.unmodifiable([
  for (final locale in odovaSupportedLocales)
    for (final scale in const [1.0, 2.0])
      for (final bold in const [false, true])
        A11yCase(locale: locale, textScale: scale, boldText: bold),
]);

/// Pumps [child] under one case.
///
/// `accessibleNavigation` follows `boldText` deliberately: both are on when a
/// user has turned the OS accessibility settings up, and testing a 200%
/// bold-text screen with screen-reader navigation off tests a combination
/// nobody has.
Future<void> pumpA11y(
  WidgetTester tester,
  A11yCase testCase,
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
  bool settle = true,
}) => pumpApp(
  tester,
  child,
  locale: testCase.locale,
  themeMode: themeMode,
  overrides: overrides,
  textScaler: TextScaler.linear(testCase.textScale),
  boldText: testCase.boldText,
  accessibleNavigation: testCase.boldText,
  settle: settle,
);

/// Performs the custom semantics action [id] on [node], as a reader would.
///
/// A `customSemanticsActions` entry is the only way a screen-reader user
/// reaches an action on a node that merged its children — `OdometerStrip` is
/// one — and `tester.tap` cannot reach it, because there is no separate
/// gesture detector left to hit. This goes through the semantics owner, which
/// is the path TalkBack and VoiceOver take.
///
/// Here rather than in the test, so the one deprecated owner lookup stays in
/// [walkSemantics]'s company and no screen test grows its own ignore.
void performCustomAction(WidgetTester tester, SemanticsNode node, int id) =>
    // The deprecated owner is the one that holds the tree in a widget test;
    // `rootPipelineOwner.semanticsOwner` is null there. Same reason as
    // [walkSemantics].
    //
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.customAction,
      id,
    );

/// Fails when the last pump produced a layout overflow.
///
/// Flutter reports an overflow through `FlutterError.onError`, which the test
/// binding collects — so it is a yellow-and-black banner in a screenshot and
/// NOTHING in a passing test unless something asks. This asks.
///
/// A non-overflow exception is re-thrown rather than reported as an overflow:
/// swallowing an unrelated error while looking for this one is how a harness
/// starts lying.
void expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  if (error == null) return;

  final text = error.toString();
  if (text.contains('overflowed by')) {
    fail(
      'A RenderFlex overflowed. At 200% text scale this is a real user seeing '
      'a clipped label, not a test artefact.\n\n$text',
    );
  }

  // Not ours. Put it back where the test framework can see it.
  //
  // A plain throw. This was `Error.throwWithStackTrace(error as Object,
  // StackTrace.current)`, which preserves nothing a plain throw does not:
  // `takeException()` returns the exception WITHOUT its original stack, so
  // there is none to preserve, and `StackTrace.current` is the stack a throw
  // attaches anyway.
  // Whatever the framework handed us goes back unchanged. Wrapping it in an
  // Error to satisfy the lint would replace the type a caller is matching on.
  //
  // ignore: only_throw_errors
  throw error as Object;
}

/// Every non-empty semantics label on screen, in tree order.
///
/// THE one semantics walker. There were five — four copied between test files
/// and a fifth inside `expectEverythingLabelled` — each carrying its own
/// `// ignore: deprecated_member_use` on `pipelineOwner`, and each with a
/// comment pointing at a single owner that did not exist. `pipelineOwner` is
/// deprecated with no whole-tree replacement, so the day it goes the fix should
/// be one edit rather than five.
List<String> spokenLabels(WidgetTester tester) {
  final out = <String>[];
  walkSemantics(tester, (node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) out.add(label);
  });
  return out;
}

/// Every label a keyboard, switch or reader can land on, in TRAVERSAL order.
///
/// Traversal order is not construction order: construction order is what a
/// developer wrote, and direction changes what the platform reads.
List<String> focusableLabels(WidgetTester tester) {
  final out = <String>[];
  walkSemantics(tester, inTraversalOrder: true, (node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty &&
        (data.hasAction(SemanticsAction.tap) ||
            data.flagsCollection.isButton ||
            data.flagsCollection.isTextField)) {
      out.add(data.label);
    }
  });
  return out;
}

/// Walks the semantics tree, ensuring and disposing the handle around it.
///
/// Without a live handle the tree is not built at all, so a walk finds nothing
/// and reports "this announces nothing" for something that announces perfectly
/// well. That false negative would report every screen in the app as broken,
/// which is the fastest way to get an accessibility gate deleted.
///
/// `pipelineOwner`, not `rootPipelineOwner`: the newer one's `semanticsOwner`
/// is null in a widget test even with a handle. Deprecated in favour of
/// `SemanticsBinding`, which has no equivalent whole-tree read — revisit when
/// it does.
void walkSemantics(
  WidgetTester tester,
  void Function(SemanticsNode node) visit, {
  bool inTraversalOrder = false,
}) {
  void walk(SemanticsNode node) {
    visit(node);
    if (inTraversalOrder) {
      node
          .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
          .forEach(walk);
    } else {
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }
  }

  final handle = tester.ensureSemantics();
  // The deprecated owner is the one that holds the tree — see this function's
  // doc comment. THE only such ignore in the harness now; there were five.
  //
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) walk(root);
  handle.dispose();
}

/// Fails when a tap target is smaller than the platform floor.
///
/// SPEC.md §17's gate and `accessibility-as-code`: 48 logical pixels on
/// Android, 44 on iOS. It is about MOTOR accuracy rather than eyesight — a
/// target easy for a steady hand at a desk is one somebody misses standing at
/// a pump in the rain, which is the user §1's four facts describe.
///
/// **Delegates to Flutter's own guidelines rather than measuring nodes here.**
/// A hand-rolled version was written first and reported the first-run language
/// screen as having a 756x9 target — the row's TITLE node, on a row whose
/// `minHeight` is 56. The framework's matcher knows which node is the tappable
/// one and a naive walk of every labelled node does not; a gate that calls a
/// correct 56pt row a 9pt one gets deleted in a fortnight, rightly.
///
/// **Its blind spot, stated because a gate that hides one is worse than no
/// gate.** The guideline measures the semantics RECT of nodes carrying
/// `SemanticsAction.tap`, so an undersized target under a
/// `Semantics(excludeSemantics: true)` wrapper is invisible to it when the
/// wrapper does not itself declare `onTap`: the small node is deleted and no
/// node with a tap action is left to measure. A 12x12 control wrapped that way
/// passes. Both widgets in this epic with that shape — `ChartAlternative` and
/// `OdometerStrip` — DO pass `onTap`, so their own rects are measured and
/// nothing is hidden today; the gate still cannot see the class of defect it
/// exists for. A real fix needs a hit-test-region walk, which is EPIC-18's.
///
/// Both platforms are checked, because the app ships to both and the floors
/// differ.
Future<void> expectTapTargets(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
}

/// Fails when something on screen cannot be announced.
///
/// TWO passes, because neither alone is enough.
///
/// The SEMANTICS TREE pass catches a button or a tappable row with no label —
/// that is what TalkBack and VoiceOver actually read, and a widget carrying a
/// label its ancestor excludes is invisible to them while being perfectly
/// visible to a widget-tree scan.
///
/// The WIDGET TREE pass catches a bare `Icon`, and it has to exist because an
/// `Icon` with no `semanticLabel` contributes NO NODE AT ALL. There is nothing
/// in the semantics tree to find: the icon is announced as silence, which is
/// exactly the defect, and only the widget tree knows it is there.
///
/// `ExcludeSemantics` is the honest way to have an unlabelled icon — a claim a
/// reviewer can check, where a missing label is an omission nobody can tell
/// from an oversight. `Semantics(excludeSemantics: true)` counts too, and has
/// to: it is a FLAG on `RenderSemanticsAnnotations`, not an `ExcludeSemantics`
/// widget, so an ancestor-by-type search does not see it. Looking only for the
/// widget made this gate fail on `OdometerStrip`, whose chevron contributes no
/// node at all — and the two cheapest ways to clear a false red are both
/// wrong: label a decorative chevron so a reader says "chevron right" on every
/// row, or delete the icon pass.
void expectEverythingLabelled(WidgetTester tester) {
  final unlabelled = <String>[];

  void walk(SemanticsNode node, String path) {
    final data = node.getSemanticsData();
    final announceable =
        data.hasAction(SemanticsAction.tap) ||
        data.flagsCollection.isButton ||
        data.flagsCollection.isImage;

    if (announceable &&
        data.label.isEmpty &&
        data.tooltip.isEmpty &&
        data.value.isEmpty) {
      unlabelled.add('$path (announced as nothing)');
    }
  }

  walkSemantics(tester, (node) => walk(node, 'root'));

  final handle = tester.ensureSemantics();
  for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
    if (icon.semanticLabel != null) continue;
    final byWidget = find.ancestor(
      of: find.byWidget(icon),
      matching: find.byType(ExcludeSemantics),
    );
    if (byWidget.evaluate().isNotEmpty) continue;
    final byFlag = find.ancestor(
      of: find.byWidget(icon),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.excludeSemantics,
      ),
    );
    if (byFlag.evaluate().isNotEmpty) continue;
    unlabelled.add('Icon(${icon.icon?.codePoint}) with no semanticLabel');
  }
  handle.dispose();

  if (unlabelled.isNotEmpty) {
    fail(
      'A screen reader announces ${unlabelled.length} thing(s) as nothing:\n'
      '${unlabelled.map((p) => '  - $p').join('\n')}\n\n'
      'Give it a label, or wrap it in ExcludeSemantics and say it carries no '
      'meaning. A missing label is not distinguishable from an oversight.',
    );
  }
}
