
---

## Verified on a device, 2026-09-08

Rebuilt and re-run on the Pixel 8a emulator (Android 15) and the iPhone 16 Pro
simulator (iOS 18), from a fresh install through first run.

| | Was | Now |
|---|---|---|
| A-2 save error | every unclassified failure said "out of space" | a refusal names its own reason: "That reading is lower than the one before it" |
| A-1 save | reported a full disk | **saves** — History shows the row, the recompute and reschedule run |
| B-1 sheet bottom | last row under the home indicator | clear space below it |
| B-3 sheet grip | a line across the whole sheet | the 44pt centred pill `.sheet__grip` specifies |
| B-2 More sheet | opened empty on three forms | not offered where it has nothing behind it |
| C-1 tab bar | About unreachable on `settings` | About fully visible above the bar |
| D-1 dark mode | tapping Dark did nothing | the whole app repaints, and the choice survives |
| D-2 permission | no OS dialog, ever | **"Allow Odova to send you notifications?"**, and Notifications flips Off → On |
| D-3 service chips | `+ Other` only | the catalogue, named |
| E-1 names | seven rows reading "Service" | Oil and filter, Brake pad check, Inspection, Insurance renewal, Air filter, New tyres, Coolant |

**Still open.** A-3, the Fuel field showing `0` after `10` was typed, did not
reproduce: the trio holds `10` in every test, including the odometer-blur-fuel
sequence the device was in. It needs the value off a device that is in that
state, not another guess.

**The More section for `service` and `expense` is a feature, not a fix.**
`ServiceRecord` has `vendor`, `invoiceRef` and `notes` and the modal collects
none of them; `ExpenseDraft` has no such fields at all. The row is hidden rather
than lying, and `log_more_sheet.dart` says in the code what building it needs.
