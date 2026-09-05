// The UI-state store as a provider, and the notifier screens actually read.
//
// The STORE is built by `bootstrap()` and injected, like the database: it opens
// a file, which is asynchronous work a synchronous provider cannot do. The
// NOTIFIER is what a screen watches, so a dismissal redraws the screen that
// dismissed it rather than waiting for something else to rebuild.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';

/// The local key-value store.
///
/// The default is IN MEMORY, not a file. A widget test that never touched
/// `bootstrap()` still gets a working store, and the production path is
/// asserted by `bootstrap_launch_test.dart` rather than assumed — the
/// alternative, throwing until overridden, would make every existing harness
/// carry an override for a banner nobody in it dismisses.
final uiStateProviderStore = Provider<UiStateStore>(
  (ref) => UiStateStore.inMemory(),
);

/// Local UI state, as a map a screen can read synchronously.
class UiState extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => ref.watch(uiStateProviderStore).snapshot;

  /// Writes [key] and redraws whoever is watching.
  Future<void> set(String key, String value) async {
    await ref.read(uiStateProviderStore).write(key, value);
    state = ref.read(uiStateProviderStore).snapshot;
  }

  /// Removes [key].
  Future<void> clear(String key) async {
    await ref.read(uiStateProviderStore).remove(key);
    state = ref.read(uiStateProviderStore).snapshot;
  }
}

/// What Home reads to decide whether a strip was dismissed.
final NotifierProvider<UiState, Map<String, String>> uiStateProvider =
    NotifierProvider<UiState, Map<String, String>>(UiState.new);
