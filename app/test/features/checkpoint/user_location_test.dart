import 'package:flutter_test/flutter_test.dart';
import 'package:wanderlock/features/checkpoint/domain/user_location.dart';

void main() {
  test('everything in place means the dot can be drawn', () {
    expect(
      locationAvailability(
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
      ),
      isA<LocationReady>(),
    );
  });

  test('a refusal that can be asked again is worth asking again', () {
    expect(
      locationAvailability(
        permission: LocationPermissionState.denied,
        serviceEnabled: true,
      ),
      isA<LocationNeedsPermission>(),
    );
  });

  // Asking again does nothing here — the system will not show the dialog. A
  // screen that offers "allow" would be offering a button that cannot work.
  test('a permanent refusal sends the user to settings instead', () {
    expect(
      locationAvailability(
        permission: LocationPermissionState.deniedForever,
        serviceEnabled: true,
      ),
      isA<LocationBlocked>(),
    );
  });

  test('permission without services is its own problem', () {
    expect(
      locationAvailability(
        permission: LocationPermissionState.granted,
        serviceEnabled: false,
      ),
      isA<LocationServiceOff>(),
    );
  });

  // Both obstacles at once. Permission wins because the dot stays hidden
  // either way, and the permission dialog is the one step that might finish
  // the job — sending the user to the device's location switch first would
  // cost them a trip and change nothing.
  test('permission is settled before the services switch', () {
    expect(
      locationAvailability(
        permission: LocationPermissionState.denied,
        serviceEnabled: false,
      ),
      isA<LocationNeedsPermission>(),
    );
    expect(
      locationAvailability(
        permission: LocationPermissionState.deniedForever,
        serviceEnabled: false,
      ),
      isA<LocationBlocked>(),
    );
  });

  // A missed case would compile as a runtime throw rather than an analyzer
  // error if the switch ever loses its exhaustiveness.
  test('every combination resolves to something', () {
    for (final permission in LocationPermissionState.values) {
      for (final serviceEnabled in [true, false]) {
        expect(
          locationAvailability(
            permission: permission,
            serviceEnabled: serviceEnabled,
          ),
          isA<LocationAvailability>(),
          reason: '$permission with serviceEnabled=$serviceEnabled',
        );
      }
    }
  });
}
