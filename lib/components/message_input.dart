import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/autocomplete.dart';
import 'package:rtchat/components/aura_controls.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/share_channel.dart';

class EmoteTextEditingController extends TextEditingController {
  List<Emote> emotes;

  EmoteTextEditingController(this.emotes);

  Iterable<MessageToken> tokenizeEmotes(
    String message,
    List<Emote> emotes,
  ) sync* {
    final emotesMap = {for (final emote in emotes) emote.code: emote};
    var lastParsedStart = 0;
    for (var start = 0; start < message.length;) {
      final end = message.indexOf(" ", start);
      final token =
          end == -1 ? message.substring(start) : message.substring(start, end);
      final emote = emotesMap[token.trim()];
      if (emote != null) {
        if (lastParsedStart != start) {
          yield TextToken(message.substring(lastParsedStart, start));
        }
        yield EmoteToken(url: emote.uri, code: emote.code);
        lastParsedStart = end == -1 ? message.length : end;
      }
      start = end == -1 ? message.length : end + 1;
    }
    if (lastParsedStart != message.length) {
      yield TextToken(message.substring(lastParsedStart));
    }
  }

  static Iterable<InlineSpan> render(
    BuildContext context,
    StyleModel styleModel,
    MessageToken token,
  ) sync* {
    if (token is TextToken) {
      yield TextSpan(text: token.text);
    } else if (token is EmoteToken) {
      yield* [
        TextSpan(text: "\u200B" * (token.code.length - 1)),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Tooltip(
            message: token.code,
            preferBelow: false,
            child: Image(
              height: styleModel.fontSize,
              image: CachedNetworkImageProvider(token.url.toString()),
              errorBuilder: (context, error, stackTrace) => Text(token.code),
            ),
          ),
        ),
      ];
    } else {
      throw Exception("invalid token");
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    assert(
      !value.composing.isValid || !withComposing || value.isComposingRangeValid,
    );
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final bool composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    final styleModel = Provider.of<StyleModel>(context, listen: false);

    if (composingRegionOutOfRange) {
      return TextSpan(
        style: style,
        children:
            tokenizeEmotes(
              text,
              emotes,
            ).expand((token) => render(context, styleModel, token)).toList(),
      );
    }

    final TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);

    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(
          children:
              tokenizeEmotes(
                value.composing.textBefore(value.text),
                emotes,
              ).expand((token) => render(context, styleModel, token)).toList(),
        ),
        TextSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        TextSpan(
          children:
              tokenizeEmotes(
                value.composing.textAfter(value.text),
                emotes,
              ).expand((token) => render(context, styleModel, token)).toList(),
        ),
      ],
    );
  }
}

class MessageInputWidget extends StatefulWidget {
  /// The channel messages are sent to and whose emotes are offered. Null when
  /// the signed-in account can't post to any of the channels shown, which
  /// disables the input.
  final Channel? channel;

  /// The channels that can be picked to send to instead. With more than one,
  /// a picker for them shows to the left of the input.
  final List<Channel> channels;

  /// Called with the channel picked to send to.
  final ValueChanged<Channel>? onChannelSelected;

  /// Loads the emotes usable in a channel. Defaults to [getEmotes], as the
  /// account on the channel's provider.
  final Future<List<Emote>> Function(Channel channel)? loadEmotes;

  const MessageInputWidget({
    super.key,
    required this.channel,
    this.channels = const [],
    this.onChannelSelected,
    this.loadEmotes,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  EmoteTextEditingController? _textEditingController;
  final _chatInputFocusNode = FocusNode();
  var _isEmotePickerVisible = false;
  var _isAuraPickerVisible = false;
  var _isKeyboardVisible = false;

  Future<void> _preparePanel() async {
    // Let the field's tap/focus event settle before hiding the native keyboard.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _chatInputFocusNode.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    final deadline = DateTime.now().add(const Duration(milliseconds: 600));
    while (mounted &&
        View.of(context).viewInsets.bottom > 0 &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  double _emotePanelHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final preview =
        media.orientation == Orientation.portrait &&
                context.watch<LayoutModel>().isShowPreview
            ? media.size.width * 9 / 16
            : 0.0;
    return (media.size.height -
            View.of(context).viewInsets.bottom /
                View.of(context).devicePixelRatio -
            media.padding.vertical -
            kToolbarHeight -
            preview -
            90)
        .clamp(64.0, 288.0);
  }

  late StreamSubscription keyboardSubscription;
  final _textSeed = Random().nextDouble();
  final List<String> _pendingSend = [];

  // the channel whose emotes are offered, and its emotes.
  Channel? _emoteChannel;
  Future<List<Emote>> _channelEmotes = Future.value(const []);
  List<Emote> _loadedEmotes = const [];

  @override
  void initState() {
    super.initState();
    final keyboardVisibilityController = KeyboardVisibilityController();
    _textEditingController = EmoteTextEditingController(const []);
    _useEmotesOf(widget.channel);
    // Subscribe to keyboard visibility changes.
    keyboardSubscription = keyboardVisibilityController.onChange.listen((
      visible,
    ) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });

    ShareChannel()
      // Register a callback to handle any shared data while app is running
      ..onDataReceived = _handleSharedData
      // Check to see if there is any shared data already via sharing
      ..getSharedText().then(_handleSharedData);
  }

  @override
  void didUpdateWidget(MessageInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _useEmotesOf(widget.channel);
    if (oldWidget.channel != widget.channel) _isAuraPickerVisible = false;
  }

  /// Starts loading [channel]'s emotes if they aren't already the ones
  /// offered.
  void _useEmotesOf(Channel? channel) {
    if (channel == _emoteChannel) {
      return;
    }
    _emoteChannel = channel;
    // don't keep offering the previous channel's emotes while loading.
    _loadedEmotes = const [];
    _textEditingController?.emotes = const [];
    if (channel == null) {
      _channelEmotes = Future.value(const []);
      return;
    }
    final emotes =
        widget.loadEmotes?.call(channel) ??
        getEmotes(
          channel,
          Provider.of<UserModel>(
            context,
            listen: false,
          ).apiOn(channel.provider),
        );
    _channelEmotes = emotes;
    emotes.then(
      (loaded) {
        // the channel may have changed while these were loading.
        if (!mounted || _emoteChannel != channel) {
          return;
        }
        setState(() {
          _loadedEmotes = loaded;
          _textEditingController?.emotes = loaded;
        });
      },
      onError: (_) {
        // without emotes, messages are still sent as typed.
      },
    );
  }

  // Handles any shared data we may receive.
  void _handleSharedData(String sharedData) {
    if (!mounted || sharedData.isEmpty) {
      return;
    }
    setState(() {
      _textEditingController?.text = sharedData;
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _chatInputFocusNode.dispose();
    _textEditingController?.dispose();
    super.dispose();
  }

  void sendMessage(String value) async {
    value = value.trim();
    final channel = widget.channel;
    if (value.isEmpty || channel == null) {
      return;
    }
    // an account can chat in others' channels on its own provider.
    final account = Provider.of<UserModel>(
      context,
      listen: false,
    ).accountOn(channel.provider);
    if (account == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (value.startsWith('!')) {
      final commandsModel = Provider.of<CommandsModel>(context, listen: false);
      commandsModel.addCommand(Command(value, DateTime.now()));
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _textEditingController?.clear();
    });
    var done = false;
    await Future.wait([
      () async {
        try {
          final error = await ActionsAdapter.forAccount(
            account,
          ).send(channel, value);
          if (error != null) {
            messenger.showSnackBar(SnackBar(content: Text(error)));
          } else if (mounted && channel.provider == Providers.twitch) {
            context.read<AuraArenaModel>().sent(channel, value);
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(e.toString())));
        }
        done = true;
        if (!mounted) {
          return;
        }
        setState(() {
          _pendingSend.remove(value);
        });
      }(),
      () async {
        await Future.delayed(const Duration(seconds: 1));
        if (!done) {
          if (!mounted) {
            return;
          }
          setState(() {
            _pendingSend.add(value);
          });
        }
      }(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final l10n = AppLocalizations.of(context)!;
    final invite =
        channel?.provider == Providers.twitch
            ? context.watch<AuraArenaModel>().invitation(
              channel!,
              recipient:
                  context
                      .watch<UserModel>()
                      .accountOn(Providers.twitch)
                      ?.channel
                      .displayName,
            )
            : null;
    final showAura = _isAuraPickerVisible && invite == null;
    if (invite != null && _isAuraPickerVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isAuraPickerVisible = false);
      });
    }
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (channel?.provider == Providers.twitch && !showAura)
            AuraContextCards(channel: channel!),
          // render pending sends
          ..._pendingSend.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                e,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
          if (_isKeyboardVisible && channel != null)
            Flexible(
              child: AutocompleteWidget(
                controller: _textEditingController!,
                onSend: sendMessage,
                emotes: _channelEmotes,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (channel != null && widget.channels.length > 1)
                  _DestinationPicker(
                    channel: channel,
                    channels: widget.channels,
                    onSelected: widget.onChannelSelected,
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      color: Theme.of(context).splashColor,
                    ),
                    child: TextField(
                      enabled: channel != null,
                      focusNode: _chatInputFocusNode,
                      controller: _textEditingController,
                      textInputAction: TextInputAction.send,
                      // kick rejects messages over 500 characters (grapheme
                      // clusters, which is how maxLength counts too).
                      maxLength:
                          channel?.provider == Providers.kick ? 500 : null,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      maxLines: 6,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (channel?.provider == Providers.twitch)
                              IconButton(
                                tooltip: 'Aura Arena',
                                iconSize: 24,
                                icon: Image.asset(
                                  'assets/aura-arena.png',
                                  width: 24,
                                  height: 24,
                                ),
                                onPressed: () async {
                                  await _preparePanel();
                                  if (!mounted) return;
                                  setState(() {
                                    _isAuraPickerVisible =
                                        !_isAuraPickerVisible;
                                    _isEmotePickerVisible = false;
                                  });
                                },
                              ),
                            IconButton(
                              tooltip: 'Emote',
                              onPressed:
                                  channel == null
                                      ? null
                                      : () async {
                                        if (_isEmotePickerVisible) {
                                          setState(
                                            () => _isEmotePickerVisible = false,
                                          );
                                          _chatInputFocusNode.requestFocus();
                                          return;
                                        }

                                        await _preparePanel();

                                        if (!mounted) return;

                                        setState(() {
                                          _isEmotePickerVisible = true;
                                          _isAuraPickerVisible = false;
                                        });
                                      },
                              splashRadius: 24,
                              icon:
                                  _isEmotePickerVisible
                                      ? const Icon(Icons.keyboard_rounded)
                                      : const Icon(
                                        Icons.emoji_emotions_outlined,
                                      ),
                            ),
                          ],
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: Theme.of(context).colorScheme.primary,
                          splashRadius: 24,
                          onPressed:
                              channel == null
                                  ? null
                                  : () => sendMessage(
                                    _textEditingController?.text ?? '',
                                  ),
                        ),
                        border: InputBorder.none,
                        hintMaxLines: 1,
                        hintText: () {
                          if (channel == null) {
                            final accounts =
                                Provider.of<UserModel>(context).accounts;
                            if (accounts.isEmpty) {
                              return l10n.signInToSendMessages;
                            } else if (accounts.length > 1) {
                              return l10n.cantChatWithAccounts;
                            }
                            return l10n.cantChatWithAccount(
                              providerName(accounts.single.provider),
                            );
                          }
                          // name the channel when it's one of several.
                          if (widget.channels.length > 1) {
                            return l10n.sendAMessageTo(channel.displayName);
                          }
                          if (_textSeed < 0.5) {
                            return l10n.sendAMessage;
                          } else if (_textSeed < 0.9) {
                            return l10n.writeSomething;
                          } else if (_textSeed < 0.99) {
                            return l10n.speakToTheCrowds;
                          } else if (_textSeed < 0.999) {
                            return l10n.shareYourThoughts;
                          }
                          return l10n.saySomethingYouLittleBitch;
                        }(),
                      ),
                      onChanged: (text) {
                        final filtered = text.replaceAll('\n', ' ');
                        if (filtered == text) {
                          return;
                        }
                        setState(() {
                          _textEditingController?.value = TextEditingValue(
                            text: filtered,
                            selection: TextSelection.fromPosition(
                              TextPosition(
                                offset:
                                    _textEditingController?.text.length ?? 0,
                              ),
                            ),
                          );
                        });
                      },
                      onSubmitted: sendMessage,
                      onTap: () {
                        setState(() {
                          _isEmotePickerVisible = false;
                          _isAuraPickerVisible = false;
                        });
                        _chatInputFocusNode.requestFocus();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (channel?.provider == Providers.twitch)
            AnimatedSize(
              duration:
                  MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child:
                  showAura
                      ? AuraCommandPanel(
                        channel: channel!,
                        onCompose: (text) {
                          _textEditingController!.value = TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(
                              offset: text.length,
                            ),
                          );
                          setState(() {
                            _isAuraPickerVisible = false;
                            _isEmotePickerVisible = false;
                          });
                          _chatInputFocusNode.requestFocus();
                        },
                        onTournament:
                            () => setState(() => _isAuraPickerVisible = false),
                      )
                      : const SizedBox.shrink(),
            ),
          _isEmotePickerVisible && channel != null
              ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _emotePanelHeight(context),
                ),
                child: EmotePickerWidget(
                  channel: channel,
                  emotes: _loadedEmotes,
                  onEmoteSelected: (emote) {
                    if (emote == null) {
                      setState(() {
                        _isEmotePickerVisible = false;
                      });
                      return;
                    }
                    if (_textEditingController?.text.isNotEmpty ?? false) {
                      _textEditingController?.text =
                          "${_textEditingController?.text} ${emote.code} ";
                    } else {
                      _textEditingController?.text = "${emote.code} ";
                    }
                  },
                ),
              )
              : Container(),
        ],
      ),
    );
  }
}

/// Shows the channel messages are sent to, and picks another from
/// [channels].
class _DestinationPicker extends StatelessWidget {
  final Channel channel;
  final List<Channel> channels;
  final ValueChanged<Channel>? onSelected;

  const _DestinationPicker({
    required this.channel,
    required this.channels,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Channel>(
      tooltip: channel.displayName,
      initialValue: channel,
      onSelected: onSelected,
      itemBuilder:
          (context) => [
            for (final option in channels)
              PopupMenuItem(
                value: option,
                child: ListTile(
                  leading: ProviderIcon(option.provider),
                  title: Text(option.displayName),
                ),
              ),
          ],
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProviderIcon(channel.provider, size: 16),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
