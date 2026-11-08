import 'package:flutter/material.dart';
import 'package:rtchat/models/layout.dart';

/// Shared cockpit palette. Transitions are short, with no permanent animations.
class Themes {
  static final _cache = <(InterfaceTheme, Brightness), ThemeData>{};
  static ThemeData lightFor(InterfaceTheme palette) => _cache.putIfAbsent((
    palette,
    Brightness.light,
  ), () => _theme(Brightness.light, palette));
  static ThemeData darkFor(InterfaceTheme palette) => _cache.putIfAbsent((
    palette,
    Brightness.dark,
  ), () => _theme(Brightness.dark, palette));
  static ThemeData _theme(Brightness brightness, InterfaceTheme palette) {
    final colors = interfaceColors[palette]!;
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ).copyWith(
      primary:
          dark
              ? colors.accent
              : ColorScheme.fromSeed(
                seedColor: colors.accent,
                brightness: brightness,
              ).primary,
      onPrimary: dark ? const Color(0xff091017) : Colors.white,
      secondary: dark ? const Color(0xffffc279) : const Color(0xff895219),
      surface:
          dark
              ? colors.surface
              : Color.alphaBlend(
                colors.accent.withValues(alpha: .035),
                const Color(0xfff8f9fb),
              ),
      onSurface: dark ? const Color(0xfff0f6ff) : const Color(0xff102035),
      outline: dark ? colors.outline : const Color(0xff7c909f),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope',
    );
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: scheme.outline.withValues(alpha: .45)),
    );
    return base.copyWith(
      scaffoldBackgroundColor:
          dark
              ? colors.background
              : Color.alphaBlend(
                colors.accent.withValues(alpha: .08),
                const Color(0xfff3f5f7),
              ),
      textTheme: base.textTheme.copyWith(
        bodyMedium: base.textTheme.bodyMedium!.copyWith(
          height: 1.42,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: base.textTheme.titleLarge!.copyWith(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        ),
        titleMedium: base.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w800,
        ),
        labelLarge: base.textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? colors.surface : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: .35)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? colors.card : Colors.white,
        shape: border,
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          backgroundColor: dark ? colors.card : Colors.white,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? colors.raised : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: scheme.primary.withValues(alpha: .22),
        side: BorderSide(color: scheme.outline.withValues(alpha: .6)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: .25),
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }

  static final lightTheme = lightFor(InterfaceTheme.ciano);
  static final darkTheme = darkFor(InterfaceTheme.ciano);
}

class InterfaceColors {
  final String label;
  final Color accent, background, surface, card, raised, outline;
  InterfaceColors(
    this.label,
    int accent,
    int background,
    int surface,
    int card,
    int raised,
    int outline,
  ) : accent = Color(accent),
      background = Color(background),
      surface = Color(surface),
      card = Color(card),
      raised = Color(raised),
      outline = Color(outline);
}

final interfaceColors = <InterfaceTheme, InterfaceColors>{
  InterfaceTheme.ciano: InterfaceColors(
    'Ciano',
    0xff68e5da,
    0xff070f1b,
    0xff0c1827,
    0xff112236,
    0xff13263a,
    0xff38516b,
  ),
  InterfaceTheme.nero: InterfaceColors(
    'Nero',
    0xffdce0e5,
    0xff000000,
    0xff0b0b0d,
    0xff151518,
    0xff1e1e23,
    0xff505057,
  ),
  InterfaceTheme.blu: InterfaceColors(
    'Blu',
    0xff79b7ff,
    0xff07111f,
    0xff0d1a2d,
    0xff11233a,
    0xff162b43,
    0xff365778,
  ),
  InterfaceTheme.viola: InterfaceColors(
    'Viola',
    0xffc8a2ff,
    0xff100b1b,
    0xff1a1229,
    0xff241b38,
    0xff2b2142,
    0xff675079,
  ),
  InterfaceTheme.verde: InterfaceColors(
    'Verde',
    0xff84dfaf,
    0xff07140f,
    0xff0d2118,
    0xff123025,
    0xff183c2e,
    0xff3c6a55,
  ),
  InterfaceTheme.marrone: InterfaceColors(
    'Marrone',
    0xffe3b387,
    0xff17100c,
    0xff261a12,
    0xff342519,
    0xff3f2d1d,
    0xff7d6047,
  ),
  InterfaceTheme.giallo: InterfaceColors(
    'Giallo',
    0xfff5ce54,
    0xff141208,
    0xff211e0f,
    0xff2c2712,
    0xff302a14,
    0xff74643d,
  ),
  InterfaceTheme.rosso: InterfaceColors(
    'Rosso',
    0xffff9b9b,
    0xff190b0e,
    0xff2a141a,
    0xff391c24,
    0xff43242d,
    0xff78505b,
  ),
  InterfaceTheme.arancione: InterfaceColors(
    'Arancione',
    0xffffba7a,
    0xff191008,
    0xff281b10,
    0xff372719,
    0xff422f1d,
    0xff7b5b3b,
  ),
  InterfaceTheme.grigio: InterfaceColors(
    'Grigio',
    0xffadbcd0,
    0xff111318,
    0xff1a1e25,
    0xff242b35,
    0xff2c3440,
    0xff576477,
  ),
};
