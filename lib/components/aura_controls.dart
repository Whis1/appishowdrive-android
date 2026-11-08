import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/layout.dart';

/// Sends as the signed-in Twitch account; the game remains authoritative.
Future<bool> sendAura(
  BuildContext context,
  Channel channel,
  AuraCommand command, {
  String? target,
  String? amount,
}) async {
  final model = context.read<AuraArenaModel>();
  if (model.sending || channel.provider != Providers.twitch) return false;
  final user = context.read<UserModel>(),
      account = user.accountOn(Providers.twitch);
  if (account == null || (command.streamer && !user.isOwnChannel(channel))) {
    return false;
  }
  final messenger = ScaffoldMessenger.of(context);
  final text = auraEncode(command, target: target, amount: amount);
  model.setSending(true);
  try {
    final error = await ActionsAdapter.forAccount(account).send(channel, text);
    if (error != null) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
      return false;
    }
    model.sent(channel, text);
    if (context.mounted) {
      context.read<CommandsModel>().addCommand(Command(text, DateTime.now()));
    }
    return true;
  } catch (_) {
    if (messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Invio non riuscito. Il comando non è stato confermato.',
          ),
        ),
      );
    }
    return false;
  } finally {
    model.setSending(false);
  }
}

Future<void> runAuraCommand(
  BuildContext context,
  Channel channel,
  AuraCommand command, {
  String? target,
}) async {
  String? amount;
  if (command.argument != AuraArgument.none &&
      !(command.argument == AuraArgument.user && target != null)) {
    final result = await showDialog<({String target, String amount})>(
      context: context,
      builder: (context) => _ArgumentsDialog(command: command, target: target),
    );
    if (result == null || !context.mounted) return;
    target = result.target;
    amount = result.amount;
  }
  if (command.destructive) {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(command.label),
            content: const Text(
              'Questa azione azzera i dati del gioco indicati dal comando. Vuoi eseguirla?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Conferma'),
              ),
            ],
          ),
    );
    if (accepted != true || !context.mounted) return;
  }
  if (!context.mounted) return;
  await sendAura(context, channel, command, target: target, amount: amount);
}

class _ArgumentsDialog extends StatefulWidget {
  final AuraCommand command;
  final String? target;
  const _ArgumentsDialog({required this.command, this.target});
  @override
  State<_ArgumentsDialog> createState() => _ArgumentsDialogState();
}

class _ArgumentsDialogState extends State<_ArgumentsDialog> {
  late final _target = TextEditingController(text: widget.target);
  final _amount = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _target.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = [
          AuraArgument.user,
          AuraArgument.userNumber,
        ].contains(widget.command.argument),
        number = [
          AuraArgument.number,
          AuraArgument.userNumber,
        ].contains(widget.command.argument);
    return AlertDialog(
      title: Text(widget.command.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user)
              TextField(
                controller: _target,
                readOnly: widget.target != null,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Nome utente Twitch',
                  prefixText: '@',
                ),
              ),
            if (number)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength:
                      ['!HP', '!LevaHP'].contains(widget.command.command)
                          ? 5
                          : 100,
                  decoration: const InputDecoration(labelText: 'Quantità'),
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff66d99c),
            foregroundColor: const Color(0xff06151a),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Invia'),
          onPressed: () {
            try {
              auraEncode(
                widget.command,
                target: _target.text,
                amount: _amount.text,
              );
              Navigator.pop(context, (
                target: _target.text,
                amount: _amount.text,
              ));
            } on ArgumentError catch (e) {
              setState(() => _error = e.message.toString());
            }
          },
        ),
      ],
    );
  }
}

class AuraCommandPanel extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTournament;
  final ValueChanged<String>? onCompose;
  const AuraCommandPanel({
    super.key,
    required this.channel,
    this.onTournament,
    this.onCompose,
  });
  @override
  Widget build(BuildContext context) {
    final owner = context.watch<UserModel>().isOwnChannel(channel),
        model = context.watch<AuraArenaModel>();
    final media = MediaQuery.of(context);
    final preview =
        media.orientation == Orientation.portrait &&
                context.watch<LayoutModel>().isShowPreview
            ? media.size.width * 9 / 16
            : 0.0;
    final panelHeight = (media.size.height -
            View.of(context).viewInsets.bottom /
                View.of(context).devicePixelRatio -
            media.padding.vertical -
            56 -
            preview -
            88 -
            64)
        .clamp(140.0, 320.0);
    return SizedBox(
      height: panelHeight,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Comandi Aura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [Tab(text: 'Solo Streamer'), Tab(text: 'Solo utenti')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  owner
                      ? _buttons(
                        context,
                        model.state(channel).audiences
                            ? auraAudienceCommands
                            : auraStreamerCommands,
                        model.sending,
                      )
                      : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'I comandi streamer sono disponibili nel tuo canale Twitch.',
                          ),
                        ),
                      ),
                  _buttons(context, auraUserCommands, model.sending),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(
    BuildContext context,
    List<AuraCommand> commands,
    bool busy,
  ) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 230,
      mainAxisExtent: 58,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: commands.length,
    itemBuilder: (context, i) {
      final command = commands[i];
      final composeOnly = [
        '!Processo',
        '!Sanziona',
        '!HP',
        '!LevaHP',
        '!LevaPA',
      ].contains(command.command);
      return OutlinedButton(
        onPressed:
            busy
                ? null
                : () async {
                  if (composeOnly) {
                    onCompose?.call('${command.command} ');
                    return;
                  }
                  await runAuraCommand(context, channel, command);
                  if (context.mounted &&
                      command.command == '!Creatorneo' &&
                      context
                              .read<AuraArenaModel>()
                              .state(channel)
                              .tournament ==
                          1) {
                    onTournament?.call();
                  }
                },
        child: Text(command.command, textAlign: TextAlign.center, maxLines: 2),
      );
    },
  );
}

class AuraContextCards extends StatefulWidget {
  final Channel channel;
  const AuraContextCards({super.key, required this.channel});
  @override
  State<AuraContextCards> createState() => _AuraContextCardsState();
}

class _AuraContextCardsState extends State<AuraContextCards> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AuraArenaModel>(),
        state = model.state(widget.channel),
        owner = context.watch<UserModel>().isOwnChannel(widget.channel),
        invite = model.invitation(
          widget.channel,
          recipient:
              context
                  .watch<UserModel>()
                  .accountOn(Providers.twitch)
                  ?.channel
                  .displayName,
        );
    if (invite != null) {
      return _card(context, '${invite.challenger} ti ha sfidato!', [
        _button(
          'Accetta',
          true,
          model.sending
              ? null
              : () => sendAura(
                context,
                widget.channel,
                const AuraCommand(
                  '!Accetta',
                  'Accetta',
                  streamer: false,
                  argument: AuraArgument.user,
                ),
                target: invite.challenger,
              ),
        ),
        _button('Ignora', false, () => model.dismiss(widget.channel)),
      ]);
    }
    if (!owner || state.tournament == 0) {
      return const SizedBox.shrink();
    }
    if (state.tournament == 1) {
      return _card(context, 'Torneo creato', [
        _button(
          'ForzaTorneo',
          true,
          model.sending
              ? null
              : () => sendAura(
                context,
                widget.channel,
                const AuraCommand('!ForzaTorneo', 'ForzaTorneo'),
              ),
        ),
        _button(
          'Senza Forzare',
          false,
          () => model.withoutForce(widget.channel),
        ),
      ]);
    }
    if (state.tournament == 2) {
      return _card(context, 'Vuoi partecipare al torneo?', [
        _button(
          'Partecipa al Torneo',
          true,
          model.sending
              ? null
              : () => sendAura(
                context,
                widget.channel,
                const AuraCommand(
                  '!Partecipatorneo',
                  'Partecipa al Torneo',
                  streamer: false,
                ),
              ),
        ),
        _button(
          'Non partecipare',
          false,
          () => model.skipParticipation(widget.channel),
        ),
      ]);
    }
    return _card(context, 'Gestisci il torneo', [
      _button(
        'Iniziatorneo',
        true,
        model.sending
            ? null
            : () => sendAura(
              context,
              widget.channel,
              const AuraCommand('!Iniziatorneo', 'Iniziatorneo'),
            ),
      ),
      _button(
        'Terminatorneo',
        false,
        model.sending
            ? null
            : () => sendAura(
              context,
              widget.channel,
              const AuraCommand('!Terminatorneo', 'Terminatorneo'),
            ),
      ),
    ]);
  }

  Widget _card(BuildContext context, String title, List<Widget> buttons) =>
      Card(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final (i, b) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: b),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
  Widget _button(String text, bool positive, VoidCallback? onTap) =>
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              positive ? const Color(0xff66d99c) : const Color(0xffc95263),
          foregroundColor: positive ? const Color(0xff051a12) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        onPressed: onTap,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
}
