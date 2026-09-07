// The backup file's shape, as constants.
//
// SPEC.md §6: "the backup is plain, unencrypted JSON with English `snake_case`
// keys regardless of app language" — because a backup that only opens on a
// Persian-locale device is not a backup. The person who needs this file is
// standing in a phone shop with a dead handset; the file has to be readable by
// them, by a text editor, and by a version of this app they have not installed
// yet.

/// The `format` field's only legal value.
///
/// A NAMESPACE, not "backup": the share sheet hands `.json` files to anything,
/// and a reader that accepts any JSON document with the right-looking keys
/// will one day be handed a different app's export.
const String kBackupFormat = 'odova.backup';

/// The format version this build reads and writes.
///
/// EPIC-15 owns it; `settings.about` reads it. It was declared in
/// `lib/app/app_version.dart` while this epic was pending, and that
/// declaration now points here — two copies is how the number on the About
/// screen and the number inside the file drift apart, which is a support
/// conversation nobody can resolve.
const int kSupportedFormatVersion = 1;

/// The units every figure in the file is in.
///
/// Written out rather than assumed, because §3's canonical integers are the
/// whole reason the file is safe to read in ten years: `odometer_m` is metres
/// and says so, and a reader that guessed would guess wrong exactly once.
const Map<String, String> kBackupUnits = {
  'distance': 'm',
  'volume': 'ml',
  'mass': 'g',
  'energy': 'wh',
  'money': 'minor',
};

/// The fields in the file that are DERIVED and will be recomputed on import.
///
/// Listed in the envelope so a reader knows not to trust them, and written
/// anyway so a human opening the file can see what the app concluded. §1
/// forbids persisting a derived value in the DATABASE; a backup is a snapshot
/// and may carry one as long as it says so.
const List<String> kDerivedFields = [
  'reminders.last_done_date',
  'reminders.last_done_odometer_m',
  'reminders.last_done_service_id',
];

/// The arrays, in the order they are written.
///
/// PARENTS BEFORE CHILDREN, and §6 §2.6 makes a streaming reader's one-pass
/// reference resolution depend on it: a `fillup` naming a `vehicle_id` can be
/// resolved the moment it is read, without holding the whole document.
const List<String> kBackupArrays = [
  'vehicles',
  'reminders',
  'odometer_readings',
  'odometer_corrections',
  'fillups',
  'services',
  'expenses',
  'trips',
];

/// The envelope's keys, in the order they are written.
///
/// Order is part of the format. §6 §2.6 lets a reader validate the envelope
/// and refuse a wrong-format or wrong-version file before parsing a single
/// record — which is what makes a 12,000-record file cheap to reject.
const List<String> kEnvelopeKeys = [
  'format',
  'format_version',
  'app_version',
  'app_build',
  'platform',
  'exported_at',
  'exported_at_local',
  'units',
  'derived_fields',
  'record_counts',
  'content_hash',
];

/// The `content_hash` placeholder: `sha256:` and 64 zeros.
///
/// Written first, then overwritten IN PLACE with the real digest. The length
/// is identical, so no byte offset shifts and the hash covers the document it
/// is actually in — a hash computed over a shorter document and then inserted
/// would describe a file that never existed.
const String kContentHashPlaceholder =
    'sha256:0000000000000000000000000000000000000000000000000000000000000000';
