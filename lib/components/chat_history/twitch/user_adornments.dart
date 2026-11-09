import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_identity.dart';
import 'package:rtchat/models/style.dart';

class UserAdornments extends StatelessWidget {
  final String userId, login;
  final double size;
  const UserAdornments({
    super.key,
    required this.userId,
    required this.login,
    required this.size,
  });
  @override
  Widget build(BuildContext context) {
    final identity = context.watch<ChatIdentityModel?>(),
        style = context.watch<StyleModel>();
    if (identity == null) return const SizedBox.shrink();
    final visible =
        ChatIdentityModel.sources.keys.where(style.badgesVisible).toList();
    unawaited(identity.ensureBadges(visible));
    if (style.badgesVisible('pronouns')) identity.ensurePronouns(userId, login);
    final badges = identity.badgesFor(userId, visible),
        pronouns =
            style.badgesVisible('pronouns')
                ? identity.pronounsFor(userId)
                : null;
    if (badges.isEmpty && pronouns == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final badge in badges)
            Tooltip(
              message: badge.title,
              child:
                  Uri.parse(badge.url).path.endsWith('.svg')
                      ? SvgPicture.network(
                        badge.url,
                        height: size,
                        width: size,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                      : Image(
                        image: CachedNetworkImageProvider(badge.url),
                        height: size,
                        width: size,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
            ),
          if (pronouns != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                pronouns,
                style: TextStyle(
                  fontSize: size * .56,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
