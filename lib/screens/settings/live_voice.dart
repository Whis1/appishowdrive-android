import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveVoiceScreen extends StatelessWidget {
  const LiveVoiceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voce e rumori della live')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Voce più chiara in OBS',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Il componente per OBS riduce il rumore mentre parli e fa tornare l’ambiente dopo la frase. Si configura una volta sul PC che trasmette la live.',
        ),
        const SizedBox(height: 16),
        const Text(
          '1. Sul PC, scarica ed estrai il componente. Chiudi OBS e apri Installazione-Voce-OBS.exe.',
        ),
        const SizedBox(height: 12),
        const Text(
          '2. In OBS, sulla sola sorgente del microfono del telefono, apri Filtri → + → APPISHOWDRIVE · Voce e ambiente.',
        ),
        const SizedBox(height: 12),
        const Text(
          '3. Lascia video, musica, Sound Alerts e TTS su sorgenti separate. Prova una breve registrazione prima della live.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.computer),
          label: const Text('Componente per il PC con OBS'),
          onPressed: () async {
            final opened = await launchUrl(
              Uri.parse(
                'https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Voce-OBS.zip',
              ),
              mode: LaunchMode.externalApplication,
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Apri la pagina degli aggiornamenti GitHub dal PC.',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Il filtro va installato sul PC, non sul telefono. Android non permette a questa app di sostituire il microfono di un’altra app. Se il telefono invia già voce, musica e TTS tutti insieme, occorre prima separare la voce nel programma che trasmette.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Il filtro rileva la voce, ma non riconosce l’identità del parlante. Per evitare che TTS o musica rientrino fisicamente nel microfono, usa cuffie o auricolari.',
        ),
      ],
    ),
  );
}
