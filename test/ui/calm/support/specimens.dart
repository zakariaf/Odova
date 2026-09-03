// The one list of Calm specimens.
//
// The gallery and the golden matrix both read it, so a new widget state cannot
// be added to one and forgotten in the other — which is how a specimen sheet
// stops describing the library it documents.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_card.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_icon_tile.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_number_pad.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_sheet.dart';
import 'package:odova/ui/calm/calm_snackbar.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_stepper.dart';
import 'package:odova/ui/calm/calm_switch.dart';
import 'package:odova/ui/calm/calm_tile.dart';

/// One widget, with every state it has, stacked in a column.
@immutable
class CalmSpecimen {
  /// Creates a specimen.
  const CalmSpecimen(this.name, this.build);

  /// The golden's filename stem, and the gallery's section heading.
  final String name;

  /// Builds the states.
  ///
  /// `rtl` is true when the sheet is being rendered for a right-to-left
  /// locale, so a specimen can use fixture strings in the script the direction
  /// implies — Persian text and Extended Arabic-Indic digits, which is where
  /// glyph joining and the `۰۱۲۳` block actually get exercised.
  final List<Widget> Function({required bool rtl}) build;
}

String _t({
  required bool rtl,
  required String latin,
  required String persian,
}) => rtl ? persian : latin;

CalmDueView _due(
  bool rtl,
  DueState state, {
  DueConfidence confidence = DueConfidence.measured,
  double? progress = 0.7,
  String? anchor,
}) => CalmDueView(
  state: state,
  driver: DueDriver.distance,
  confidence: confidence,
  title: _t(rtl: rtl, latin: 'Oil change', persian: 'تعویض روغن'),
  statusLine: _t(
    rtl: rtl,
    latin: 'Due in ~900 km',
    persian: 'حدود ۹۰۰ کیلومتر مانده',
  ),
  actionLabel: _t(rtl: rtl, latin: 'Log it', persian: 'ثبت'),
  anchorLine: anchor,
  progress: progress,
);

/// Every widget in `lib/ui/calm/`, in every state it declares.
List<CalmSpecimen> calmSpecimens() => [
  CalmSpecimen(
    'pressable',
    ({required rtl}) => [
      CalmPressable(
        onTap: () {},
        borderRadius: 16,
        child: CalmCard(
          child: Text(_t(rtl: rtl, latin: 'Pressable', persian: 'قابل فشار')),
        ),
      ),
      CalmPressable(
        onTap: () {},
        borderRadius: 16,
        child: const CalmDirectionalIcon(
          Icons.chevron_right,
          size: 24,
          color: Color(0xFF2C2420),
        ),
      ),
    ],
  ),
  CalmSpecimen(
    'card',
    ({required rtl}) => [
      for (final variant in CalmCardVariant.values)
        CalmCard(variant: variant, child: Text(variant.name)),
    ],
  ),
  CalmSpecimen(
    'tile',
    ({required rtl}) => [
      Row(
        children: [
          Expanded(
            child: CalmTile(
              value: '6.4',
              label: _t(
                rtl: rtl,
                latin: 'L/100 km',
                persian: 'لیتر در ۱۰۰ کیلومتر',
              ),
            ),
          ),
          Expanded(
            child: CalmTile(
              value: '1.73',
              label: _t(
                rtl: rtl,
                latin: 'Cost per km',
                persian: 'هزینه هر کیلومتر',
              ),
              brand: true,
            ),
          ),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'icon-tile',
    ({required rtl}) => [
      Wrap(
        spacing: 12,
        children: [
          const CalmIconTile(icon: Icons.build_outlined),
          for (final state in DueState.values)
            CalmIconTile(icon: Icons.build_outlined, state: state),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'rows',
    ({required rtl}) => [
      CalmRowGroup(
        header: _t(rtl: rtl, latin: 'Reminders', persian: 'یادآورها'),
        footer: _t(
          rtl: rtl,
          latin: 'Odova checks both.',
          persian: 'اودوا هر دو را بررسی می‌کند.',
        ),
        rows: [
          CalmListRow(
            title: _t(rtl: rtl, latin: 'Oil change', persian: 'تعویض روغن'),
            subtitle: _t(
              rtl: rtl,
              latin: 'every 15,000 km',
              persian: 'هر ۱۵٬۰۰۰ کیلومتر',
            ),
            lead: const CalmIconTile(icon: Icons.opacity_outlined),
            value: '~900',
            onTap: () {},
            showChevron: true,
            size: CalmRowSize.lg,
          ),
          CalmListRow(
            title: _t(rtl: rtl, latin: 'Selected', persian: 'انتخاب‌شده'),
            selected: true,
            onTap: () {},
          ),
          CalmListRow(
            title: _t(rtl: rtl, latin: 'Delete vehicle', persian: 'حذف خودرو'),
            danger: true,
            onTap: () {},
          ),
          CalmListRow(
            title: _t(rtl: rtl, latin: 'Disabled', persian: 'غیرفعال'),
            enabled: false,
            onTap: () {},
          ),
          CalmListRow.switchRow(
            title: _t(rtl: rtl, latin: 'Notifications', persian: 'اعلان‌ها'),
            onToggle: () {},
            end: const CalmSwitch(value: true, onChanged: null),
          ),
          CalmListRow(
            title: _t(rtl: rtl, latin: 'Compact', persian: 'فشرده'),
            size: CalmRowSize.compact,
            onTap: () {},
          ),
        ],
      ),
      CalmListRow(
        title: _t(rtl: rtl, latin: 'Standalone', persian: 'مستقل'),
        standalone: true,
        onTap: () {},
        showChevron: true,
      ),
    ],
  ),
  CalmSpecimen(
    'button',
    ({required rtl}) => [
      for (final variant in CalmButtonVariant.values)
        CalmButton(
          label: variant.name,
          onPressed: () {},
          variant: variant,
          icon: variant == CalmButtonVariant.icon ? Icons.add : null,
          dueState: DueState.needsOdometer,
          block: true,
        ),
      for (final size in CalmButtonSize.values)
        CalmButton(label: size.name, onPressed: () {}, size: size),
      CalmButton(
        label: _t(rtl: rtl, latin: 'Saving', persian: 'در حال ذخیره'),
        onPressed: () {},
        loading: true,
        block: true,
      ),
      Column(
        children: [
          CalmButton(
            label: _t(rtl: rtl, latin: 'Save', persian: 'ذخیره'),
            onPressed: null,
            block: true,
          ),
          CalmButtonExplain(
            reason: _t(
              rtl: rtl,
              latin: 'Odometer required',
              persian: 'کیلومترشمار لازم است',
            ),
          ),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'chip',
    ({required rtl}) => [
      CalmChipBar(
        chips: [
          CalmChip(
            label: _t(rtl: rtl, latin: 'All', persian: 'همه'),
            onTap: () {},
            selected: true,
          ),
          CalmChip(
            label: _t(rtl: rtl, latin: 'Fuel', persian: 'سوخت'),
            onTap: () {},
          ),
          CalmChip(
            label: _t(rtl: rtl, latin: 'Business', persian: 'کاری'),
            onTap: () {},
            business: true,
          ),
          CalmChip(
            label: _t(rtl: rtl, latin: 'Disabled', persian: 'غیرفعال'),
            onTap: () {},
            enabled: false,
          ),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'badge',
    ({required rtl}) => [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final kind in CalmBadgeKind.values)
            if (kind == CalmBadgeKind.dot)
              const CalmBadge.dot()
            else
              CalmBadge(label: kind.name, kind: kind),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'status-dot',
    ({required rtl}) => [
      // A Builder, not a captured context: a specimen list that holds a
      // BuildContext resolves the theme of whichever sheet was built last.
      Builder(
        builder: (context) => Row(
          children: [
            for (final state in DueState.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: CalmStatusDot(
                  style: CalmStatusStyle.of(context, state),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
  CalmSpecimen(
    'field',
    ({required rtl}) => [
      CalmField(
        label: _t(rtl: rtl, latin: 'Odometer', persian: 'کیلومترشمار'),
        controller: TextEditingController(
          text: _t(rtl: rtl, latin: '187412', persian: '۱۸۷۴۱۲'),
        ),
        hint: _t(rtl: rtl, latin: 'Whole kilometres', persian: 'کیلومتر کامل'),
        affix: Text(_t(rtl: rtl, latin: 'km', persian: 'کیلومتر')),
        numeric: true,
      ),
      CalmField(
        label: _t(rtl: rtl, latin: 'Odometer', persian: 'کیلومترشمار'),
        controller: TextEditingController(
          text: _t(rtl: rtl, latin: '9', persian: '۹'),
        ),
        errorText: _t(
          rtl: rtl,
          latin: 'Lower than the last reading',
          persian: 'کمتر از آخرین عدد',
        ),
      ),
      CalmField(
        label: _t(rtl: rtl, latin: 'Price per litre', persian: 'قیمت هر لیتر'),
        controller: TextEditingController(
          text: _t(rtl: rtl, latin: '1.734', persian: '۱٫۷۳۴'),
        ),
        computed: true,
        computedHint: _t(rtl: rtl, latin: 'Calculated', persian: 'محاسبه‌شده'),
      ),
      CalmField(
        label: _t(rtl: rtl, latin: 'Note', persian: 'یادداشت'),
        controller: TextEditingController(),
        size: CalmFieldSize.lg,
        placeholder: _t(rtl: rtl, latin: 'Optional', persian: 'اختیاری'),
      ),
      CalmField(
        label: _t(rtl: rtl, latin: 'Disabled', persian: 'غیرفعال'),
        controller: TextEditingController(text: '—'),
        enabled: false,
      ),
    ],
  ),
  CalmSpecimen(
    'stepper',
    ({required rtl}) => [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: CalmStepper(
          value: _t(rtl: rtl, latin: '15,000', persian: '۱۵٬۰۰۰'),
          onDecrement: () {},
          onIncrement: () {},
          decrementLabel: _t(rtl: rtl, latin: 'Less', persian: 'کمتر'),
          incrementLabel: _t(rtl: rtl, latin: 'More', persian: 'بیشتر'),
        ),
      ),
    ],
  ),
  CalmSpecimen(
    'switch',
    ({required rtl}) => [
      // Two ENABLED, so the traversal matrix actually reaches them: it
      // enumerates CalmPressable, and a disabled control is skipped. A switch
      // that opted out of the primitive was the one control that matrix could
      // never check, which is exactly how it went keyboard-unreachable.
      Row(
        children: [
          CalmSwitch(value: false, onChanged: (_) {}),
          const SizedBox(width: 16),
          CalmSwitch(value: true, onChanged: (_) {}),
          const SizedBox(width: 16),
          const CalmSwitch(value: true, onChanged: null),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'segmented',
    ({required rtl}) => [
      CalmSegmented(
        labels: [
          _t(rtl: rtl, latin: 'km', persian: 'کیلومتر'),
          _t(rtl: rtl, latin: 'mi', persian: 'مایل'),
        ],
        index: 0,
        onChanged: (_) {},
      ),
    ],
  ),
  CalmSpecimen(
    'app-bar',
    ({required rtl}) => [
      CalmAppBar(
        title: _t(rtl: rtl, latin: 'Settings', persian: 'تنظیمات'),
      ),
      CalmAppBar.large(
        title: _t(rtl: rtl, latin: 'Costs', persian: 'هزینه‌ها'),
        subtitle: _t(
          rtl: rtl,
          latin: 'Last 12 months',
          persian: '۱۲ ماه گذشته',
        ),
      ),
      CalmAppBar.vehicle(
        title: _t(rtl: rtl, latin: 'Golf TDI', persian: 'گلف'),
        onTapVehicle: () {},
      ),
      CalmAppBar.modal(
        title: _t(rtl: rtl, latin: 'Log a fill-up', persian: 'ثبت سوخت‌گیری'),
        startLabel: _t(rtl: rtl, latin: 'Cancel', persian: 'لغو'),
        onStart: () {},
        endLabel: _t(rtl: rtl, latin: 'Save', persian: 'ذخیره'),
        onEnd: () {},
      ),
    ],
  ),
  CalmSpecimen(
    'tab-bar',
    ({required rtl}) => [
      CalmTabBar(
        index: 0,
        onChanged: (_) {},
        onAdd: () {},
        addLabel: _t(rtl: rtl, latin: 'Add', persian: 'افزودن'),
        labels: [
          _t(rtl: rtl, latin: 'Home', persian: 'خانه'),
          _t(rtl: rtl, latin: 'History', persian: 'تاریخچه'),
          _t(rtl: rtl, latin: 'Costs', persian: 'هزینه‌ها'),
          _t(rtl: rtl, latin: 'Settings', persian: 'تنظیمات'),
        ],
        icons: const [
          Icons.home_outlined,
          Icons.history,
          Icons.pie_chart_outline,
          Icons.settings_outlined,
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'sheet',
    ({required rtl}) => [
      CalmSheet(
        title: _t(
          rtl: rtl,
          latin: 'Choose a category',
          persian: 'یک دسته انتخاب کنید',
        ),
        subtitle: _t(
          rtl: rtl,
          latin: 'Service and repairs',
          persian: 'سرویس و تعمیر',
        ),
        actions: [
          CalmButton(
            label: _t(rtl: rtl, latin: 'Save', persian: 'ذخیره'),
            onPressed: () {},
            block: true,
          ),
        ],
        children: [
          Text(_t(rtl: rtl, latin: 'Oil change', persian: 'تعویض روغن')),
          Text(_t(rtl: rtl, latin: 'Brake pads', persian: 'لنت ترمز')),
        ],
      ),
    ],
  ),
  CalmSpecimen(
    'dialog',
    ({required rtl}) => [
      CalmDialog(
        icon: Icons.delete_outline,
        danger: true,
        title: _t(
          rtl: rtl,
          latin: 'Delete this fill-up?',
          persian: 'این سوخت‌گیری حذف شود؟',
        ),
        body: _t(
          rtl: rtl,
          latin: '42.8 L on 12 March. This cannot be undone.',
          persian: '۴۲٫۸ لیتر در ۱۲ مارس. این کار برگشت‌پذیر نیست.',
        ),
        confirmLabel: _t(rtl: rtl, latin: 'Delete', persian: 'حذف'),
        onConfirm: () {},
        cancelLabel: _t(rtl: rtl, latin: 'Keep it', persian: 'نگه‌داشتن'),
        onCancel: () {},
      ),
    ],
  ),
  CalmSpecimen(
    'snackbar',
    ({required rtl}) => [
      CalmSnackbar(
        message: _t(
          rtl: rtl,
          latin: 'Fill-up saved',
          persian: 'سوخت‌گیری ذخیره شد',
        ),
        actionLabel: _t(rtl: rtl, latin: 'Undo', persian: 'واگرد'),
        onAction: () {},
      ),
      CalmSnackbar(
        message: _t(
          rtl: rtl,
          latin: 'Vehicle deleted',
          persian: 'خودرو حذف شد',
        ),
        actionLabel: _t(rtl: rtl, latin: 'Undo', persian: 'واگرد'),
        onAction: () {},
        danger: true,
      ),
    ],
  ),
  CalmSpecimen(
    'number-pad',
    ({required rtl}) => [
      CalmNumberPad(
        value: _t(rtl: rtl, latin: '187,412', persian: '۱۸۷٬۴۱۲'),
        unit: _t(rtl: rtl, latin: 'km', persian: 'کیلومتر'),
        hint: _t(
          rtl: rtl,
          latin: '+432 km since 12 Mar',
          persian: '+۴۳۲ کیلومتر از ۱۲ مارس',
        ),
        digits: rtl
            ? const ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹']
            : null,
        onDigit: (_) {},
        onDecimal: () {},
        onBackspace: () {},
        onConfirm: () {},
        confirmLabel: _t(rtl: rtl, latin: 'Save', persian: 'ذخیره'),
        decimalLabel: _t(rtl: rtl, latin: '.', persian: '٫'),
        secondaryLabel: _t(rtl: rtl, latin: 'Clear', persian: 'پاک'),
        onSecondary: () {},
        backspaceSemanticLabel: _t(
          rtl: rtl,
          latin: 'Backspace',
          persian: 'حذف',
        ),
      ),
    ],
  ),
  CalmSpecimen(
    'due-card',
    ({required rtl}) => [
      CalmDueCard(
        view: _due(
          rtl,
          DueState.overdue,
          anchor: _t(
            rtl: rtl,
            latin: 'Was due at 186,512 km',
            persian: 'موعد در ۱۸۶٬۵۱۲ کیلومتر',
          ),
        ),
        density: CalmDueDensity.primary,
        onTap: () {},
        onAction: () {},
      ),
      CalmDueCard(
        view: _due(
          rtl,
          DueState.needsOdometer,
          confidence: DueConfidence.defaulted,
          progress: null,
        ),
        density: CalmDueDensity.primary,
        onTap: () {},
        onAction: () {},
      ),
      for (final state in DueState.values)
        CalmDueCard(
          view: _due(rtl, state),
          density: CalmDueDensity.secondary,
          onTap: () {},
          onAction: () {},
        ),
    ],
  ),
  CalmSpecimen(
    'all-clear',
    ({required rtl}) => [
      CalmAllClear(
        headline: _t(
          rtl: rtl,
          latin: 'Nothing due',
          persian: 'چیزی موعد ندارد',
        ),
        nextLine: _t(
          rtl: rtl,
          latin: 'Next: Inspection, 14 March',
          persian: 'بعدی: معاینه، ۱۴ مارس',
        ),
        fuzzLine: _t(
          rtl: rtl,
          latin: 'in about 6 weeks',
          persian: 'حدود ۶ هفته دیگر',
        ),
        since: CalmSinceLine(
          label: _t(
            rtl: rtl,
            latin: 'Since the last oil change',
            persian: 'از آخرین تعویض روغن',
          ),
          figure: _t(
            rtl: rtl,
            latin: '3,120 km · 4 months',
            persian: '۳٬۱۲۰ کیلومتر · ۴ ماه',
          ),
        ),
      ),
    ],
  ),
  CalmSpecimen(
    'empty-state',
    ({required rtl}) => [
      CalmEmptyState(
        icon: Icons.local_gas_station_outlined,
        title: _t(
          rtl: rtl,
          latin: 'No fill-ups yet',
          persian: 'هنوز سوخت‌گیری ثبت نشده',
        ),
        body: _t(
          rtl: rtl,
          latin: 'Log one at the pump and Odova works out the rest.',
          persian: 'یکی را سر پمپ ثبت کنید تا اودوا بقیه را حساب کند.',
        ),
        action: CalmButton(
          label: _t(rtl: rtl, latin: 'Log a fill-up', persian: 'ثبت سوخت‌گیری'),
          onPressed: () {},
        ),
      ),
    ],
  ),
];

/// Every Latin string in these sheets renders in Vazirmatn.
///
/// Not a cosmetic choice: with no platform font in a test, an unnamed style
/// falls back to a face whose glyphs are square ems — roughly twice as wide as
/// any real font. An overflow matrix run against that measures a font nobody
/// ships, reports failures the design does not have, and would force the
/// layout to be redrawn around them. `fontFamily` is null on every CalmType
/// role, so it merges down from here.
class CalmSpecimenFont extends StatelessWidget {
  /// Wraps [child].
  const CalmSpecimenFont({required this.child, super.key});

  /// The sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(fontFamily: 'Vazirmatn'),
    child: child,
  );
}

/// The sheet every specimen matrix pumps.
///
/// Here rather than in each matrix, for the same reason [calmSpecimens] is:
/// the overflow, touch-target, traversal and golden lanes all sweep the whole
/// library, and three of them had their own copy of this tree. A change one of
/// them needs — a MediaQuery, a wider constraint, a Directionality — landed in
/// one and silently not the others, and each matrix then measured a slightly
/// different library.
class CalmSpecimenSheet extends StatelessWidget {
  /// Wraps [children].
  const CalmSpecimenSheet({
    required this.children,
    super.key,
    this.padded = false,
  });

  /// One specimen's states.
  final List<Widget> children;

  /// The golden lane's variant: the theme's own ground, a margin, and a gap
  /// between states so the sheet reads as a specimen sheet.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: padded
          ? [
              for (final child in children) ...[
                child,
                const SizedBox(height: 16),
              ],
            ]
          : children,
    );

    return CalmSpecimenFont(
      child: ColoredBox(
        color: padded
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0x00000000),
        child: SingleChildScrollView(
          child: padded
              ? Padding(padding: const EdgeInsets.all(20), child: column)
              : column,
        ),
      ),
    );
  }
}
