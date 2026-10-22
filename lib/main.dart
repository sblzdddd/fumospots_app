import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/locator.dart';
import 'features/auth/auth_controller.dart';
import 'features/home/main_screen.dart';
import 'features/settings/theme_controller.dart';
import 'features/settings/visual_settings_controller.dart';
import 'utils/fumo_color_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RendererBinding.instance.ensureSemantics();
  await dotenv.load(fileName: '.env');
  setupDI();
  await Future.wait([
    getIt<ThemeController>().init(),
    getIt<VisualSettingsController>().init(),
  ]);
  getIt<AuthController>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeController>();
    final colorThemes = FumoColorThemes(context);

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Fumospots',
          theme: colorThemes.buildLightTheme(const Color(0xFF31a567)),
          darkTheme: colorThemes.buildDarkTheme(const Color(0xFF31a567)),
          themeMode: themeController.mode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
