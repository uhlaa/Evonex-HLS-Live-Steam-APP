// lib/widgets/horizontal_channel_list.dart
import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../screens/video_screen.dart';

class HorizontalChannelList extends StatelessWidget {
  final List<Channel> channels;
  final String? category; // e.g. "sports", "news", "entertainment"
  final String title;
  final double height;
  final double cardWidth;

  const HorizontalChannelList({
    super.key,
    required this.channels,
    this.category,
    this.title = "Channels",
    this.height = 80,
    this.cardWidth = 140,
  });

  @override
  Widget build(BuildContext context) {
    // If category provided, filter case-insensitively
    final List<Channel> filtered = category == null
        ? channels
        : channels
            .where((c) =>
                (c.category ?? '').toLowerCase() == category!.toLowerCase())
            .toList();

    if (filtered.isEmpty) {
      // Show nothing or a small message — adjust as you prefer
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          category == null ? 'No channels available' : 'No channels in "$category"',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // optional title line that shows category if provided
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            category != null ? '${title} • ${category![0].toUpperCase()}${category!.substring(1)}' : title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final channel = filtered[index];

              return _HorizontalChannelCard(
                channel: channel,
                width: cardWidth,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoScreen(url: channel.link ?? ''),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HorizontalChannelCard extends StatelessWidget {
  final Channel channel;
  final double width;
  final VoidCallback onTap;

  const _HorizontalChannelCard({
    required this.channel,
    required this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (channel.image == null || channel.image!.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    return Image.asset(
      channel.image!,
      fit: BoxFit.cover,
    );
  }
}
