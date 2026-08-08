import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanderlock/features/checkpoint/data/device_location.dart';
import 'package:wanderlock/features/checkpoint/domain/user_location.dart';

final deviceLocationProvider = Provider<DeviceLocation>(
  (ref) => const DeviceLocation(),
);

/// Whether the map is currently keeping the user's dot centred.
///
/// Separate from [LocationAvailability] because the two answer different
/// questions. Availability is what the operating system allows; this is what
/// the user last asked for. Losing permission must not silently rewrite their
/// preference, and regaining it must not silently start moving the map.
enum CameraFollow { off, following }

/// Reads the permission and services situation, and holds what it found.
///
/// Nothing is asked for on first build. A permission dialog that appears
/// because a screen was opened teaches the user to dismiss it; this waits
/// until they press the button that needs it.
class UserLocationController extends AsyncNotifier<LocationAvailability> {
  @override
  Future<LocationAvailability> build() => _read();

  Future<LocationAvailability> _read() async {
    final device = ref.read(deviceLocationProvider);
    return locationAvailability(
      permission: await device.currentPermission(),
      serviceEnabled: await device.isServiceEnabled(),
    );
  }

  /// Re-reads the situation. Worth calling when the app comes back to the
  /// foreground: the user may have just changed it in Settings.
  Future<void> refresh() async {
    state = AsyncValue.data(await _read());
  }

  /// Shows the system dialog and records whatever comes back.
  ///
  /// Returns true only if the map can now draw the dot, so the caller can
  /// decide whether to start following without re-reading the state.
  Future<bool> requestPermission() async {
    final device = ref.read(deviceLocationProvider);
    await device.requestPermission();
    final availability = await _read();
    state = AsyncValue.data(availability);
    return availability is LocationReady;
  }

  Future<void> openAppSettings() =>
      ref.read(deviceLocationProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(deviceLocationProvider).openLocationSettings();
}

final userLocationProvider =
    AsyncNotifierProvider<UserLocationController, LocationAvailability>(
      UserLocationController.new,
    );

/// What the camera is doing, kept apart from the map widget so a rebuild does
/// not reset it.
class CameraFollowController extends Notifier<CameraFollow> {
  @override
  CameraFollow build() => CameraFollow.off;

  void follow() => state = CameraFollow.following;

  /// Called both by the button and by the map itself, which reports when a
  /// drag has taken the camera off the user's location. Without that second
  /// path the button would keep claiming to follow while the map sat still.
  void stop() => state = CameraFollow.off;
}

final cameraFollowProvider =
    NotifierProvider<CameraFollowController, CameraFollow>(
      CameraFollowController.new,
    );
