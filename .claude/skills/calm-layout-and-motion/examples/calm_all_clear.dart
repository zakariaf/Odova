// CalmAllClear — "nothing is due" rendered as the GOOD state — and
// CalmEmptyState for the different condition of a list not filled in yet.
//
// All-clear carries exactly four things: the mark, the good news, what is next
// with its date, and the date it was last confirmed. It carries no shrug art, no
// "yet", no filled CTA, and no animation: this is a state you land on, not an
// event that happens, and it fires on most Home opens (SPEC §9).
import 'package:flutter/material.dart';

import 'calm_tokens_min.dart';

/// `.icon--xl` — the only icon size Calm uses above 32.
const double _iconXl = 44;

/// The since-last-service receipt. Omitted entirely when there is no
/// ServiceRecord to measure from: SPEC §1 forbids a plausible-looking blank.
@immutable
class CalmSinceLine {
  const CalmSinceLine({required this.label, required this.figure});

  /// "Since the last oil change"
  final String label;

  /// "3,120 km · 4 months" — localised and numeral-formatted upstream.
  final String figure;
}

class CalmAllClear extends StatelessWidget {
  const CalmAllClear({
    super.key,
    required this.headline,
    required this.nextLine,
    this.fuzzLine,
    this.since,
  });

  /// "Nothing due". Present tense, no exclamation mark, no confetti.
  final String headline;

  /// "Next: Inspection (TÜV), 14 March" — the exact date, off the time axis.
  final String nextLine;

  /// "in about 6 weeks" — the estimate, kept on its own line so it can never
  /// read as a fact (SPEC §1). Null when nothing is scheduled.
  final String? fuzzLine;

  final CalmSinceLine? since;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);
    final shapes = CalmShapes.of(context);

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(space.s6, space.s8, space.s6, space.s7),
      decoration: BoxDecoration(
        borderRadius: shapes.radius3xl,
        // The sage wash is what makes this NOT an empty state.
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.2,
          colors: [colors.ok.tint, colors.surface],
          stops: const [0, 0.72],
        ),
        boxShadow: shapes.elev2, // warm-tinted and layered, never a border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: space.s4,
        children: [
          // 1. The mark. Decorative — the heading below carries the meaning, so
          //    a screen reader hears the sentence, not "image, image".
          ExcludeSemantics(
            child: Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(color: colors.ok.tint, shape: BoxShape.circle),
                child: Icon(Icons.check, size: _iconXl, color: colors.ok.ink),
              ),
            ),
          ),
          // 2. The good news.
          Semantics(
            header: true,
            child: Text(headline,
                textAlign: TextAlign.center,
                style: type.titleLg.copyWith(color: colors.ink)),
          ),
          // 3. What is next, and the fuzz — two lines that never merge into one
          //    confident sentence.
          Text(nextLine,
              textAlign: TextAlign.center,
              style: type.bodyLg.copyWith(color: colors.ink2)),
          if (fuzzLine != null)
            Text(fuzzLine!,
                textAlign: TextAlign.center,
                style: type.caption.copyWith(color: colors.ink2)),
          // 4. The receipt. Without it the card is an assertion; with it, evidence.
          if (since != null)
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                  horizontal: space.s5, vertical: space.s4),
              decoration: BoxDecoration(
                  color: colors.surface2, borderRadius: shapes.radiusXl),
              child: Column(
                children: [
                  Text(since!.label,
                      textAlign: TextAlign.center,
                      style: type.caption.copyWith(color: colors.ink2)),
                  Text(since!.figure,
                      textAlign: TextAlign.center,
                      style: type.headline.copyWith(color: colors.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The other condition: a list the user has not filled yet. Neutral art, and the
/// only one of the two allowed a filled primary action.
class CalmEmptyState extends StatelessWidget {
  const CalmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;

  /// States the mechanism, not the feature — a Calm empty state is allowed to
  /// talk someone out of using one.
  final String body;

  /// A real primary button. CalmAllClear never gets one.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: space.s6, vertical: space.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: space.s4,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: colors.surface2, shape: BoxShape.circle),
              child: Icon(icon, size: _iconXl, color: colors.ink2),
            ),
          ),
          Semantics(
            header: true,
            child: Text(title,
                textAlign: TextAlign.center,
                style: type.title.copyWith(color: colors.ink)),
          ),
          ConstrainedBox(
            // `.empty__text` caps at 28ch. A fixed max width, never a FittedBox
            // or an ellipsis — see `accessibility-as-code`.
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(body,
                textAlign: TextAlign.center,
                style: type.bodyLg.copyWith(color: colors.ink2)),
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
