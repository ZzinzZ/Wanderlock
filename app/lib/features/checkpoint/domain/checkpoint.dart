/// What a checkpoint is classified as. Drives marker colour and grouping.
///
/// Persisted by name, never by index — see `CheckpointRows.category`.
enum CheckpointCategory {
  museum,
  monument,
  market,
  religious,
  architecture,
  street;

  /// Falls back to [street] rather than throwing: a category added on the
  /// server must not brick an older client that has not shipped it yet.
  static CheckpointCategory parse(String value) {
    for (final category in CheckpointCategory.values) {
      if (category.name == value) return category;
    }
    return CheckpointCategory.street;
  }
}

/// A place that can be unlocked by going there.
///
/// Pure content: it says nothing about whether *this* user has been. That
/// belongs to `VisitState` in the unlock feature, and keeping the two apart is
/// what stops a lens from caching its own idea of what is unlocked.
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.category,
    this.requiresQrFallback = false,
    this.address,
    this.photoUrl,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// How close a user must be for a check-in to be considered. Advisory on the
  /// client — the server decides. Set per place because a wide plaza and a
  /// narrow temple gate do not deserve the same radius.
  final int radiusMeters;

  final CheckpointCategory category;

  /// True where the S3 field survey found GPS unreliable, typically between
  /// tall buildings. The client should offer the QR fallback up front rather
  /// than after a user has failed to check in.
  final bool requiresQrFallback;

  final String? address;
  final String? photoUrl;

  Checkpoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    CheckpointCategory? category,
    bool? requiresQrFallback,
    String? address,
    String? photoUrl,
  }) {
    return Checkpoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      category: category ?? this.category,
      requiresQrFallback: requiresQrFallback ?? this.requiresQrFallback,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Checkpoint &&
          other.id == id &&
          other.name == name &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.radiusMeters == radiusMeters &&
          other.category == category &&
          other.requiresQrFallback == requiresQrFallback &&
          other.address == address &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    category,
    requiresQrFallback,
    address,
    photoUrl,
  );

  @override
  String toString() => 'Checkpoint($id, $name)';
}
