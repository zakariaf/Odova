/// Shared fakes.
///
/// What belongs here: fake repositories, fake service ports, fake DAOs —
/// anything on the far side of a boundary the app injects across, so a test
/// can hand one to `pumpApp(overrides: ...)` in a line.
///
/// What does not: a faked `Notifier`. A `Notifier` is the thing under test; a
/// test that replaces one is a test of nothing. Fake what the Notifier talks
/// to instead.
///
/// Empty until the persistence epic gives it something real to stand in for.
library;
