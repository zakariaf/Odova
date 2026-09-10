# docs/

Images the repository's own `README.md` shows. Nothing here is used by the app,
and nothing here is a source of truth.

| | |
|---|---|
| `icon.png` | A copy of the 1024 marketing icon, which is generated into the iOS asset catalogue by [`design/icon/generate.py`](../design/icon/generate.py) from the Calm tokens. |
| `screenshots/` | Four of the App Store captures in [`store/screenshots/`](../store/README.md), scaled to 440 px so the landing page loads in kilobytes rather than megabytes. |

**These are copies, and the originals are the ones that ship.** The icon is
gated against `--color-brand` by `test/policy/app_icon_test.dart`, and the store
set by `test/policy/store_screenshots_test.dart`; neither gate looks here. If
the app's look changes, regenerate the originals first and then re-scale:

```bash
python3 design/icon/generate.py
bash tools/capture_store_screenshots.sh          # needs a booted simulator
cp ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png docs/icon.png
for pair in en/1-home:home-en en/2-reminders:reminders-en \
            fa/1-home:home-fa ckb/2-reminders:reminders-ckb; do
  src=${pair%%:*}; dst=${pair##*:}
  sips -Z 440 "store/screenshots/${src%/*}/6.9-inch/${src#*/}.png" \
    --out "docs/screenshots/$dst.png"
done
```

The four were chosen to show the two things the README claims and a reader would
otherwise take on trust: that the home screen answers one question, and that
right-to-left is a first-class target rather than a port — hence Persian with
Jalali dates and Eastern Arabic numerals, and Sorani with its own reminder names.
