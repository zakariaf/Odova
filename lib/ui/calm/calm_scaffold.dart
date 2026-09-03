// The chrome: CalmScaffold, CalmAppBar, CalmTabBar.
//
// Every screen in the app sits in this frame. A 56pt app bar, a scrolling body
// at the 22pt gutter with s5 between children, an optional non-scrolling foot,
// and a 62pt tab bar whose centre + overhangs it by 18.
//
// Bottom chrome comes from MediaQuery.paddingOf, never from `--homebar-h`:
// that token is specimen-sheet chrome and is 0 on most Android hardware.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// `.tabbar__fab` — 62 square, comfortably over the 52 floor.
const double kCalmTabFabSize = 62;

/// `margin-block-start: -18px` — the + breaks the bar's top edge on purpose.
const double kCalmTabFabLift = 18;

/// `.modal-head__action` paints 44; Calm's floor is still 52.
const double kCalmAppBarActionHeight = 44;

/// The only screen skeleton in Odova.
class CalmScaffold extends StatelessWidget {
  /// Creates a screen.
  const CalmScaffold({
    required this.appBar,
    required this.children,
    super.key,
    this.tabBar,
    this.footer,
  });

  /// The bar at the top. An ordinary widget in a Column, never
  /// `Scaffold.appBar`: `large` and `vehicle` are two lines tall.
  final CalmAppBar appBar;

  /// The scrolling body.
  ///
  /// Six languages and an unclamped text scaler mean nothing on a Calm screen
  /// may depend on fitting. SPEC.md §9's above-the-fold budget is verified by a
  /// 375x667 golden, not bought by making the body rigid.
  final List<Widget> children;

  /// The tab bar, when the screen is a tab root.
  final Widget? tabBar;

  /// `.screen__foot` — the full-width primary action that stays inside the
  /// thumb's reach however far the body scrolls.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      // The odometer strip is typed into, and SPEC.md §10 forbids a primary
      // action under the keyboard. Scaffold reads MediaQuery.viewInsetsOf.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: tabBar == null, // the tab bar draws its own bottom inset
        child: Column(
          children: [
            appBar,
            Expanded(
              child: ListView.separated(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.screenPad,
                  space.s5,
                  space.screenPad,
                  space.s6,
                ),
                itemCount: children.length,
                separatorBuilder: (_, _) => SizedBox(height: space.s5),
                itemBuilder: (_, i) => children[i],
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.screenPad,
                  space.s4,
                  space.screenPad,
                  space.s5,
                ),
                child: footer,
              ),
            ?tabBar,
          ],
        ),
      ),
    );
  }
}

/// Which of the four shapes an app bar is.
enum CalmAppBarShape {
  /// 56pt, `type.title`, actions on the end edge.
  standard,

  /// Two lines: `type.titleLg` with an optional caption subtitle.
  large,

  /// The vehicle name and its chevron as ONE 52pt target.
  vehicle,

  /// `1fr auto 1fr`: a start action, a centred title, an end action.
  modal,
}

/// The bar at the top of a screen.
class CalmAppBar extends StatelessWidget {
  /// The 56pt bar: a start-aligned title and optional end actions.
  const CalmAppBar({
    required this.title,
    super.key,
    this.showVehicleChevron = false,
    this.onTapVehicle,
    this.actions = const [],
  }) : shape = showVehicleChevron
           ? CalmAppBarShape.vehicle
           : CalmAppBarShape.standard,
       subtitle = null,
       startLabel = null,
       onStart = null,
       endLabel = null,
       onEnd = null;

  /// The two-line bar: `type.titleLg` over an optional caption.
  const CalmAppBar.large({
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
  }) : shape = CalmAppBarShape.large,
       showVehicleChevron = false,
       onTapVehicle = null,
       startLabel = null,
       onStart = null,
       endLabel = null,
       onEnd = null;

  /// The vehicle bar. The chevron exists only because this constructor was
  /// chosen — SPEC.md §9: with one vehicle the name is plain text.
  const CalmAppBar.vehicle({
    required this.title,
    required VoidCallback this.onTapVehicle,
    super.key,
    this.actions = const [],
  }) : shape = CalmAppBarShape.vehicle,
       showVehicleChevron = true,
       subtitle = null,
       startLabel = null,
       onStart = null,
       endLabel = null,
       onEnd = null;

  /// The modal head: Cancel, title, Save (SPEC.md §10).
  ///
  /// [onEnd] may be null — that is the disabled Save — but SPEC.md §10 says
  /// Save on the five `log.*` forms is never disabled; it validates, scrolls to
  /// the first failing field and focuses it.
  const CalmAppBar.modal({
    required this.title,
    required String this.startLabel,
    required VoidCallback this.onStart,
    required String this.endLabel,
    required this.onEnd,
    super.key,
  }) : shape = CalmAppBarShape.modal,
       showVehicleChevron = false,
       onTapVehicle = null,
       subtitle = null,
       actions = const [];

  /// The screen's name, already localised.
  final String title;

  /// Which shape this is.
  final CalmAppBarShape shape;

  /// The caption under a [CalmAppBarShape.large] title.
  final String? subtitle;

  /// True only on the vehicle shape.
  final bool showVehicleChevron;

  /// What tapping the vehicle title does.
  final VoidCallback? onTapVehicle;

  /// End-edge actions.
  final List<Widget> actions;

  /// The modal head's start action ("Cancel").
  final String? startLabel;

  /// What Cancel does.
  final VoidCallback? onStart;

  /// The modal head's end action ("Save").
  final String? endLabel;

  /// What Save does. Null draws it disabled.
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // fade, not ellipsis: a truncated vehicle name is still readable, and an
    // ellipsis in an RTL string lands on the wrong end of it.
    Widget label(TextStyle style) => Text(
      title,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: style.copyWith(color: colors.ink),
    );

    final child = switch (shape) {
      CalmAppBarShape.large => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          space.screenPad,
          space.s2,
          space.screenPad,
          space.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: label(type.titleLg)),
                ...actions,
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: space.s1),
              Text(
                subtitle!,
                style: type.caption.copyWith(color: colors.ink3),
              ),
            ],
          ],
        ),
      ),
      CalmAppBarShape.modal => Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: space.s4,
          vertical: space.s2,
        ),
        // `grid-template-columns: 1fr auto 1fr`. The title is Flexible and
        // loose, so it takes its intrinsic width and the two action columns
        // split what is left equally — and `center` is what puts the leftover
        // back symmetrically. With the default `start` the whole row slides by
        // half the leftover and the title is 5pt off centre, which reads as a
        // misalignment rather than as a bug.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CalmAppBarAction(
                  label: startLabel!,
                  onTap: onStart,
                ),
              ),
            ),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.center,
                style: type.headline.copyWith(
                  color: colors.ink,
                  fontWeight: type.semi,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CalmAppBarAction(
                  label: endLabel!,
                  onTap: onEnd,
                  primary: true,
                ),
              ),
            ),
          ],
        ),
      ),
      CalmAppBarShape.vehicle || CalmAppBarShape.standard => Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
        child: Row(
          children: [
            Expanded(
              child: showVehicleChevron
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CalmVehicleTitle(
                        onTap: onTapVehicle,
                        child: label(type.title),
                      ),
                    )
                  : label(type.title),
            ),
            ...actions,
          ],
        ),
      ),
    };

    // The bar is part of the page, not a card floating over it: no shadow, no
    // hairline, the same `bg` as the body behind it. No `alignment` either —
    // a Container with one expands to fill whatever it is given, and in a
    // Center that is the whole screen.
    return Container(
      constraints: BoxConstraints(minHeight: space.appbarH),
      child: child,
    );
  }
}

/// The vehicle name and its chevron, as one pill-shaped target.
class CalmVehicleTitle extends StatelessWidget {
  /// Creates the target.
  const CalmVehicleTitle({required this.child, super.key, this.onTap});

  /// The name.
  final Widget child;

  /// What tapping it does.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: shapes.radiusPill,
      pressScale: 1, // a title does not squeeze
      child: Builder(
        builder: (context) => DecoratedBox(
          decoration: ShapeDecoration(
            color: CalmPressState.of(context)
                ? colors.surface2
                : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: ConstrainedBox(
            // 52, not the 44 the visible pill would give us.
            constraints: BoxConstraints(minHeight: space.touchMin),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: space.s3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: child),
                  SizedBox(width: space.s2),
                  Icon(Icons.expand_more, color: colors.ink3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text action in an app bar: the modal head's Cancel and Save.
class CalmAppBarAction extends StatelessWidget {
  /// Creates the action.
  const CalmAppBarAction({
    required this.label,
    required this.onTap,
    super.key,
    this.primary = false,
  });

  /// The word, already localised.
  final String label;

  /// Null draws it disabled.
  final VoidCallback? onTap;

  /// The end action (Save) is brand and semibold.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return CalmPressable(
      onTap: onTap,
      enabled: onTap != null,
      borderRadius: kCalmAppBarActionHeight / 2,
      // `.modal-head__action` paints 44 — Material's floor, not Calm's. The
      // paint stays 44 and the target grows to 52.
      expandTapTarget: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kCalmAppBarActionHeight,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: space.s2),
          child: Align(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              style: type.bodyLg.copyWith(
                color: onTap == null
                    ? colors.ink4
                    : (primary ? colors.brand : colors.ink2),
                fontWeight: primary ? type.semi : type.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 62pt bar: five equal slots, the middle one holding the +.
class CalmTabBar extends StatelessWidget {
  /// Creates the tab bar.
  const CalmTabBar({
    required this.index,
    required this.onChanged,
    required this.onAdd,
    required this.addLabel,
    required this.labels,
    super.key,
  });

  /// The selected tab, 0..3.
  final int index;

  /// Reports the tapped tab.
  final ValueChanged<int> onChanged;

  /// What the + does.
  final VoidCallback onAdd;

  /// The + carries no visible text, so it needs a spoken one.
  final String addLabel;

  /// Home, History, Costs, Settings — already localised.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    assert(
      labels.length == 4,
      'CalmTabBar has four labelled slots plus the +.',
    );
    final space = CalmSpace.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // The widget is 18pt TALLER than the bar it paints, and that is not a
    // decoration. CSS lets `margin-block-start: -18px` overflow a box and stay
    // clickable; Flutter's RenderBox.hitTest rejects a position outside its own
    // size before it ever reaches the child, so a + drawn overhanging a 62pt
    // bar would have 44pt of hit area — under the 52 floor, on the app's most
    // pressed control. The extra band is transparent and sits on `bg`, which
    // is the colour of the page behind it, so it is invisible.
    return SizedBox(
      height: space.tabbarH + bottomInset + kCalmTabFabLift,
      child: Stack(
        children: [
          const PositionedDirectional(
            top: kCalmTabFabLift,
            start: 0,
            end: 0,
            bottom: 0,
            child: CalmTabBarSurface(),
          ),
          PositionedDirectional(
            top: kCalmTabFabLift,
            start: 0,
            end: 0,
            bottom: bottomInset,
            // `grid-template-columns: repeat(5, 1fr)`. The middle slot is
            // empty: the + lives in its own band above, so its whole 62 is
            // hittable.
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: CalmTabSlot(
                      child: i == 2
                          ? const SizedBox.shrink()
                          : _CalmTabItem(
                              label: labels[i < 2 ? i : i - 1],
                              active: (i < 2 ? i : i - 1) == index,
                              onTap: () => onChanged(i < 2 ? i : i - 1),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: kCalmTabFabSize,
            // Centred in the bar, not in a slot: dead centre in both
            // directions with no second code path.
            child: Center(
              child: CalmTabFab(onTap: onAdd, semanticLabel: addLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// The painted 62pt bar: `bg` plus the top divider hairline.
class CalmTabBarSurface extends StatelessWidget {
  /// Creates the surface.
  const CalmTabBarSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        // `.tabbar { box-shadow: 0 -1px 0 var(--color-divider) }` — a hairline
        // ABOVE, drawn as a shadow rather than a Border, because only
        // calm_field.dart and calm_pressable.dart may construct one.
        boxShadow: [
          BoxShadow(color: colors.divider, offset: const Offset(0, -1)),
        ],
      ),
    );
  }
}

/// One of the tab bar's five equal slots.
class CalmTabSlot extends StatelessWidget {
  /// Creates a slot.
  const CalmTabSlot({required this.child, super.key});

  /// What it holds.
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

/// The central +.
class CalmTabFab extends StatelessWidget {
  /// Creates the +.
  const CalmTabFab({
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  /// What it does.
  final VoidCallback onTap;

  /// It carries no visible text, so it needs a spoken one.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: shapes.radiusPill,
      pressScale: kCalmPressScaleFab,
      semanticLabel: semanticLabel,
      child: SizedBox.square(
        dimension: kCalmTabFabSize,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.brand,
            shape: const CircleBorder(),
            shadows: shapes.elev2,
          ),
          child: Icon(Icons.add, size: 28, color: colors.onBrand),
        ),
      ),
    );
  }
}

class _CalmTabItem extends StatelessWidget {
  const _CalmTabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Semantics(
      selected: active,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: 0,
        pressScale: 1,
        child: SizedBox(
          height: space.touchMin, // 52 inside a 62 bar
          child: Center(
            // `.tabbar__item` declares no transition, so neither does this.
            child: Text(
              label,
              maxLines: 1,
              // Weight AND colour, never colour alone.
              style: type.caption.copyWith(
                color: active ? colors.brand : colors.ink2,
                fontWeight: active ? type.semi : type.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.snackbar` sits above the tab bar and the home indicator.
///
/// The CSS composes `--homebar-h`; on device that number is MediaQuery's.
double calmSnackbarBottomInset(BuildContext context) {
  final space = CalmSpace.of(context);
  return space.tabbarH + MediaQuery.paddingOf(context).bottom + space.s3;
}
