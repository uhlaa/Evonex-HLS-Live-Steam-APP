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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFFFF4C5B).withOpacity(.10)
              : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            /// ✅ LOGO (FIXED – cached)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: channel.image,
                width: 70,
                height: 44,
    
                fadeInDuration: const Duration(milliseconds: 0),
                fadeOutDuration: const Duration(milliseconds: 0),
                placeholder: (context, url) => Container(
                  width: 70,
                  height: 44,
                  color: Colors.grey.shade300,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.tv,
                  size: 32,
                  color: Colors.white54,
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// NAME
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// RIGHT ICON
            isPlaying
                ? const PlayingEqualizer()
                : Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
          ],
        ),
      ),
    );
  }
}
