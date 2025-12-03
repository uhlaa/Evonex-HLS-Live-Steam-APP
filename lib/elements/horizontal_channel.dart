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

  // simple static tap-lock to debounce rapid double taps per link
  static final Set<String> _tapLocks = <String>{};

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
    final List<Channel> filtered = category == null
        ? channels
        : channels
            .where((c) =>
                (c.category ?? '').toLowerCase() == category!.toLowerCase())
            .toList();

    if (filtered.isEmpty) {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            category != null ? '${title} • ${category![0].toUpperCase()}${category!.substring(1)}' : title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
              final link = (channel.link ?? '').trim();

              return _HorizontalChannelCard(
                key: ValueKey('channel_${link.isEmpty ? index : link}_$index'),
                channel: channel,
                width: cardWidth,
                onTap: () async {
                  if (link.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No stream link available for this channel')),
                    );
                    return;
                  }

                  // basic URL-ish validation
                  final uri = Uri.tryParse(link);
                  if (uri == null || (uri.scheme.isEmpty && !link.startsWith('http'))) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid stream link')),
                    );
                    return;
                  }

                  // debounce per-link
                  if (_tapLocks.contains(link)) return;
                  _tapLocks.add(link);

                  try {
                    // If we're already inside a VideoScreen, change stream instead of navigating
                    final state = context.findAncestorStateOfType<VideoScreenState>();
                    if (state != null) {
                      try {
                        // pass channel.image so placeholder updates immediately
                        await state.changeStream(link, placeholderImage: channel.image);
                      } catch (e) {
                        debugPrint('changeStream failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not change stream')),
                        );
                      } finally {
                        _tapLocks.remove(link);
                      }
                      return;
                    }

                    // Not inside VideoScreen: push a new VideoScreen and pass placeholderImage
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoScreen(
                            url: link,
                            placeholderImage: channel.image,
                            name: channel.name,
                          ),
                        ),
                      );
                    } catch (pushError) {
                      debugPrint('Navigator.push failed: $pushError — trying pushReplacement');

                      // fallback: try pushReplacement instead of relying on VideoScreen.openReplace
                      try {
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => VideoScreen(
                              url: link,
                              placeholderImage: channel.image,
                              name: channel.name,
                            ),
                          ),
                        );
                      } catch (replaceError) {
                        debugPrint('pushReplacement also failed: $replaceError');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to open player')),
                        );
                      }
                    }
                  } finally {
                    // ensure lock removed
                    _tapLocks.remove(link);
                  }
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
    super.key,
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
    final img = channel.image;
    if (img == null || img.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    final lower = img.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.black26),
        ),
      );
    }

    return Image.asset(
      img,
      fit: BoxFit.cover,
    );
  }
}
