import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/themes.dart';
import 'package:rtchat/screens/settings/interface_themes.dart';

void main() {
  double contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
  }

  test(
    'All ten palettes retain readable text and primary controls in dark and light modes',
    () {
      expect(interfaceColors.length, 10);
      for (final palette in InterfaceTheme.values) {
        for (final theme in [
          Themes.darkFor(palette),
          Themes.lightFor(palette),
        ]) {
          final scheme = theme.colorScheme;
          expect(
            contrast(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name} body',
          );
          expect(
            contrast(scheme.onSurface, theme.scaffoldBackgroundColor),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name} background',
          );
          expect(
            contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: '${palette.name} buttons',
          );
        }
      }
    },
  );
  test(
    'Palette selection persists without altering original layout preferences',
    () {
      final layout = LayoutModel.fromJson({
        'interfaceTheme': 'viola',
        'isShowPreview': true,
        'themeMode': 1,
      });
      expect(layout.interfaceTheme, InterfaceTheme.viola);
      layout.interfaceTheme = InterfaceTheme.marrone;
      final restored = LayoutModel.fromJson(layout.toJson());
      expect(restored.interfaceTheme, InterfaceTheme.marrone);
      expect(restored.isShowPreview, true);
      expect(restored.themeMode, ThemeMode.dark);
      expect(
        LayoutModel.fromJson({'interfaceTheme': 'unknown'}).interfaceTheme,
        InterfaceTheme.ciano,
      );
      layout.dispose();
      restored.dispose();
    },
  );
  testWidgets(
    'Selecting a color tile applies it immediately and marks the choice',
    (tester) async {
      final layout = LayoutModel.fromJson({});
      addTearDown(layout.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: layout,
          child: Consumer<LayoutModel>(
            builder:
                (context, model, _) => MaterialApp(
                  theme: Themes.darkFor(model.interfaceTheme),
                  home: const InterfaceThemesScreen(),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Viola'));
      await tester.pumpAndSettle();
      expect(layout.interfaceTheme, InterfaceTheme.viola);
      final context = tester.element(find.byType(InterfaceThemesScreen));
      expect(
        Theme.of(context).colorScheme.primary,
        interfaceColors[InterfaceTheme.viola]!.accent,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
