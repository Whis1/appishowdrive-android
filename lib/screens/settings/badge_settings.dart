import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';

const identitySources = {
  'twitch': 'Badge Twitch',
  'ffz': 'Badge FrankerFaceZ',
  'bttv': 'Badge BetterTTV',
  'chatterino': 'Badge Chatterino',
  'pronouns': 'Pronomi scelti dagli utenti',
  '7tv': 'Colori e temi dei nickname 7TV',
};

class ChatIdentitySettings extends StatelessWidget {
  const ChatIdentitySettings({super.key});
  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleModel>();
    void all(bool visible) {
      for (final source in identitySources.keys) {
        style.hideBadges(source, !visible);
      }
      context.read<TwitchBadgeModel>().setAllEnabled(visible);
    }

    return Column(
      children: [
        const ListTile(
          title: Text(
            'Badge, pronomi e nickname',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Tutti attivi inizialmente. I pronomi sono quelli scelti dagli utenti nel servizio Pronomi Twitch.',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => all(true),
              child: const Text('Attiva tutto'),
            ),
            TextButton(
              onPressed: () => all(false),
              child: const Text('Disattiva tutto'),
            ),
          ],
        ),
        for (final source in identitySources.entries)
          CheckboxListTile(
            title: Text(source.value),
            value: style.badgesVisible(source.key),
            onChanged: (visible) {
              style.hideBadges(source.key, !(visible ?? false));
              if (source.key == 'twitch' && visible == true) {
                final badges = context.read<TwitchBadgeModel>();
                if (badges.enabledCount == 0) badges.setAllEnabled(true);
              }
            },
          ),
        ListTile(
          title: const Text('Scegli singoli badge Twitch'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/settings/badges'),
        ),
      ],
    );
  }
}

class BadgeSettingsScreen extends StatelessWidget {
  const BadgeSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badge e pronomi')),
      body: const SingleChildScrollView(child: ChatIdentitySettings()),
    );
  }
}
