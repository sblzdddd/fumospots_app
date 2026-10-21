import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:progressive_blur/progressive_blur.dart';

import 'core/di/locator.dart';
import 'features/auth/auth_controller.dart';
import 'features/home/main_screen.dart';
import 'utils/fumo_color_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RendererBinding.instance.ensureSemantics();
  await dotenv.load(fileName: '.env');
  await ProgressiveBlurWidget.precache();
  setupDI();
  getIt<AuthController>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FumoColorThemes colorThemes = FumoColorThemes(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: colorThemes.buildLightTheme(Color(0xFF31a567)),
      darkTheme: colorThemes.buildDarkTheme(Color(0xFF31a567)),
      // preserve text dpi scale
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const MainScreen(title: 'FUMOSPOTS'),
    );
  }
}
