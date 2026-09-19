import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/features/unlock/application/visit_state_providers.dart';
import 'package:wanderlock/features/unlock/domain/check_in_service.dart';

/// Runs a check-in and remembers what came back.
///
/// The screen never calls the service directly and never inspects the outcome
/// to decide whether something is unlocked: it asks for a check-in, and reads
/// what is unlocked from [visitStateProvider] like every other lens. That is
/// what keeps "one arrival, every way of playing" true — the unlock moment is
/// a reaction to the shared state changing, not a separate truth the screen
/// holds while it animates.
class CheckInController extends Notifier<CheckInState> {
  @override
  CheckInState build() => const CheckInState.idle();

  Future<void> checkIn({
    required String checkpointId,
    required double latitude,
    required double longitude,
  }) async {
    if (state.isInFlight) return;
    state = CheckInState(checkpointId: checkpointId, isInFlight: true);

    final outcome = await ref
        .read(checkInServiceProvider)
        .checkIn(
          checkpointId: checkpointId,
          latitude: latitude,
          longitude: longitude,
        );

    // Only a grant touches the unlock layer, and it stores what the authority
    // returned rather than anything assembled here.
    if (outcome is CheckInGranted) {
      await ref.read(visitStateRepositoryProvider).cacheGranted(outcome.visit);
    }

    state = CheckInState(checkpointId: checkpointId, outcome: outcome);
  }

  /// Records that the app had no position to send, without sending anything.
  ///
  /// Not a refusal by the authority — nobody was asked — so it reuses the
  /// outcome that means exactly that.
  void reportNoFix(String checkpointId) {
    state = CheckInState(
      checkpointId: checkpointId,
      outcome: const CheckInUnavailable(),
    );
  }

  /// Clears the last answer once the screen has finished showing it.
  void acknowledge() => state = const CheckInState.idle();
}

/// The last check-in asked for, and what the authority said about it.
class CheckInState {
  const CheckInState({
    required this.checkpointId,
    this.outcome,
    this.isInFlight = false,
  });

  const CheckInState.idle()
    : checkpointId = null,
      outcome = null,
      isInFlight = false;

  final String? checkpointId;
  final CheckInOutcome? outcome;
  final bool isInFlight;

  bool get isGranted => outcome is CheckInGranted;
}

final checkInControllerProvider =
    NotifierProvider<CheckInController, CheckInState>(CheckInController.new);
