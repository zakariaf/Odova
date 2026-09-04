/// The screens the three dialog references were shot OVER.
///
/// `dialog.discard` and `dialog.snooze` were shot over `home`, and
/// `dialog.confirmDelete` over `vehicles` — and none of those screens exists
/// when EPIC-08 runs. The band check compares against the whole 390x844 frame,
/// so a missing backdrop fails the gate for a reason that has nothing to do
/// with the dialog.
///
/// So these are static, non-interactive compositions of EPIC-03's widgets
/// reproducing the reference backdrops' band profile, built from the same
/// fixture the reference depicts: the Golf at 187,412 km with oil overdue by
/// 900 km. **Test-only. Never shipped** — `test/policy/structure_test.dart`
/// asserts nothing under `lib/` imports this file.
///
/// EPIC-09 and EPIC-10 replace them with the real screens and re-run the three
/// captures. **If the parity result CHANGES when they do, this stand-in was
/// lying** — and that is a finding then, not a shrug (EPIC-08 finding F-8.2).
library;

import 'package:flutter/material.dart';
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

/// The strings the reference draws, per direction.
///
/// Hand-transcribed from `design/calm/screens.html`'s `data-en` / `data-fa`
/// attributes rather than pulled from the ARB files, and deliberately so: this
/// fixture must reproduce the REFERENCE, and a string that has since been
/// reworded in the ARB would silently change the band profile.
class ParityCopy {
  /// Creates the transcription for a direction.
  const ParityCopy({required this.rtl});

  /// Reads the direction from [context].
  ///
  /// One authority for both parity files: the backdrop and the dialog on top of
  /// it must name the same car, and two transcriptions would let them disagree
  /// without anything failing.
  factory ParityCopy.of(BuildContext context) =>
      ParityCopy(rtl: Directionality.of(context) == TextDirection.rtl);

  /// Whether the capture is right-to-left.
  final bool rtl;

  String _t(String latin, String persian) => rtl ? persian : latin;

  /// A number, in the artboard's numerals.
  ///
  /// A lookup rather than a formatter: these are the exact figures the pictures
  /// carry, and EPIC-04's formatters have their own tests.
  String number(int n) =>
      rtl ? '$n'.split('').map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)]).join() : '$n';

  /// A snooze date, exactly as the artboard writes it.
  String artboardDate(CivilDate date) => switch ((date.month, date.day)) {
    (9, 6) => _t('6 Sep', '۱۵ شهریور'),
    (9, 10) => _t('10 Sep', '۱۹ شهریور'),
    (10, 3) => _t('3 Oct', '۱۱ مهر'),
    _ => _t('${date.day}/${date.month}', '${date.day}/${date.month}'),
  };

  /// A distance, exactly as the artboard writes it.
  String artboardDistance(int metres) => switch (metres) {
    500000 => _t('500 km', '۵۰۰ کیلومتر'),
    187912000 => _t('187,912 km', '۱۸۷٬۹۱۲ کیلومتر'),
    _ => _t('${metres ~/ 1000} km', '${metres ~/ 1000} کیلومتر'),
  };

  /// The discard dialog's summary half.
  String get discardSummary => _t(
    'a 15,000 km interval and a new baseline',
    'بازه ۱۵٬۰۰۰ کیلومتری و مبنای جدید',
  );

  /// The confirm-delete dialog's safe alternative.
  String get keepItMarkSold => _t(
    'Keep it — mark it sold',
    'نگهش دار — فروخته‌شده علامت بزن',
  );

  String get vehicle => _t('The Golf', 'گلف');
  String get overdueBadge => _t('1 overdue', '۱ عقب‌افتاده');
  String get odometer => _t('187,412 km', '۱۸۷٬۴۱۲ کیلومتر');
  String get odometerMeta => _t('Entered 2 September', 'ثبت‌شده در ۱۱ شهریور');
  String get oil => _t('Oil and filter', 'روغن و فیلتر');
  String get oilStatus => _t('Overdue by 900 km', '۹۰۰ کیلومتر عقب‌افتاده');
  String get oilAnchor => _t(
    'Was due at 186,512 km · 12 August',
    'موعدش ۱۸۶٬۵۱۲ کیلومتر بود · ۲۱ مرداد',
  );
  String get logIt => _t('Log it', 'ثبت کن');
  String get inspection => _t('Inspection (TÜV)', 'معاینه فنی');
  String get inspectionDue => _t('14 March', '۲۳ اسفند');
  String get brakes => _t('Brake pads', 'لنت ترمز');
  String get brakesDue => _t('in about 1,800 km', 'حدود ۱٬۸۰۰ کیلومتر');
  String get belt => _t('Timing belt', 'تسمه تایم');
  String get beltSub => _t(
    'Odova needs a reading to say when',
    'اودووا به عدد کیلومتر نیاز دارد',
  );
  String get lastFillUp => _t('Last fill-up', 'آخرین سوخت‌گیری');
  String get lastFillUpSub =>
      _t('2 September · 42.8 L', '۱۱ شهریور · ۴۲٫۸ لیتر');
  String get lastFillUpValue => _t('€74.20', '۷۴٬۲۰۰ تومان');
  String get lastFillUpConsumption => _t('6.4 L/100 km', '۶٫۴ ل/۱۰۰ کیلومتر');
  String get home => _t('Home', 'خانه');
  String get history => _t('History', 'تاریخچه');
  String get costs => _t('Costs', 'هزینه‌ها');
  String get settings => _t('Settings', 'تنظیمات');
  String get log => _t('Log', 'ثبت');
  String get vehiclesTitle => _t('Vehicles', 'خودروها');
  String get garageCaption => _t(
    'Manage the garage here. Switching cars happens from the Home title.',
    'گاراژ را اینجا مدیریت کنید. تعویض خودرو از عنوان صفحه خانه انجام می‌شود.',
  );

  /// The three vehicles the artboard lists: name, spec line, status line, and
  /// the due state its dot and tile take.
  List<(String, String, String, DueState)> get garage => [
    (
      _t('The Golf', 'گلف'),
      _t('VW Golf VII · 2016 · diesel', 'فولکس‌واگن گلف ۷ · ۲۰۱۶ · دیزل'),
      _t(
        '187,412 km · oil and filter overdue',
        '۱۸۷٬۴۱۲ کیلومتر · روغن عقب‌افتاده',
      ),
      DueState.overdue,
    ),
    (
      _t('Transit', 'ترنزیت'),
      _t('Ford Transit · 2019 · business', 'فورد ترنزیت · ۲۰۱۹ · کاری'),
      _t('96,400 km · all good', '۹۶٬۴۰۰ کیلومتر · همه‌چیز مرتب'),
      DueState.ok,
    ),
    (
      'CB500X',
      _t('Honda · 2021 · petrol', 'هوندا · ۲۰۲۱ · بنزین'),
      _t('23,905 km · no reminders yet', '۲۳٬۹۰۵ کیلومتر · هنوز یادآوری ندارد'),
      DueState.needsOdometer,
    ),
  ];
}

/// The `home` screen as the discard and snooze references draw it.
class HomeBackdrop extends StatelessWidget {
  /// Creates the backdrop.
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final copy = ParityCopy(rtl: rtl);

    // `Material`, because a screen has one and this stand-in replaced the
    // `CalmScaffold` that used to provide it. Without one, every `Text` here
    // inherits `WidgetsApp`'s fallback `DefaultTextStyle` — 48pt bold red
    // monospace — and `CalmType` overrides all of it except the FAMILY. The
    // strings then measure about twice their real width, which showed up as a
    // `CalmListRow` overflow and would have made every band edge wrong.
    return Material(
      color: CalmColors.of(context).bg,
      child: SafeArea(
        // `bottom: false` — the tab bar draws its own inset, exactly as
        // `CalmScaffold` does it.
        bottom: false,
        child: Column(
          children: [
            CalmAppBar.vehicle(
              title: copy.vehicle,
              onTapVehicle: _inert,
              actions: [
                CalmBadge(
                  label: copy.overdueBadge,
                  kind: CalmBadgeKind.overdue,
                ),
              ],
            ),
            Expanded(child: _Body(copy: copy)),
            CalmTabBar(
              index: 0,
              onChanged: _inertIndex,
              onAdd: _inert,
              addLabel: copy.log,
              labels: [copy.home, copy.history, copy.costs, copy.settings],
              // `CalmTabIcons`, not a second list. `app_shell.dart` records
              // that the Costs glyph is expected to change in EPIC-09; a copy
              // here would keep the old one and shift the parity result for a
              // reason unrelated to the dialog — the one signal this fixture
              // exists to keep meaningful.
              icons: const [
                CalmTabIcons.home,
                CalmTabIcons.history,
                CalmTabIcons.costs,
                CalmTabIcons.settings,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The artboard's body, at the ARTBOARD's spacing.
///
/// **Not `CalmScaffold`, and that is a finding rather than a shortcut.**
/// `.screen__body` in `odova.css` is `padding-block: 20 24; gap: 20`, which is
/// exactly what `CalmScaffold` implements. But the `home` artboard overrides it
/// inline to `padding-block: 8 12; gap: 12` — tightened so more of the screen
/// fits in the frame for the screenshot. So the reference picture of `home` is
/// NOT what a standard `CalmScaffold` produces, and a backdrop built with one
/// misses roughly a quarter of the reference's band edges for a reason that has
/// nothing to do with the dialog on top of it.
///
/// This fixture reproduces the ARTBOARD, because its whole job is to make the
/// band check see the dialog rather than the wall behind it. **EPIC-10 will hit
/// the same gap building the real Home** and has to decide it deliberately:
/// either `home`'s artboard is re-shot at `.screen__body`'s own spacing, or
/// `CalmScaffold` gains the density the artboard is using. Recorded in
/// `epics/progress/EPIC-08.md`.
class _Body extends StatelessWidget {
  const _Body({required this.copy});

  final ParityCopy copy;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    // Four fixed children, so a plain `ListView` rather than `.separated` with
    // a builder: the builder form called `_rows(context)` once for `itemCount`
    // and again for every index — five constructions of the same list, fifteen
    // status-style resolutions where three would do, and all of it re-run on
    // every relayout.
    final rows = _rows(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        space.screenPad,
        space.s2,
        space.screenPad,
        space.s3,
      ),
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) SizedBox(height: space.s3),
          row,
        ],
      ],
    );
  }

  List<Widget> _rows(BuildContext context) => [
    CalmListRow(
      title: copy.odometer,
      subtitle: copy.odometerMeta,
      lead: const CalmIconTile(icon: Icons.speed_outlined),
      onTap: _inert,
      size: CalmRowSize.lg,
      standalone: true,
      showChevron: true,
    ),
    CalmDueCard(
      view: CalmDueView(
        state: DueState.overdue,
        driver: DueDriver.distance,
        confidence: RateConfidence.measured,
        title: copy.oil,
        statusLine: copy.oilStatus,
        anchorLine: copy.oilAnchor,
        actionLabel: copy.logIt,
        progress: 1,
      ),
      density: CalmDueDensity.primary,
      onTap: _inert,
      onAction: _inert,
    ),
    CalmRowGroup(
      rows: [
        CalmListRow(
          title: copy.inspection,
          value: copy.inspectionDue,
          lead: _dot(context, DueState.dueSoon),
          onTap: _inert,
          size: CalmRowSize.compact,
          showChevron: true,
        ),
        CalmListRow(
          title: copy.brakes,
          value: copy.brakesDue,
          lead: _dot(context, DueState.dueSoon),
          onTap: _inert,
          size: CalmRowSize.compact,
          showChevron: true,
        ),
        CalmListRow(
          title: copy.belt,
          subtitle: copy.beltSub,
          lead: _dot(context, DueState.unknown),
          onTap: _inert,
          size: CalmRowSize.compact,
          showChevron: true,
        ),
      ],
    ),
    CalmListRow(
      title: copy.lastFillUp,
      subtitle: copy.lastFillUpSub,
      // A stacked END, not `value:`. The artboard's `.row__end` here is a
      // `u-stack` of the amount over the consumption, and a single-line value
      // makes the row shorter than the reference's — which the band check reads
      // as two missing edges.
      end: _StackedEnd(
        value: copy.lastFillUpValue,
        sub: copy.lastFillUpConsumption,
      ),
      lead: const CalmIconTile(icon: Icons.local_gas_station_outlined),
      onTap: _inert,
      size: CalmRowSize.compact,
      standalone: true,
    ),
  ];
}

/// The amount over the consumption, as the artboard's `.row__end u-stack`.
class _StackedEnd extends StatelessWidget {
  const _StackedEnd({required this.value, required this.sub});

  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: type.body.copyWith(
            color: colors.ink2,
            fontWeight: type.medium,
          ),
        ),
        // `--gap: 2px` in the artboard's inline style.
        const SizedBox(height: 2),
        Text(sub, style: type.caption.copyWith(color: colors.ink3)),
      ],
    );
  }
}

/// A status dot, resolved against the theme.
///
/// `CalmStatusStyle` is deliberately not constructible by a caller — a resolved
/// style is derived from the theme, never chosen — so the dot takes one from
/// `of`.
Widget _dot(BuildContext context, DueState state) =>
    CalmStatusDot(style: CalmStatusStyle.of(context, state));

/// A backdrop does nothing when tapped: it is a picture, not a screen.
void _inert() {}
void _inertIndex(int _) {}

/// The `vehicles` screen as the confirm-delete reference draws it.
///
/// Same caveats as [HomeBackdrop] and the same artboard override — this one
/// tightens `padding-block` to `4 12`. A stand-in for a screen EPIC-09 builds,
/// kept only so the band check sees the dialog rather than the wall behind it.
class VehiclesBackdrop extends StatelessWidget {
  /// Creates the backdrop.
  const VehiclesBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final copy = ParityCopy(rtl: rtl);
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Material(
      color: colors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CalmAppBar(title: copy.vehiclesTitle),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  space.screenPad,
                  space.s1,
                  space.screenPad,
                  space.s3,
                ),
                children: [
                  Text(
                    copy.garageCaption,
                    style: type.caption.copyWith(color: colors.ink3),
                  ),
                  SizedBox(height: space.s5),
                  CalmRowGroup(
                    rows: [
                      for (final vehicle in copy.garage)
                        CalmListRow(
                          title: vehicle.$1,
                          subtitle: '${vehicle.$2}\n${vehicle.$3}',
                          lead: CalmIconTile(
                            icon: Icons.directions_car_outlined,
                            state: vehicle.$4,
                          ),
                          end: _dot(context, vehicle.$4),
                          onTap: _inert,
                          size: CalmRowSize.lg,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
