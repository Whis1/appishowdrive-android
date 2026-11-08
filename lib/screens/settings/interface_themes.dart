import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/themes.dart';

class InterfaceThemesScreen extends StatelessWidget {
  const InterfaceThemesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final layout = context.watch<LayoutModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Colori dell’interfaccia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Scegli il tuo colore',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tocca un riquadro: il tema cambia subito e resta salvato.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anteprima chat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text('Buon viaggio, Ishowdrive!'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 136,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: InterfaceTheme.values.length,
            itemBuilder: (context, index) {
              final palette = InterfaceTheme.values[index],
                  colors = interfaceColors[palette]!,
                  selected = layout.interfaceTheme == palette;
              return Semantics(
                selected: selected,
                button: true,
                label: 'Tema ${colors.label}',
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: selected ? colors.accent : colors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => layout.interfaceTheme = palette,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  colors.label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xfff0f6ff),
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.accent,
                                  size: 22,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              for (final color in [
                                colors.background,
                                colors.card,
                                colors.accent,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    width: 27,
                                    height: 27,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colors.outline),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
