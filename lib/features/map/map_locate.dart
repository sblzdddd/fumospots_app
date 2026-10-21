import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:maplibre/maplibre.dart';

/// Location permission + map tracking helpers.
class MapLocate {
  bool enabled = false;

  /// MapLibre Android's permission Future can hang after the system dialog
  /// (JNI listener released before the callback). Poll + resume instead.
  Future<bool> ensurePermission({
    String explanation = 'Show your current location on the map.',
  }) async {
    if (!PermissionManager.isSupported) {
      return true;
    }

    final permissions = PermissionManager();
    if (permissions.locationPermissionsGranted) {
      return true;
    }

    final done = Completer<bool>();
    void finish() {
      if (!done.isCompleted) {
        done.complete(permissions.locationPermissionsGranted);
      }
    }

    final lifecycle = AppLifecycleListener(onResume: finish);
    try {
      unawaited(
        permissions
            .requestLocationPermissions(explanation: explanation)
            .then((granted) {
              if (!done.isCompleted) {
                done.complete(granted);
              }
            })
            .catchError((Object _) {
              finish();
              return false;
            }),
      );

      unawaited(() async {
        for (var i = 0; i < 150 && !done.isCompleted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (permissions.locationPermissionsGranted) {
            finish();
            return;
          }
        }
        finish();
      }());

      return await done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => permissions.locationPermissionsGranted,
      );
    } finally {
      lifecycle.dispose();
    }
  }

  Future<String?> goToMyLocation(MapController map) async {
    if (!MapController.userLocationIsSupported) {
      return 'Location is not supported on this device.';
    }

    final granted = await ensurePermission();
    if (!granted) {
      return 'Location permission is required.';
    }

    if (!enabled) {
      await map.enableLocation(pulse: true);
      enabled = true;
    }
    await map.trackLocation(trackLocation: true);
    return null;
  }

  void reset() {
    enabled = false;
  }
}
