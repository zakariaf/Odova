// What a screen reader says when the app is guessing.
//
// SPEC.md §17's accessibility gate and §1.4's uncertainty rules meet here. The
// visible string carries a `~`, and a screen reader must never read that as
// "tilde" — it must read the MEANING, because the whole point of the prefix is
// to say "the app does not know this exactly" and a user who cannot see it is
// entitled to the same warning.
//
// **One helper, and the sentence comes from ARB.** `commonEstimatedA11y` is
// "estimated, about {value}", already translated into all six locales — and it
// had NO production caller until this file. Concatenating "estimated" onto a
// figure per screen would put an English word order into five languages that do
// not share it, and would need finding again on every new screen.
//
// It is deliberately NOT part of `formatDistanceFigure`: that function returns
// the VISIBLE string, and a semantic label is a different thing that happens to
// be built from it. Returning both from one function is how a caller ends up
// rendering "estimated, about 187,400 km" on screen.
import 'package:flutter/widgets.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// Wraps [child] so a screen reader announces [value] as an estimate.
///
/// [value] is the figure WITHOUT its `~` — the marker is visual, and the label
/// says in words what the marker says in glyphs. Pass the already-formatted and
/// already-numeral-shaped body, so the announcement uses the same digits the
/// screen shows.
///
/// `excludeSemantics` on the child, because the child renders the `~` form and
/// a screen reader that reached it would announce the figure twice — once as
/// the tilde string and once as this sentence.
class EstimatedValueSemantics extends StatelessWidget {
  /// Wraps [child].
  const EstimatedValueSemantics({
    required this.value,
    required this.child,
    super.key,
  });

  /// The figure, formatted and numeral-shaped, with no `~`.
  final String value;

  /// The visible widget, which carries the `~`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.commonEstimatedA11y(value),
      excludeSemantics: true,
      child: child,
    );
  }
}

/// The sentence itself, for a caller that already owns a `Semantics`.
///
/// A screen with one merged announcement — a due card reads as a single node —
/// cannot nest another `Semantics` inside it without splitting the node in two.
/// It builds its whole sentence and needs this piece as a string.
String estimatedValueLabel(AppLocalizations l10n, String value) =>
    l10n.commonEstimatedA11y(value);
