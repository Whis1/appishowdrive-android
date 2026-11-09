import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/embedded_engine.dart';
import 'package:rtchat/screens/settings/tts/speech_diagnostics.dart';

class ItalianVoicesScreen extends StatefulWidget {
  const ItalianVoicesScreen({super.key});
  @override
  State<ItalianVoicesScreen> createState() => _ItalianVoicesScreenState();
}

class _ItalianVoicesScreenState extends State<ItalianVoicesScreen> {
  bool _previewing = false;
  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TtsModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Voci italiane')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Voci già incluse nell’app',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cinque profili femminili e cinque maschili leggono in italiano, anche offline. Sara e Nicola sono le voci originali; gli altri timbri sono derivati da queste voci italiane. Ascolta un’anteprima e scegli separatamente per Twitch e Kick.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Le voci integrate richiedono Android 8 o successivo a 64 bit e memoria sufficiente. Se il motore non è disponibile, la lettura continua con la voce Android.',
          ),
          _row('system', 'Voce Android'),
          for (final voice in EmbeddedItalianEngine.names.entries)
            _row(voice.key, voice.value),
          const SpeechDiagnosticsTile(),
          Text(
            'Velocità di lettura',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: tts.speed.clamp(.1, 1),
            min: .1,
            max: 1,
            divisions: 18,
            label: '${(tts.speed * 2).toStringAsFixed(1)}×',
            onChanged: (v) => tts.speed = v,
          ),
          OutlinedButton(
            onPressed: () => tts.speed = .5,
            child: const Text('Usa velocità naturale'),
          ),
        ],
      ),
    );
  }

  Widget _row(String id, String title) {
    final tts = context.watch<TtsModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  id == 'system' ? Icons.phone_android : Icons.graphic_eq,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ascolta $title',
                  onPressed:
                      _previewing
                          ? null
                          : () async {
                            setState(() => _previewing = true);
                            try {
                              if (id != 'system') tts.retryNeuralVoices();
                              await tts.previewVoice(
                                'it',
                                id,
                                'Ciao, benvenuti su Ishowdrive! Leggerò i vostri messaggi di Twitch e Kick durante il viaggio.',
                              );
                              if (mounted &&
                                  tts.neuralFallback != null &&
                                  id != 'system') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'La voce integrata non è disponibile. Hai ascoltato la voce Android. Consulta Diagnostica voci.',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _previewing = false);
                            }
                          },
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final provider in Providers.all)
                  FilterChip(
                    avatar: ProviderIcon(provider, size: 18),
                    label: Text('Usa per ${providerName(provider)}'),
                    selected: tts.platformVoice(provider) == id,
                    onSelected: (_) => tts.setPlatformVoice(provider, id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
