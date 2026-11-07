// APPISHOWDRIVE modification, 7 November 2026: community Android edition; see NOTICE-APPISHOWDRIVE.md.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

Uri companionSignInUri(String provider, String session) {
  if (!{'twitch', 'kick'}.contains(provider) ||
      !RegExp(r'^[a-f0-9-]{36}$').hasMatch(session)) {
    throw ArgumentError('Invalid sign-in session');
  }
  return Uri.https('chat.rtirl.com', '/auth/$provider/redirect', {
    'companion': session,
  });
}

class CompanionAuthWidget extends StatefulWidget {
  final String provider;
  final bool isTooOld;
  final bool sameDevice;

  const CompanionAuthWidget({
    super.key,
    required this.isTooOld,
    required this.provider,
    this.sameDevice = false,
  });

  @override
  State<CompanionAuthWidget> createState() => _CompanionAuthWidgetState();
}

class _CompanionAuthWidgetState extends State<CompanionAuthWidget> {
  final sessionUuid = const Uuid().v4();
  StreamSubscription<String>? _subscription;
  Timer? _timeout;
  String? _error;
  bool _finishing = false;

  Uri get _url => companionSignInUri(widget.provider, sessionUuid);

  @override
  void initState() {
    super.initState();
    _listen();
    if (widget.sameDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openBrowser());
      });
    }
  }

  void _listen() {
    unawaited(_subscription?.cancel());
    _timeout?.cancel();
    _subscription = ProfilesAdapter.instance
        .companionAuthTokens(sessionUuid: sessionUuid)
        .listen(
          (token) async {
            if (!mounted || _finishing) return;
            _finishing = true;
            try {
              final accounts = Provider.of<AccountsModel>(
                context,
                listen: false,
              );
              final navigator = Navigator.of(context);
              await accounts.signIn(widget.provider, token);
              if (mounted) navigator.pop();
            } catch (_) {
              if (mounted) {
                setState(() {
                  _error = 'Accesso non completato. Chiudi e riprova.';
                  _finishing = false;
                });
              }
            }
          },
          onError: (Object _) {
            if (mounted) {
              setState(
                () =>
                    _error =
                        'Collegamento non disponibile. Controlla la connessione e riprova.',
              );
            }
          },
        );
    _timeout = Timer(const Duration(minutes: 5), () {
      unawaited(_subscription?.cancel());
      if (mounted) {
        setState(
          () =>
              _error =
                  'Tempo di accesso scaduto. Premi il pulsante per riprovare.',
        );
      }
    });
  }

  Future<void> _openBrowser() async {
    if (_error != null) {
      setState(() => _error = null);
      _listen();
    }
    try {
      if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
        throw StateError('Browser unavailable');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error =
                  'Impossibile aprire il browser. Puoi usare il QR da un altro dispositivo.',
        );
      }
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                Text(
                  widget.sameDevice
                      ? 'Autorizza ${widget.provider == 'kick' ? 'Kick' : 'Twitch'} nel browser, poi torna in APPISHOWDRIVE.'
                      : widget.isTooOld
                      ? AppLocalizations.of(context)!.companionAuthBrowserTooOld
                      : AppLocalizations.of(context)!.companionAuthScanQrCode,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Accedi dal browser di questo telefono'),
                  onPressed: _openBrowser,
                ),
                const Text(
                  'Dopo l’autorizzazione torna in APPISHOWDRIVE. Puoi anche usare il QR da un altro dispositivo.',
                ),
                QrImageView(
                  backgroundColor: Colors.white,
                  data: _url.toString(),
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
