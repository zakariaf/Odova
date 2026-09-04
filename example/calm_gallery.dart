// The runnable specimen sheet.
//
// `flutter run -t example/calm_gallery.dart`, then open design/calm/system.html
// beside it. The golden matrix pins what the library IS; this is how a person
// finds out whether that is what it should be — type weight, icon shape and
// optical alignment are not things a pixel comparison can judge.
//
// It reads the same list the goldens do, so a state cannot be added to one and
// forgotten in the other.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

import '../test/ui/calm/support/specimens.dart';

void main() {
  runApp(const ProviderScope(retry: noProviderRetry, child: _Gallery()));
}

class _Gallery extends StatefulWidget {
  const _Gallery();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  ThemeMode _mode = ThemeMode.light;
  Locale _locale = const Locale('en');

  bool get _rtl => _locale.languageCode != 'en';

  @override
  Widget build(BuildContext context) {
    return OdovaApp(
      themeMode: _mode,
      locale: _locale,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Builder(
              builder: (context) {
                final colors = CalmColors.of(context);
                final space = CalmSpace.of(context);
                final type = CalmType.of(context);

                return ColoredBox(
                  color: colors.bg,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.all(space.s4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Calm specimens',
                                  style: type.title.copyWith(color: colors.ink),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _mode = _mode == ThemeMode.light
                                      ? ThemeMode.dark
                                      : ThemeMode.light,
                                ),
                                icon: const Icon(Icons.brightness_6_outlined),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _locale = _rtl
                                      ? const Locale('en')
                                      : const Locale('fa'),
                                ),
                                icon: const Icon(
                                  Icons.format_textdirection_r_to_l,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsetsDirectional.all(space.s5),
                            children: [
                              for (final specimen in calmSpecimens()) ...[
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    top: space.s7,
                                    bottom: space.s3,
                                  ),
                                  child: Text(
                                    specimen.name,
                                    style: type.caption.copyWith(
                                      color: colors.ink2,
                                      fontWeight: type.semi,
                                    ),
                                  ),
                                ),
                                for (final child in specimen.build(rtl: _rtl))
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      bottom: space.s4,
                                    ),
                                    child: child,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
