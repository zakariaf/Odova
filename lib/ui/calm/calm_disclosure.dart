// A collapsed group that reveals its contents.
//
// SPEC.md §8 draws two on `vehicle.edit` — `▸ Purchase and sale` and
// `▸ This vehicle's units & currency`. They are what keep a form with twenty
// fields from being a wall: the six a user touches are on screen, the fourteen
// they touch once a year are one tap away.
//
// **Composed, not invented.** `design/calm/odova.css` has no `.disclosure`, so
// there is no drawn appearance to match. This is a `CalmListRow` with the
// existing disclosure chevron and the group's own surface — every part of it is
// already in the design system, which is the honest way to build a component
// the design did not draw.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_row_group.dart';

/// A titled group that starts closed.
class CalmDisclosure extends StatefulWidget {
  /// Creates a disclosure.
  const CalmDisclosure({
    required this.title,
    required this.children,
    super.key,
    this.initiallyOpen = false,
  });

  /// The header, already localised.
  final String title;

  /// What it hides.
  final List<Widget> children;

  /// Whether it starts open. SPEC.md §8 wants both of `vehicle.edit`'s closed.
  final bool initiallyOpen;

  @override
  State<CalmDisclosure> createState() => _CalmDisclosureState();
}

class _CalmDisclosureState extends State<CalmDisclosure> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final motion = CalmMotion.of(context);
    final space = CalmSpace.of(context);

    return AnimatedSize(
      duration: calmDuration(context, motion.base),
      curve: motion.easeStandard,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: space.s3,
        children: [
          // MERGED with the row's own node rather than wrapped around it.
          // `CalmListRow` already carries a `MergeSemantics`, so a bare
          // `Semantics(expanded:)` above it becomes a SECOND node that a
          // screen reader reads separately — the flag has to land on the same
          // node as the title or it describes nothing.
          MergeSemantics(
            child: Semantics(
              expanded: _open,
              child: CalmRowGroup(
                rows: [
                  CalmListRow(
                    title: widget.title,
                    onTap: () => setState(() => _open = !_open),
                    // CLOSED, the disclosure chevron points at the end edge
                    // and mirrors under RTL — it is one of the six glyphs that
                    // does. OPEN, it points down, a direction with no
                    // handedness, so it is a plain Icon and must not flip.
                    showChevron: !_open,
                    end: _open ? const Icon(Icons.expand_more, size: 20) : null,
                  ),
                ],
              ),
            ),
          ),

          // BUILT ONLY WHEN OPEN, never merely hidden. A subtree kept alive
          // behind an `Offstage` still runs its controllers, still takes focus
          // in a traversal and still reports its fields to a screen reader —
          // which would make this a form with fourteen invisible tab stops.
          if (_open) ...widget.children,
        ],
      ),
    );
  }
}
