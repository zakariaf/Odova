import 'package:flutter/widgets.dart';

/// A zero-size widget that hands its [BuildContext] to [onContext].
///
/// The only way to read `Directionality.of`, `Theme.of` or
/// `AppLocalizations.of` as the app itself sees them: from inside the scopes
/// the app builds, not from the test's own context above them.
Widget captureContext(void Function(BuildContext context) onContext) {
  return Builder(
    builder: (context) {
      onContext(context);
      return const SizedBox.shrink();
    },
  );
}
