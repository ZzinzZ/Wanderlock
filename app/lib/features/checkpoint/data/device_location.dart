import 'package:geolocator/geolocator.dart';

import 'package:wanderlock/features/checkpoint/domain/user_location.dart';

/// The edge between the operating system's idea of location permission and
/// ours.
///
/// Everything package-specific stops here. `domain/` has its own
/// [LocationPermissionState] and never sees geolocator's, so replacing the
/// package later is a change to this file and nothing else.
class DeviceLocation {
  const DeviceLocation();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermissionState> currentPermission() async =>
      _map(await Geolocator.checkPermission());

  /// Shows the system dialog, if the system is still willing to show it.
  ///
  /// Returns the state afterwards, which may still be a refusal — asking is
  /// not the same as being granted, and the caller has to handle both.
  Future<LocationPermissionState> requestPermission() async =>
      _map(await Geolocator.requestPermission());

  /// One position fix, or null if the device could not produce one in time.
  ///
  /// Null rather than an exception because every caller has the same answer to
  /// every failure — permission, timeout, hardware — which is to say that we
  /// do not know where the user is and must not guess.
  ///
  /// The timeout matters more than it looks: without one, a first fix indoors
  /// can hang for minutes behind a button the user already pressed.
  Future<UserPosition?> currentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        // Accuracy is left at the package default of `best`. Naming it
        // explicitly reads as a decision and trips the redundant-argument
        // lint; the decision worth recording is the time limit.
        locationSettings: const LocationSettings(
          // design-token-ignore: a GPS timeout is not a design value
          timeLimit: Duration(seconds: 12),
        ),
      );
      return UserPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } on Object {
      return null;
    }
  }

  /// Opens the app's own settings page, the only way back from
  /// [LocationPermissionState.deniedForever].
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device's location settings, for when services are switched off
  /// device-wide.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static LocationPermissionState _map(LocationPermission permission) =>
      switch (permission) {
        // `denied` covers "never asked" too — the platform does not tell them
        // apart, and the next step is the same for both.
        LocationPermission.denied => LocationPermissionState.denied,
        LocationPermission.deniedForever =>
          LocationPermissionState.deniedForever,
        // Coarse location still puts the dot on the map. Precision is
        // check-in's problem, which is F4 with S3's numbers behind it.
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationPermissionState.granted,
        // Web-only, and it means unknown rather than allowed. Treated as not
        // granted so the app asks instead of assuming.
        LocationPermission.unableToDetermine => LocationPermissionState.denied,
      };
}
