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
