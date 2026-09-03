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
    bool showVehicleChevron = false,
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
  ///
  /// Derived, not stored: the flag and [shape] said the same thing in every
  /// reachable state and were kept in sync by hand across four constructors.
  /// It stays in the public API because the inventory's signature declares it.
  bool get showVehicleChevron => shape == CalmAppBarShape.vehicle;

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
      CalmAppBarShape.vehicle => Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CalmVehicleTitle(
                  onTap: onTapVehicle,
                  child: label(type.title),
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
      CalmAppBarShape.standard => Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
        child: Row(
          children: [
            Expanded(child: label(type.title)),
            ...actions,
          ],
        ),
      ),
    };

    // The bar is part of the page, not a card floating over it: no shadow, no
    // hairline, the same `bg` as the body behind it — so a ConstrainedBox, not
    // a Container with a null decoration. (The test that asserted on that null
    // decoration passed unconditionally, which is why it now asserts there is
    // no DecoratedBox at all.)
    return ConstrainedBox(
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
              textAlign: TextAlign.center,
              // No maxLines: "Abbrechen" at 200% is wider than a third of a
              // 320pt modal head.
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
    this.icons,
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

  /// One 24pt glyph per label, drawn above it.
  ///
  /// Optional so the declared signature still compiles, but `.tabbar__icon` is
  /// 24px in odova.css and the reference screenshots show four of them: a bar
  /// built without these will not pass its parity check.
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    assert(
      labels.length == 4,
      'CalmTabBar has four labelled slots plus the +.',
    );
    assert(
      icons == null || icons!.length == 4,
      'One icon per label, or none at all.',
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // The widget is 18pt TALLER than the bar it paints, and that is not a
    // decoration. CSS lets `margin-block-start: -18px` overflow a box and stay
    // clickable; Flutter's RenderBox.hitTest rejects a position outside its own
    // size before it ever reaches the child, so a + drawn overhanging a 62pt
    // bar would have 44pt of hit area — under the 52 floor, on the app's most
    // pressed control. The extra band is transparent and sits on `bg`, which
    // is the colour of the page behind it, so it is invisible.
    return Stack(
      children: [
        const PositionedDirectional(
          top: kCalmTabFabLift,
          start: 0,
          end: 0,
          bottom: 0,
          child: CalmTabBarSurface(),
        ),
        // The only NON-positioned child, so it is what sizes the Stack. The
        // bar therefore grows with the text scale rather than clipping its
        // labels at 150% — SPEC.md §17 allows zero glyph clipping at 200%.
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: kCalmTabFabLift,
            bottom: bottomInset,
          ),
          // `grid-template-columns: repeat(5, 1fr)`. The middle slot is empty:
          // the + lives in its own band above, so its whole 62 is hittable.
          // Four tabs, with the empty middle slot inserted between the second
          // and the third. Iterating the FIVE grid slots instead meant
          // `i < 2 ? i : i - 1` written four times in four places, which is
          // four chances to get an off-by-one wrong on a bar that is on all 28
          // screens.
          child: Row(
            children: [
              for (var tab = 0; tab < 4; tab++) ...[
                if (tab == 2)
                  const Expanded(
                    child: CalmTabSlot(child: SizedBox.shrink()),
                  ),
                Expanded(
                  child: CalmTabSlot(
                    child: _CalmTabItem(
                      label: labels[tab],
                      icon: icons?[tab],
                      active: tab == index,
                      onTap: () => onChanged(tab),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: kCalmTabFabSize,
          // Centred in the bar, not in a slot: dead centre in both directions
          // with no second code path.
          child: Center(
            child: CalmTabFab(onTap: onAdd, semanticLabel: addLabel),
          ),
        ),
      ],
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

    return DecoratedBox(
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
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    return ConstrainedBox(
      // 62 at 1x, and taller when the label needs it.
      constraints: BoxConstraints(minHeight: space.tabbarH),
      // heightFactor, or the Center expands to whatever loose height the Row
      // hands it — which is the whole screen, and the bar with it.
      child: Center(heightFactor: 1, child: child),
    );
  }
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
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    // `.tabbar__item { color: var(--color-ink-3) }` — the design's value, and
    // a known WCAG 1.4.3 failure at 13px on `bg` (3.67:1 light). It is the
    // same ink3 finding deferred to EPIC-17, and the pair is already declared
    // and excepted in calm_contrast_test.dart. Quietly substituting ink2 here
    // would make the app disagree with its own reference screenshots.
    final tint = active ? colors.brand : colors.ink3;

    return Semantics(
      selected: active,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: 0,
        pressScale: 1,
        child: ConstrainedBox(
          // 52 inside a 62 bar, and a MINIMUM: at 200% the icon and the label
          // together need more than 52, and a fixed height would clip them.
          constraints: BoxConstraints(minHeight: space.touchMin),
          // heightFactor here too: a Center under a bounded height expands to
          // fill it, and the bar takes the whole screen.
          child: Center(
            heightFactor: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: space.iconMd, color: tint),
                  const SizedBox(height: 3), // .tabbar__item { gap: 3px }
                ],
                Text(
                  label,
                  textAlign: TextAlign.center,
                  // No maxLines. "Settings" at 150% does not fit a fifth of a
                  // 320pt screen on one line, and SPEC.md §17 allows zero
                  // glyph clipping at 200%. Calm cuts words, not type — the
                  // bar grows.
                  // Weight AND colour, never colour alone.
                  style: type.caption.copyWith(
                    color: tint,
                    fontWeight: active ? type.semi : type.medium,
                  ),
                ),
              ],
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
