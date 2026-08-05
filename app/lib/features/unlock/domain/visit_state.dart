/// How far a user has got with one checkpoint.
///
/// A missing record means [unknown]; the value exists so a checkpoint can be
/// recorded as glimpsed but not yet reached.
enum VisitStatus {
  /// Never seen. Not stored — absence of a record means this.
  unknown,

  /// Seen on the map but not reached. A faint dot with no name.
  revealed,

  /// Been there, proven. This is what every lens lights up.
  visited;

  /// Falls back to [unknown] rather than throwing, so a status added on the
  /// server cannot brick an older client.
  static VisitStatus parse(String value) {
    for (final status in VisitStatus.values) {
      if (status.name == value) return status;
    }
    return VisitStatus.unknown;
  }
}

/// How a visit was proven.
///
/// GPS is the normal path. The other two exist because District 1 has streets
/// where GPS is unreliable between tall buildings, and refusing a user who is
/// genuinely standing there would be the worst possible failure.
enum VerifyMethod {
  gps,
  qr,
  quiz;

  static VerifyMethod parse(String value) {
    for (final method in VerifyMethod.values) {
      if (method.name == value) return method;
    }
    return VerifyMethod.gps;
  }
}

/// One user's proven visit to one checkpoint.
///
/// **This is the foundation layer.** Every lens reads it and none of them
/// stores its own copy: a stamp is owned when its checkpoint is visited, a
/// quest step is done when its checkpoint is visited, fog lifts where its
/// checkpoint is visited. That is the whole product thesis — one arrival
/// unlocks every way of playing — and it only holds while this stays the
/// single record of the fact.
///
/// The client never mints one of these. They arrive from the server after a
/// check-in it verified.
class VisitState {
  const VisitState({
    required this.checkpointId,
    required this.status,
    required this.visitedAt,
    required this.verifiedBy,
  });

  final String checkpointId;
  final VisitStatus status;
  final DateTime visitedAt;
  final VerifyMethod verifiedBy;

  bool get isVisited => status == VisitStatus.visited;

  VisitState copyWith({
    String? checkpointId,
    VisitStatus? status,
    DateTime? visitedAt,
    VerifyMethod? verifiedBy,
  }) {
    return VisitState(
      checkpointId: checkpointId ?? this.checkpointId,
      status: status ?? this.status,
      visitedAt: visitedAt ?? this.visitedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitState &&
          other.checkpointId == checkpointId &&
          other.status == status &&
          other.visitedAt == visitedAt &&
          other.verifiedBy == verifiedBy;

  @override
  int get hashCode => Object.hash(checkpointId, status, visitedAt, verifiedBy);

  @override
  String toString() => 'VisitState($checkpointId, ${status.name})';
}
