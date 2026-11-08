import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';

/// Italian voices share one offline model, with independent platform choices.
class ItalianVoicesScreen extends StatefulWidget {
  const ItalianVoicesScreen({super.key});
  @override
  State<ItalianVoicesScreen> createState() => _ItalianVoicesScreenState();
}

class _ItalianVoicesScreenState extends State<ItalianVoicesScreen> {
  bool _previewing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<VoicePacksModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<VoicePacksModel>();
    final tts = context.watch<TtsModel>();
    final pack = bundledVoicePacks.firstWhere((p) => p.id == 'supertonic-3');
    final ready = packs.installed.containsKey(pack.id);
    final task = packs.task(pack.id);
    final available =
        ready && tts.neuralEngine != null && tts.neuralFallback == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Voci italiane IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Una voce per ogni chat',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scegli la stessa voce per Twitch e Kick oppure due voci diverse. Sono voci generate da IA: dopo il download funzionano anche offline, senza abbonamenti.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PACCHETTO ITALIANO · 10 VOCI',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Supertonic 3 · ${(pack.downloadSize / 1048576).round()} MB · un solo download per tutte le voci',
                  ),
                  if (ready)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('✓ Voci installate sul telefono'),
                    ),
                  if (tts.neuralFallback != null)
                    const Text(
                      'Il motore IA non è disponibile su questo dispositivo. È attiva la voce Android; le selezioni rimangono salvate.',
                    ),
                  if (task != null) ...[
                    const SizedBox(height: 12),
                    StreamBuilder<VoicePackProgress>(
                      stream: task.progress,
                      builder: (context, snapshot) {
                        final p = snapshot.data;
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value:
                                  p == null || p.totalBytes == 0
                                      ? null
                                      : p.downloadedBytes / p.totalBytes,
                            ),
                            Text(
                              packs.waitsForWifi(pack.id)
                                  ? 'In attesa del Wi-Fi'
                                  : 'Download delle voci in corso…',
                            ),
                          ],
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () => packs.cancel(pack.id),
                      child: const Text('Annulla download'),
                    ),
                    if (packs.waitsForWifi(pack.id))
                      TextButton(
                        onPressed: () => packs.installOverMobileData(pack),
                        child: const Text('Usa dati mobili'),
                      ),
                  ] else if (!ready)
                    FilledButton.icon(
                      onPressed:
                          packs.isSupported
                              ? () {
                                tts.preferredVoicePackId = 'supertonic-3';
                                tts.speed = .5;
                                packs.install(pack);
                              }
                              : null,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Scarica le voci italiane'),
                    ),
                  if (packs.error(pack.id) != null)
                    const Text(
                      'Download non riuscito. Puoi riprovare: le voci già installate sono conservate.',
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Modello gratuito OpenRAIL-M · codice del motore MIT. Licenza e attribuzione nei pacchetti vocali.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _voiceRow(
            context,
            'Voce Android',
            'system',
            Icons.phone_android,
            true,
          ),
          for (final speaker in pack.speakers)
            _voiceRow(
              context,
              '${speaker.gender == 'female' ? 'Voce femminile' : 'Voce maschile'} ${speaker.name.substring(1)}',
              speaker.name,
              Icons.graphic_eq_rounded,
              available,
            ),
          const SizedBox(height: 16),
          Text(
            'Velocità di lettura',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: tts.speed.clamp(0.1, 1.0),
            min: 0.1,
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

  Widget _voiceRow(
    BuildContext context,
    String title,
    String id,
    IconData icon,
    bool available,
  ) {
    final tts = context.watch<TtsModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
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
                if (id != 'system')
                  IconButton(
                    tooltip: 'Ascolta $title',
                    onPressed:
                        !available || _previewing
                            ? null
                            : () async {
                              setState(() => _previewing = true);
                              try {
                                await tts.previewVoice(
                                  'it',
                                  id,
                                  'Ciao, benvenuti su Ishowdrive! Leggerò i vostri messaggi di Twitch e Kick durante il viaggio.',
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _previewing = false);
                                }
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
                    onSelected:
                        !available
                            ? null
                            : (_) => tts.setPlatformVoice(
                              provider,
                              tts.platformVoice(provider) == id ? null : id,
                            ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
