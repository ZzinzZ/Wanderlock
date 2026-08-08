/// What the operating system last said about our permission to read location.
///
/// Our own enum rather than the location package's, because `domain/` depends
/// on plain Dart only. Mapping happens at the edge, in `data/`, which also
/// means swapping the package later is a change in one file.
/// There is deliberately no "never asked" value. The platform APIs do not
/// distinguish it from a refusal, and the app would do the same thing either
/// way: show the system dialog and see what comes back.
enum LocationPermissionState {
  /// Not granted, but the system will still show the dialog if asked.
  denied,

  /// Refused for good. Asking again does nothing — only Settings can undo it.
  deniedForever,

  /// Granted, at whatever precision the user chose.
  granted,
}

/// What the map can actually do about showing where the user is, and what the
/// screen should therefore offer them.
sealed class LocationAvailability {
  const LocationAvailability();
}

/// Everything is in place. Draw the dot.
class LocationReady extends LocationAvailability {
  const LocationReady();
}

/// Worth asking for permission — the system dialog will appear.
class LocationNeedsPermission extends LocationAvailability {
  const LocationNeedsPermission();
}

/// Permission is refused for good. The only way out is app settings, so the
/// screen must send them there rather than pop a dialog that never appears.
class LocationBlocked extends LocationAvailability {
  const LocationBlocked();
}

/// Permission is granted but location services are switched off device-wide.
/// A different problem with a different fix, and telling the user to grant
/// permission here would send them somewhere that already says "allowed".
class LocationServiceOff extends LocationAvailability {
  const LocationServiceOff();
}

/// Works out which of the four situations the device is in.
///
/// Permission is settled before the services switch, deliberately. A user who
/// has not granted permission gains nothing from being told to turn location
/// services on: the dot stays hidden either way, and the permission dialog is
/// the one step that might actually finish the job. Once permission is in
/// hand, the services switch becomes the real remaining obstacle and is worth
/// naming.
LocationAvailability locationAvailability({
  required LocationPermissionState permission,
  required bool serviceEnabled,
}) => switch (permission) {
  LocationPermissionState.deniedForever => const LocationBlocked(),
  LocationPermissionState.denied => const LocationNeedsPermission(),
  LocationPermissionState.granted when !serviceEnabled =>
    const LocationServiceOff(),
  LocationPermissionState.granted => const LocationReady(),
};
