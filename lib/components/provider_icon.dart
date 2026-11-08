import 'package:flutter/material.dart';
import 'package:rtchat/models/channels.dart';

/// A small icon identifying a streaming platform.
class ProviderIcon extends StatelessWidget {
  final String provider;
  final double size;

  const ProviderIcon(this.provider, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    switch (provider) {
      case Providers.twitch:
        return Image.asset(
          'assets/providers/twitch.png',
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.contain,
        );
      case Providers.kick:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF53FC18),
            borderRadius: BorderRadius.circular(size / 5),
          ),
          child: Text(
            "K",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.7,
              height: 1,
            ),
          ),
        );
    }
    return Icon(Icons.public, size: size);
  }
}

/// Compact platform logo; its name is available to screen readers only.
class ChatPlatformBadge extends StatelessWidget {
  final String provider;
  const ChatPlatformBadge(this.provider, {super.key});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Messaggio da ${providerName(provider)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ProviderIcon(provider, size: 16),
        ),
      ),
    );
  }
}

/// Keeps provider identity at the right edge, separate from role/sub badges.
class PlatformChatRow extends StatelessWidget {
  final String provider;
  final Widget child;
  const PlatformChatRow({
    super.key,
    required this.provider,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: child),
      Padding(
        padding: const EdgeInsets.only(top: 7),
        child: ChatPlatformBadge(provider),
      ),
    ],
  );
}
