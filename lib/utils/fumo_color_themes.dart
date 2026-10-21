import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class FumoColorThemes {
  late TextTheme textTheme;

  // constructor
  FumoColorThemes(BuildContext context) {
    textTheme = TextTheme(
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24,
      ),
      bodyMedium: GoogleFonts.notoSansSc(
        fontSize: 16,
      ),
    );
  }

  ThemeData buildLightTheme(Color seedColor) {
    ColorScheme baseLightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    // Create custom light color scheme with darker background and white containers
    // with ref to: Today
    ColorScheme lightColorScheme = baseLightColorScheme.copyWith(
      surface: Color.lerp(
        const Color.fromARGB(248, 248, 248, 248),
        seedColor,
        0.04,
      )!,
      surfaceContainer: Color.lerp(Colors.white, seedColor, 0.01)!,
      surfaceContainerHigh: Color.lerp(Colors.white, seedColor, 0.005)!,
      surfaceContainerHighest: Color.lerp(Colors.white, seedColor, 0.02)!,
      surfaceContainerLow: Color.lerp(
        const Color(0xF8F8F8F8),
        seedColor,
        0.02,
      )!,
      surfaceContainerLowest: Color.lerp(
        const Color(0xF6F6F6F6),
        seedColor,
        0.04,
      )!,
      surfaceBright: Color.lerp(Colors.white, seedColor, 0.02)!,
    );

    return ThemeData(
      colorScheme: lightColorScheme,
      textTheme: textTheme.apply(
        bodyColor: lightColorScheme.onSurface,
        displayColor: lightColorScheme.onSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 1.0,
        highlightElevation: 4.0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        menuPadding: EdgeInsets.zero,
        elevation: 1.0,
      ),
    );
  }

  ThemeData buildDarkTheme(Color seedColor) {
    ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: darkColorScheme,
      textTheme: textTheme.apply(
        bodyColor: darkColorScheme.onSurface,
        displayColor: darkColorScheme.onSurface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        menuPadding: EdgeInsets.zero,
      ),
    );
  }
}
