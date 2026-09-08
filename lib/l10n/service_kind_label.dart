// What a catalogue item is called.
//
// SPEC.md §8 gives `ServiceItem.label` meaning only when `kind = custom` — "the
// user's own item… the only case where the label carries meaning". Every other
// item is a SEED, its label is null by construction
// — `service_item_catalogue.dart` says "the label, which is always null for
// a seed" —
// and its name comes from its kind.
//
// **Those names did not exist.** Two places in the code pointed at "the 28 kind
// strings EPIC-10 owns" and EPIC-10 shipped without them, so `reminders.list`
// drew seven rows all reading "Service", Home read "Next: Service", and the
// service form offered `+ Other` and nothing else. The generic noun was never
// meant to be what a user sees; `vehicleStatusItemGeneric`'s own ARB
// description calls it the fallback for "when the app cannot name the item".
//
// A switch and not a map: `ServiceKind` is a closed enum, so a member added
// without a name here fails to compile rather than silently falling back to the
// noun this file exists to stop showing.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// What [kind] is called, in the active locale.
///
/// `ServiceKind.custom` carries no useful name of its own — the user's label
/// does — so a caller with a label must prefer it. [serviceItemLabel] is that
/// rule.
String serviceKindLabel(AppLocalizations l10n, ServiceKind kind) =>
    switch (kind) {
      ServiceKind.oilAndFilter => l10n.serviceKindOilAndFilter,
      ServiceKind.airFilter => l10n.serviceKindAirFilter,
      ServiceKind.cabinFilter => l10n.serviceKindCabinFilter,
      ServiceKind.fuelFilter => l10n.serviceKindFuelFilter,
      ServiceKind.sparkPlugs => l10n.serviceKindSparkPlugs,
      ServiceKind.timingBelt => l10n.serviceKindTimingBelt,
      ServiceKind.brakePadsCheck => l10n.serviceKindBrakePadsCheck,
      ServiceKind.brakePadsFront => l10n.serviceKindBrakePadsFront,
      ServiceKind.brakePadsRear => l10n.serviceKindBrakePadsRear,
      ServiceKind.brakeFluid => l10n.serviceKindBrakeFluid,
      ServiceKind.coolant => l10n.serviceKindCoolant,
      ServiceKind.transmissionFluid => l10n.serviceKindTransmissionFluid,
      ServiceKind.wheelAlignment => l10n.serviceKindWheelAlignment,
      ServiceKind.tyreRotate => l10n.serviceKindTyreRotate,
      ServiceKind.tyreReplace => l10n.serviceKindTyreReplace,
      ServiceKind.battery => l10n.serviceKindBattery,
      ServiceKind.wipers => l10n.serviceKindWipers,
      ServiceKind.inspection => l10n.serviceKindInspection,
      ServiceKind.registration => l10n.serviceKindRegistration,
      ServiceKind.insuranceRenewal => l10n.serviceKindInsuranceRenewal,
      ServiceKind.acService => l10n.serviceKindAcService,
      ServiceKind.chainLube => l10n.serviceKindChainLube,
      ServiceKind.chainAndSprockets => l10n.serviceKindChainAndSprockets,
      ServiceKind.valveClearance => l10n.serviceKindValveClearance,
      ServiceKind.forkOil => l10n.serviceKindForkOil,
      ServiceKind.reductionGearboxOil => l10n.serviceKindReductionGearboxOil,
      ServiceKind.battery12v => l10n.serviceKindBattery12v,
      ServiceKind.custom => l10n.serviceKindCustom,
    };

/// What THIS item is called: its own label, or its kind's name.
///
/// The label wins where it has one, which for a seed is never and for a custom
/// item is always. `vehicleStatusItemGeneric` is no longer reachable from here
/// — it stays for the case it was written for, an item whose kind the app
/// cannot read at all.
String serviceItemLabel(
  AppLocalizations l10n, {
  required ServiceKind kind,
  required String? label,
}) => switch (label) {
  final String own when own.trim().isNotEmpty => own,
  _ => serviceKindLabel(l10n, kind),
};
