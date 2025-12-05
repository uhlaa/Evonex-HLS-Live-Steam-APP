import 'package:evonex/elements/live_badge.dart';
import 'package:flutter/material.dart';

class LiveMatchCard extends StatelessWidget {
  final String matchName;
  final String? matchCategories;
  final String teamAName;
  final String teamAImage;
  final String teamBName;
  final String teamBImage;
  final bool isLive;
  final VoidCallback? onTap; // 🔹 callback from parent

  const LiveMatchCard({
    super.key,
    required this.matchName,
    this.matchCategories,
    required this.teamAName,
    required this.teamAImage,
    required this.teamBName,
    required this.teamBImage,
    this.isLive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // 🔹 use callback
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: match name + LIVE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matchName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (matchCategories != null &&
                          matchCategories!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            matchCategories!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLive)
                  LiveBadge()
              ],
            ),

            const SizedBox(height: 12),

            // Middle row: logos + VS + team names
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TeamBlock(
                  name: teamAName,
                  imageUrl: teamAImage,
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _TeamBlock(
                  name: teamBName,
                  imageUrl: teamBImage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _TeamBlock({
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: imageUrl.trim().isEmpty
              ? const Icon(Icons.sports_cricket, size: 32)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
