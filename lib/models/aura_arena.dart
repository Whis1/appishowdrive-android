import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/message.dart';

enum AuraArgument { none, user, number, userNumber }

class AuraCommand {
  final String command;
  final String label;
  final bool streamer;
  final AuraArgument argument;
  final bool destructive;
  const AuraCommand(
    this.command,
    this.label, {
    this.streamer = true,
    this.argument = AuraArgument.none,
    this.destructive = false,
  });
}

const auraStreamerCommands = [
  AuraCommand('!Apriudienze', 'Apri udienze'),
  AuraCommand('!Creatorneo', 'Crea torneo'),
  AuraCommand('!Sfidatutti', 'Avvia Evento BOSS'),
  AuraCommand('!Processo', 'Processo', argument: AuraArgument.user),
  AuraCommand('!Sanziona', 'Invia Agente Suinos', argument: AuraArgument.user),
  AuraCommand('!HP', 'Aggiungi HP', argument: AuraArgument.userNumber),
  AuraCommand('!LevaHP', 'Leva HP', argument: AuraArgument.userNumber),
  AuraCommand('!LevaPA', 'Leva Punti Aura', argument: AuraArgument.userNumber),
  AuraCommand('!ImpostaBIT', 'Imposta Bit HP', argument: AuraArgument.number),
  AuraCommand('!AggiornaAPP', 'Aggiorna app Arena'),
  AuraCommand('!Stopapp', 'Ferma Arena'),
  AuraCommand('!Avviaapp', 'Avvia Arena'),
  AuraCommand('!Wipe', 'Azzera classifica', destructive: true),
  AuraCommand('!WipePA', 'Azzera Punti Aura', destructive: true),
];
// These commands appear only at their step after !Creatorneo.
const auraTournamentCommands = [
  AuraCommand('!ForzaTorneo', 'ForzaTorneo'),
  AuraCommand('!Iniziatorneo', 'Iniziatorneo'),
  AuraCommand('!Terminatorneo', 'Terminatorneo'),
];
const auraAudienceCommands = [
  AuraCommand('!Chiudiudienze', 'Chiudi udienze'),
  AuraCommand('!Approva', 'Approva'),
  AuraCommand('!Rifiuta', 'Rifiuta'),
  AuraCommand('!Arresta', 'Arresta'),
];
const auraUserCommands = [
  AuraCommand(
    '!Sfida',
    'Sfida un utente',
    streamer: false,
    argument: AuraArgument.user,
  ),
  AuraCommand('!Accetta', 'Accetta sfida', streamer: false),
  AuraCommand('!Classificaura', 'Classifica Aura', streamer: false),
  AuraCommand(
    '!Puntiaura',
    'I miei Punti Aura',
    streamer: false,
    argument: AuraArgument.user,
  ),
  AuraCommand('!Livello', 'Il mio livello', streamer: false),
  AuraCommand('!Bonus', 'Bonus sfide', streamer: false),
  AuraCommand('!Sceglipg', 'Scegli personaggio', streamer: false),
  AuraCommand('!Richiestapg', 'Richiedi personaggio', streamer: false),
  AuraCommand('!AumentoHP', 'Aumento HP', streamer: false),
  AuraCommand('!Torneo', 'Informazioni torneo', streamer: false),
  AuraCommand('!Partecipatorneo', 'Partecipa al Torneo', streamer: false),
  AuraCommand('!EventoBOSS', 'Informazioni BOSS', streamer: false),
  AuraCommand('!Sfidaboss', 'Sfida il BOSS', streamer: false),
  AuraCommand('!AgenteSuinos', 'Agente Suinos', streamer: false),
  AuraCommand('!Sistemalivelli', 'Sistema livelli', streamer: false),
  AuraCommand('!Proposteapprovate', 'Proposte approvate', streamer: false),
  AuraCommand('!Ruotas', 'Gira la ruota', streamer: false),
  AuraCommand(
    '!Vincites',
    'Ultima vincita',
    streamer: false,
    argument: AuraArgument.user,
  ),
];
String auraEncode(AuraCommand command, {String? target, String? amount}) {
  final needsUser = [
    AuraArgument.user,
    AuraArgument.userNumber,
  ].contains(command.argument);
  final needsNumber = [
    AuraArgument.number,
    AuraArgument.userNumber,
  ].contains(command.argument);
  final login = (target ?? '').replaceFirst(RegExp(r'^@'), '').trim();
  if (needsUser && !RegExp(r'^[a-zA-Z0-9_]{1,25}$').hasMatch(login)) {
    throw ArgumentError('Inserisci un nome Twitch valido');
  }
  if (needsNumber) {
    if (!RegExp(r'^[0-9]{1,100}$').hasMatch(amount ?? '') ||
        BigInt.parse(amount!) <= BigInt.zero) {
      throw ArgumentError('Inserisci una quantità intera maggiore di zero');
    }
    if (['!HP', '!LevaHP'].contains(command.command) &&
        BigInt.parse(amount) > BigInt.from(10000)) {
      throw ArgumentError('La quantità massima è 10000 HP');
    }
  }
  return [
    command.command,
    if (needsNumber) BigInt.parse(amount!).toString(),
    if (needsUser) '@${login.toLowerCase()}',
  ].join(' ');
}

class AuraInvite {
  final String challenger;
  final String recipient;
  final DateTime expiresAt;
  const AuraInvite(this.challenger, this.recipient, this.expiresAt);
}

class AuraChannelState {
  bool audiences = false;
  int tournament =
      0; // 0 hidden, 1 force choice, 2 participation, 3 start/end controls.
  final List<AuraInvite> invites = [];
  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

class AuraArenaModel extends ChangeNotifier {
  final Map<Channel, AuraChannelState> _states = {};
  final DateTime Function() now;
  bool _sending = false;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get sending => _sending;
  void setSending(bool value) {
    _sending = value;
    if (!_disposed) notifyListeners();
  }

  AuraArenaModel({DateTime Function()? clock}) : now = clock ?? DateTime.now;
  AuraChannelState state(Channel channel) =>
      _states.putIfAbsent(channel, AuraChannelState.new);
  AuraInvite? invitation(Channel channel, {String? recipient}) =>
      state(channel).invites
          .where(
            (i) =>
                i.expiresAt.isAfter(now()) &&
                (recipient == null ||
                    i.recipient.toLowerCase() == recipient.toLowerCase()),
          )
          .firstOrNull;
  void dismiss(Channel channel) {
    final invite = invitation(channel);
    state(channel).invites.remove(invite);
    notifyListeners();
  }

  void withoutForce(Channel channel) {
    state(channel).tournament = 2;
    notifyListeners();
  }

  void skipParticipation(Channel channel) {
    state(channel).tournament = 3;
    notifyListeners();
  }

  void sent(Channel channel, String text) {
    if (_disposed || channel.provider != Providers.twitch) return;
    final s = state(channel), command = text.split(' ').first.toLowerCase();
    s.updatedAt = now();
    switch (command) {
      case '!apriudienze':
        s.audiences = true;
      case '!chiudiudienze':
        s.audiences = false;
      case '!creatorneo':
        s.tournament = 1;
      case '!forzatorneo':
        if (s.tournament == 1) s.tournament = 2;
      case '!partecipatorneo':
        if (s.tournament == 2) s.tournament = 3;
      case '!iniziatorneo' || '!terminatorneo':
        s.tournament = 0;
      case '!accetta':
        s.invites.clear();
    }
    notifyListeners();
  }

  /// Only live, authenticated provider messages from the game's bot are observed.
  void observe(
    Channel channel,
    MessageModel message, {
    required String? recipient,
  }) {
    if (_disposed ||
        channel.provider != Providers.twitch ||
        message is! ChatMessage ||
        message.deleted ||
        message.author.login.toLowerCase() != 'ufonibiru') {
      return;
    }
    final s = state(channel), text = message.message;
    if (message.timestamp.isBefore(
      s.updatedAt.subtract(const Duration(seconds: 2)),
    )) {
      return;
    }
    if (text.contains('ha aperto le udienze!')) s.audiences = true;
    if (text.contains('ha ufficialmente chiuso le udienze!')) {
      s.audiences = false;
    }
    if (text.startsWith('Torneo aperto!') && s.tournament == 0) {
      s.tournament = 1;
    }
    if (text.startsWith('Iscrizioni chiuse:') ||
        text.contains('Nessun torneo in atto')) {
      s.tournament = 0;
    }
    if (text.contains('vince il torneo:') || text == 'Torneo terminato.') {
      s.tournament = 0;
    }
    final invite = RegExp(
      r'^@([^ ,]+), ([a-zA-Z0-9_]{1,25}) ti sfida! Scrivi !accetta entro 1 minuto\.$',
      caseSensitive: false,
    ).firstMatch(text);
    if (invite != null &&
        recipient != null &&
        invite[1]!.toLowerCase() == recipient.toLowerCase()) {
      final expires = message.timestamp.add(const Duration(minutes: 1));
      if (expires.isAfter(now())) {
        s.invites.removeWhere(
          (i) => i.challenger.toLowerCase() == invite[2]!.toLowerCase(),
        );
        s.invites.add(AuraInvite(invite[2]!, recipient, expires));
        if (s.invites.length > 20) s.invites.removeAt(0);
      }
    }
    notifyListeners();
  }
}
