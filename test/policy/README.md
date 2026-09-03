# `test/policy` — the cross-cutting greps

Tests whose subject is a decision recorded in a file rather than a Dart API:
the toolchain pins, the platform floors, the lint config, the shape of `lib/`,
the CI workflow. They are cheap, they run with the rest of the suite, and they
are the only thing that keeps a rule true twelve epics after it was written.
