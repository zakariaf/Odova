# Store listing sources

One directory per locale, one file per App Store Connect field. Nothing here is
uploaded automatically — Task 19.10 transcribes it and then **reads the store
back**, because a committed folder is not an uploaded listing.

| File | App Store Connect field | Limit |
|---|---|---|
| `name.txt` | App Name | 30 characters |
| `subtitle.txt` | Subtitle | 30 characters |
| `promotional_text.txt` | Promotional Text | 170 characters |
| `description.txt` | Description | 4000 characters |
| `keywords.txt` | Keywords (comma-separated, no spaces after commas) | 100 characters |
| `whats_new.txt` | What's New in This Version | 4000 characters |

Limits are in **characters**, not bytes. `test/policy/store_listing_test.dart`
measures them that way: Persian, Arabic and Sorani are multi-byte throughout and
would pass a byte check while failing the upload.

## Screenshots

`store/screenshots/<locale>/<display>/` — captured from the simulator by
`tools/capture_store_screenshots.sh`. The display folders are named for the
device class App Store Connect asks for, not for the simulator model.

## The copy itself

Written, not machine-translated, to the same bar as the app's own strings: no
concatenation, no absolute privacy claim (see `store/privacy-answers.md` and
`test/policy/privacy_claims_test.dart`), and the same register the app uses —
Sie in German, vous in French.

**Sorani has not been read by a native speaker.** SPEC.md §18.11 names that as
the largest single risk to the RTL launch, and it is still open. The text here
is the same shape as the other five and should be reviewed before submission,
not after.
