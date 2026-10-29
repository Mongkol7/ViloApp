import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'features/shop/models/product.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Product.loadPersistedInventoryOverrides();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER_ERROR] ${details.exceptionAsString()}');
    debugPrint('[FLUTTER_ERROR] ${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PLATFORM_ERROR] $error');
    debugPrint('[PLATFORM_ERROR] $stack');
    return true;
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ViloApp());
}
