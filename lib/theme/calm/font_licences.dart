import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the licences of every font Odova bundles.
///
/// SIL OFL 1.1 requires the licence to travel with the font. Flutter's built-in
/// licences page reads [LicenseRegistry], so this is the difference between
/// honouring that obligation and shipping a font with its licence stripped.
///
/// Called from `bootstrap()` before `runApp`. [LicenseRegistry.addLicense]
/// takes a stream factory and is lazy, so the file is only read if somebody
/// opens the licences page — this costs nothing at startup.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Vazirmatn'],
      await rootBundle.loadString('assets/fonts/OFL.txt'),
    );
  });
}
