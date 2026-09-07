// SPEC.md §13's delete-all, and the ordering that is the whole point.
@TestOn('vm')
library;

import 'package:odova/features/backup/application/delete_all_flow.dart';
import 'package:test/test.dart';

class _Ports implements DeleteAllPorts {
  _Ports({this.copyWorks = true, this.confirms = true});

  final bool copyWorks;
  final bool confirms;
  final List<DeleteAllStep> calls = [];

  @override
  Future<bool> writeWipeSafetyCopy() async {
    calls.add(DeleteAllStep.safetyCopy);
    return copyWorks;
  }

  @override
  Future<bool> confirm() async {
    calls.add(DeleteAllStep.confirm);
    return confirms;
  }

  @override
  Future<void> wipe() async => calls.add(DeleteAllStep.wipe);

  @override
  Future<void> cancelNotifications() async =>
      calls.add(DeleteAllStep.cancelNotifications);

  @override
  Future<void> routeToFirstRun() async =>
      calls.add(DeleteAllStep.routeToFirstRun);
}

void main() {
  test('the safety copy is written BEFORE the dialog opens', () async {
    // The assertion this file exists for. A copy written after confirmation is
    // a copy that does not exist at the moment the user changes their mind
    // about having confirmed — which is the only moment it was ever for.
    final ports = _Ports();

    await runDeleteAll(ports);

    expect(ports.calls.first, DeleteAllStep.safetyCopy);
    expect(
      ports.calls.indexOf(DeleteAllStep.safetyCopy),
      lessThan(ports.calls.indexOf(DeleteAllStep.confirm)),
    );
  });

  test('a confirmed delete wipes, cancels, then routes', () async {
    final ports = _Ports();

    final ran = await runDeleteAll(ports);

    expect(ran, [
      DeleteAllStep.safetyCopy,
      DeleteAllStep.confirm,
      DeleteAllStep.wipe,
      DeleteAllStep.cancelNotifications,
      DeleteAllStep.routeToFirstRun,
    ]);
  });

  test('a cancelled dialog changes nothing', () async {
    final ports = _Ports(confirms: false);

    final ran = await runDeleteAll(ports);

    expect(ran, [DeleteAllStep.safetyCopy, DeleteAllStep.confirm]);
    // The copy stays. Not waste: the next tap reuses it, and a user who
    // cancelled once is a user who is thinking about it.
    expect(ports.calls, [DeleteAllStep.safetyCopy, DeleteAllStep.confirm]);
  });

  test('a copy that could not be written stops the flow', () async {
    // §6 §4.4 has no exceptions, and "delete everything, and by the way the
    // undo did not save" is not a thing to discover afterwards.
    final ports = _Ports(copyWorks: false);

    final ran = await runDeleteAll(ports);

    expect(ran, [DeleteAllStep.safetyCopy]);
    expect(ports.calls, isNot(contains(DeleteAllStep.confirm)));
    expect(ports.calls, isNot(contains(DeleteAllStep.wipe)));
  });

  test(
    'notifications are cancelled before the app leaves the screen',
    () async {
      // The OS holds ids for reminders that no longer exist, and routing first
      // would leave that window open for as long as the transition takes.
      final ports = _Ports();

      await runDeleteAll(ports);

      expect(
        ports.calls.indexOf(DeleteAllStep.cancelNotifications),
        lessThan(ports.calls.indexOf(DeleteAllStep.routeToFirstRun)),
      );
    },
  );
}
