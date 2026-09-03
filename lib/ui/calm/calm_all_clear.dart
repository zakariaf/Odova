// CalmAllClear — "nothing is due", rendered as the GOOD state — and
// CalmEmptyState for the different condition of a list not filled in yet.
//
// All-clear carries exactly four things: the mark, the good news, what is next
// with its date, and the date it was last confirmed. No shrug art, no "yet", no
// filled call to action, and no animation: this is a state you land on, not an
// event that happens, and it fires on most Home opens (SPEC.md §9).
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// `.allclear__mark` — 92 square.
const double kCalmAllClearMarkSize = 92;

/// `box-shadow: 0 0 0 12px var(--color-ok-tint)` — a halo, not a blur.
const double kCalmAllClearHalo = 12;

/// `.empty__art` — 104 square.
const double kCalmEmptyStateArtSize = 104;

/// `.empty__text` caps at 28ch. A max width, never a FittedBox and never an
/// ellipsis.
const double kCalmEmptyStateBodyWidth = 300;

/// The since-last-service receipt.
///
/// Omitted entirely when there is no record to measure from: SPEC.md §1
/// forbids a plausible-looking blank.
@immutable
class CalmSinceLine {
  /// Creates the receipt.
  const CalmSinceLine({required this.label, required this.figure});

  /// "Since the last oil change".
  final String label;

  /// "3,120 km · 4 months" — localised and numeral-formatted upstream.
  final String figure;
}

/// The answer "nothing needs doing".
class CalmAllClear extends StatelessWidget {
  /// Creates the all-clear.
  const CalmAllClear({
    required this.headline,
    required this.nextLine,
    super.key,
    this.fuzzLine,
    this.since,
  });

  /// "Nothing due". Present tense, no exclamation mark, no confetti.
  final String headline;

  /// "Next: Inspection (TÜV), 14 March" — the exact date, off the time axis.
  final String nextLine;

  /// "in about 6 weeks" — the estimate, kept on its own line so it can never
  /// read as a fact (SPEC.md §1). Null when nothing is scheduled.
  final String? fuzzLine;

  /// The receipt. Without it the card is an assertion; with it, evidence.
  final CalmSinceLine? since;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // Through CalmSurface, which is what restores the sheen: `.allclear`
    // declares `--elev-2, --elev-sheen` and the hand-rolled BoxDecoration this
    // replaced carried only the first, because CalmSurface had no `gradient`
    // and the card went around it. A missing parameter, not a decision.
    return CalmSurface(
      color: colors.surface,
      radius: shapes.radius3xl,
      shadow: shapes.elev2, // warm-tinted and layered, never a border
      // The sage wash is what makes this NOT an empty state.
      gradient: RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [colors.ok.tint, colors.surface],
        stops: const [0, 0.72],
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        space.s6,
        space.s8,
        space.s6,
        space.s7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: space.s4,
        children: [
          const Center(child: CalmAllClearMark()),
          Semantics(
            header: true,
            child: Text(
              headline,
              textAlign: TextAlign.center,
              style: type.titleLg.copyWith(color: colors.ink),
            ),
          ),
          // What is next, and the fuzz — two lines that never merge into one
          // confident sentence.
          Text(
            nextLine,
            textAlign: TextAlign.center,
            style: type.bodyLg.copyWith(color: colors.ink2),
          ),
          if (fuzzLine != null)
            Text(
              fuzzLine!,
              textAlign: TextAlign.center,
              style: type.caption.copyWith(color: colors.ink2),
            ),
          if (since != null) CalmAllClearSince(since: since!),
        ],
      ),
    );
  }
}

/// The 92pt tick with its 12pt halo.
///
/// Decorative — the heading below carries the meaning, so a screen reader
/// hears the sentence rather than "image, image".
class CalmAllClearMark extends StatelessWidget {
  /// Creates the mark.
  const CalmAllClearMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);

    return ExcludeSemantics(
      child: Container(
        width: kCalmAllClearMarkSize,
        height: kCalmAllClearMarkSize,
        decoration: BoxDecoration(
          color: colors.ok.tint,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: colors.ok.tint, spreadRadius: kCalmAllClearHalo),
          ],
        ),
        child: Icon(
          Icons.check,
          size: CalmSpace.of(context).iconXl,
          color: colors.ok.ink,
        ),
      ),
    );
  }
}

/// The receipt block.
class CalmAllClearSince extends StatelessWidget {
  /// Creates the block.
  const CalmAllClearSince({required this.since, super.key});

  /// What to show.
  final CalmSinceLine since;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: space.s5,
        vertical: space.s4,
      ),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(shapes.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            since.label,
            textAlign: TextAlign.center,
            style: type.caption.copyWith(color: colors.ink2),
          ),
          Text(
            since.figure,
            textAlign: TextAlign.center,
            style: type.headline.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

/// The other condition: a list the user has not filled yet.
///
/// Neutral art, and the only one of the two allowed a filled primary action.
class CalmEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const CalmEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
    this.action,
  });

  /// The neutral glyph.
  final IconData icon;

  /// What is missing.
  final String title;

  /// States the mechanism, not the feature — a Calm empty state is allowed to
  /// talk someone out of using one.
  final String body;

  /// A real primary button. [CalmAllClear] never gets one.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: space.s6,
        vertical: space.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s4,
        children: [
          ExcludeSemantics(
            child: Container(
              width: kCalmEmptyStateArtSize,
              height: kCalmEmptyStateArtSize,
              decoration: BoxDecoration(
                color: colors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: space.iconXl, color: colors.ink2),
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: type.title.copyWith(color: colors.ink),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kCalmEmptyStateBodyWidth,
            ),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: type.bodyLg.copyWith(color: colors.ink2),
            ),
          ),
          if (action != null)
            Padding(
              padding: EdgeInsetsDirectional.only(top: space.s2),
              child: action,
            ),
        ],
      ),
    );
  }
}
