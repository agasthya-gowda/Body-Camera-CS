import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'screens/splash_screen.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Registers fvp as the video_player backend so VideoPlayerController can
  // play RTSP streams (the stock video_player has no RTSP support). Web has
  // no fvp implementation - RTSP can't play in a browser anyway.
  if (!kIsWeb) {
    fvp.registerWith();
  }
  await ThemeController.instance.load();
  runApp(const BWCApp());
}

class BWCApp extends StatelessWidget {
  const BWCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      controller: ThemeController.instance,
      child: MaterialApp(
        title: 'BWC Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3A6B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
