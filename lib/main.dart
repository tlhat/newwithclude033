import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:haneen_kids_vod/app/app_initializer.dart';
export 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Any uncaught Dart error is swallowed here so a failure on one phone brand
/// (audio, storage, native plugin) never closes the app.
Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails d) {
    FlutterError.dumpErrorToConsole(d);
  };
  PlatformDispatcher.instance.onError = (Object e, StackTrace st) => true;
  await runZonedGuarded<Future<void>>(
    () => AppInitializer.initializeAndRun(),
    (Object e, StackTrace st) {},
  );
}
