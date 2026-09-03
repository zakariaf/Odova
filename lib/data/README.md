# `lib/data` — storage and repositories

**Owner:** everything that reads or writes bytes. **Skills:** `persistence-drift`,
`data-export-and-restore`, `error-handling-typed-results`.

The drift schema, its migrations, the DAOs, the repositories that hand
`lib/core` types to the rest of the app, and the backup reader and writer.

`SPEC.md` §2: storage is canonical — integer metres, millilitres, watt-hours,
grams and minor currency units. Conversion happens on read, in `lib/core`, and
never on the way in.
