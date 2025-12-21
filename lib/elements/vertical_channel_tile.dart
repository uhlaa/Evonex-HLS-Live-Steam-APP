import 'package:cached_network_image/cached_network_image.dart';
import 'package:evonex/elements/palying_equlizer.dart';
import 'package:evonex/models/channel.dart';
import 'package:flutter/material.dart';

class VerticalChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onTap;

  const VerticalChannelTile({
    super.key,
    required this.channel,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFFFF4C5B).withOpacity(.10)
              : theme.colorScheme.tertiary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            /// 🔧 LOGO BOX (uniform container)
            Container(
              width: 70,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.05),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: CachedNetworkImage(
                imageUrl: channel.image,
                fit: BoxFit.contain,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (context, url, error) => const Icon(
                  Icons.tv,
                  size: 26,
                  color: Colors.white54,
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// NAME
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.inversePrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 8),

            /// 🔧 RIGHT ICON (circular play button)
            isPlaying
                ? const PlayingEqualizer()
                : Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.05),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.inversePrimary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
