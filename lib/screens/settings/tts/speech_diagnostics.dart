import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/tts.dart';

class SpeechDiagnosticsTile extends StatelessWidget {
  const SpeechDiagnosticsTile({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (context.watch<TtsModel>().neuralFallback != null)
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Riprova voci IA'),
          onPressed: () async {
            await OnnxTtsPlatform.instance.resetNeuralRecovery();
            if (context.mounted) context.read<TtsModel>().retryNeuralVoices();
          },
        ),
      ListTile(
        leading: const Icon(Icons.troubleshoot),
        title: const Text('Diagnostica voci'),
        subtitle: const Text('Info del telefono e dell’ultima lettura IA'),
        onTap: () async {
          String text;
          try {
            final data = await OnnxTtsPlatform.instance.speechDiagnostics();
            text = [
              'Telefono: ${data['device']}',
              'Android API: ${data['androidApi']}',
              'CPU: ${data['abis']}',
              'RAM totale: ${((data['totalBytes'] as num? ?? 0) / 1048576).round()} MB',
              'RAM disponibile: ${((data['availableBytes'] as num? ?? 0) / 1048576).round()} MB',
              'Recupero voce IA: ${data['neuralRecoveryNeeded']}',
              'Ultima uscita Android: ${data['lastProcessExit']}',
            ].join('\n');
          } catch (_) {
            text = 'Diagnostica Android non disponibile su questa versione.';
          }
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Diagnostica voci'),
                  content: SingleChildScrollView(child: SelectableText(text)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Chiudi'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          () => Clipboard.setData(ClipboardData(text: text)),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copia'),
                    ),
                  ],
                ),
          );
        },
      ),
    ],
  );
}
