import 'ride.dart';

/// État (statut + verrouillage des adhésions).
class RideState {
  const RideState(this.status, {this.joinsLocked = false});

  final RideStatus status;
  final bool joinsLocked;

  @override
  bool operator ==(Object other) =>
      other is RideState &&
      other.status == status &&
      other.joinsLocked == joinsLocked;

  @override
  int get hashCode => Object.hash(status, joinsLocked);

  @override
  String toString() => '${status.dbValue}${joinsLocked ? '+locked' : ''}';
}

/// Miroir exact de `private.ride_transition` (SQL), utilisé pour proposer
/// uniquement les actions possibles. Le serveur reste l'autorité.
abstract final class RideStateMachine {
  /// Nouvel état, ou `null` si la transition est interdite.
  static RideState? next(RideState state, RideAction action) {
    final s = state.status;
    final locked = state.joinsLocked;
    switch (action) {
      case RideAction.publish:
        return s == RideStatus.draft
            ? const RideState(RideStatus.published)
            : null;
      case RideAction.lock:
        if (s == RideStatus.published) {
          return const RideState(RideStatus.locked, joinsLocked: true);
        }
        if (s == RideStatus.inProgress && !locked) {
          return const RideState(RideStatus.inProgress, joinsLocked: true);
        }
        return null;
      case RideAction.unlock:
        if (s == RideStatus.locked) {
          return const RideState(RideStatus.published);
        }
        if (s == RideStatus.inProgress && locked) {
          return const RideState(RideStatus.inProgress);
        }
        return null;
      case RideAction.start:
        if (s == RideStatus.published || s == RideStatus.locked) {
          return RideState(
            RideStatus.inProgress,
            joinsLocked: s == RideStatus.locked,
          );
        }
        return null;
      case RideAction.finish:
        return s == RideStatus.inProgress
            ? const RideState(RideStatus.finished)
            : null;
      case RideAction.cancel:
        return const {
              RideStatus.published,
              RideStatus.locked,
              RideStatus.inProgress,
            }.contains(s)
            ? const RideState(RideStatus.cancelled)
            : null;
    }
  }

  static List<RideAction> availableActions(RideState state) => [
    for (final action in RideAction.values)
      if (next(state, action) != null) action,
  ];

  /// Miroir de `private.ride_accepts_participants`.
  static bool acceptsParticipants(RideState state) =>
      state.status == RideStatus.published ||
      (state.status == RideStatus.inProgress && !state.joinsLocked);

  /// Les détails sont modifiables avant le départ uniquement.
  static bool isEditable(RideStatus status) => const {
    RideStatus.draft,
    RideStatus.published,
    RideStatus.locked,
  }.contains(status);
}

extension RideStateX on Ride {
  RideState get state => RideState(status, joinsLocked: joinsLocked);

  bool get acceptsParticipants => RideStateMachine.acceptsParticipants(state);
}
