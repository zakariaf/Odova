// CalmScaffold — the only screen skeleton in Odova.
//
// 56pt app bar, a scrolling body at the 22px gutter with s5 between children, an
// optional non-scrolling foot, and a 62pt tab bar whose centre + overhangs it.
// Bottom chrome comes from MediaQuery.paddingOf, never from --homebar-h: that
// token is specimen-sheet chrome and is 0 on most Android hardware.
//
// Every tap target here is >= --touch-min (52), measured on the gesture node
// rather than the ink. Token slots come from calm_tokens_min.dart.
import 'package:flutter/material.dart';

import 'calm_tokens_min.dart';

class CalmScaffold extends StatelessWidget {
  const CalmScaffold(
      {super.key, required this.appBar, required this.children, this.tabBar, this.footer});

  final CalmAppBar appBar;

  /// The scrolling body. Six languages and an unclamped textScaler mean nothing
  /// on a Calm screen may depend on fitting; SPEC §9's above-the-fold budget is
  /// verified by a 375x667 golden, not bought by making the body rigid.
  final List<Widget> children;

  final Widget? tabBar;

  /// `.screen__foot` — the full-width primary action that stays inside the
  /// thumb's reach however far the body scrolls.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      resizeToAvoidBottomInset: true, // the odometer strip is typed into
      body: SafeArea(
        bottom: tabBar == null, // the tab bar draws its own bottom inset
        child: Column(
          children: [
            appBar,
            Expanded(
              child: ListView.separated(
                padding: EdgeInsetsDirectional.fromSTEB(
                    space.screenPad, space.s5, space.screenPad, space.s6),
                itemCount: children.length,
                separatorBuilder: (_, __) => SizedBox(height: space.s5),
                itemBuilder: (_, i) => children[i],
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    space.screenPad, space.s4, space.screenPad, space.s5),
                child: footer,
              ),
            if (tabBar != null) tabBar!,
          ],
        ),
      ),
    );
  }
}

/// 56pt bar. The chevron and its tap target exist only when a second vehicle
/// does (SPEC §9) — the garage is invisible until it is real.
class CalmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CalmAppBar({super.key, required this.title, this.showVehicleChevron = false,
      this.onTapVehicle, this.actions = const []});

  final String title;
  final bool showVehicleChevron;
  final VoidCallback? onTapVehicle;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(calmSpace.appbarH);

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    // fade, not ellipsis: a truncated vehicle name is still readable.
    final label = Text(title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: CalmType.of(context).title.copyWith(color: colors.ink));

    return Container(
      constraints: BoxConstraints(minHeight: space.appbarH),
      padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Expanded(
            child: showVehicleChevron
                ? _VehicleTitle(onTap: onTapVehicle, child: label)
                : label,
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _VehicleTitle extends StatelessWidget {
  const _VehicleTitle({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // the whole rect responds, not the text
        onTap: onTap,
        child: ConstrainedBox(
          // 52, not the 44 the visible pill would give us.
          constraints: BoxConstraints(minHeight: space.touchMin),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: child),
              SizedBox(width: space.s2),
              Icon(Icons.expand_more, color: colors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}

/// 62pt bar, four labelled slots plus the +, which overhangs the top edge by 18.
class CalmTabBar extends StatelessWidget {
  const CalmTabBar({super.key, required this.index, required this.onChanged,
      required this.onAdd, required this.addLabel, required this.labels});

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  /// The + carries no visible text, so it needs a spoken one.
  final String addLabel;

  /// Home, History, Costs, Settings — already localised.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    assert(labels.length == 4, 'CalmTabBar has four labelled slots plus the +.');
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: space.tabbarH + bottomInset,
      padding: EdgeInsetsDirectional.only(bottom: bottomInset),
      // Elevation, never a border: the bar lifts off the body with --elev-2.
      // A hairline is the dense-spreadsheet vocabulary Calm rejects, and only
      // calm_field.dart and calm_pressable.dart may construct a Border.
      decoration: BoxDecoration(
        color: colors.bg,
        boxShadow: CalmShapes.of(context).elev2,
      ),
      child: Stack(
        clipBehavior: Clip.none, // the + is meant to break the bar's top edge
        alignment: AlignmentDirectional.center,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: _TabItem(
                      label: labels[i], active: i == index, onTap: () => onChanged(i)),
                ),
                if (i == 1) SizedBox(width: space.tabFabSize),
              ],
            ],
          ),
          PositionedDirectional(
            top: -space.tabFabLift,
            child: Semantics(
              button: true,
              label: addLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAdd,
                child: Container(
                  width: space.tabFabSize, // 62, comfortably over the 52 floor
                  height: space.tabFabSize,
                  decoration:
                      BoxDecoration(color: colors.brand, shape: BoxShape.circle),
                  child: Icon(Icons.add, color: colors.onBrand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: space.touchMin, // 52 inside a 62 bar
          child: Center(
            // Active state is weight AND colour, never colour alone.
            child: Text(label,
                maxLines: 1,
                style: type.caption.copyWith(
                    color: active ? colors.brand : colors.ink2,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}

/// `.snackbar` sits above the tab bar and the home indicator. The CSS composes
/// `--homebar-h`; on device that number is MediaQuery's.
double calmSnackbarBottomInset(BuildContext context) {
  final space = CalmSpace.of(context);
  return space.tabbarH + MediaQuery.paddingOf(context).bottom + space.s3;
}
