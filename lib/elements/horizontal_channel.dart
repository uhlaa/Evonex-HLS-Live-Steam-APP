// lib/widgets/horizontal_channel_list.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/channel.dart';
import '../screens/video_screen.dart';

typedef ChannelTapCallback = Future<void> Function(
    Map<String, dynamic> rawChannel);

class HorizontalChannelList extends StatefulWidget {
  /// Streams channels from Supabase `channel_list` table.
  final String? category; // e.g. "sports", "news", "entertainment"
  final String title;
  final double height;
  final double cardWidth;

  /// Optional callback executed when a channel is tapped. Receives raw map from Supabase.
  final ChannelTapCallback? onChannelTap;

  // static tap-lock to debounce rapid double taps per link
  static final Set<String> _tapLocks = <String>{};

  const HorizontalChannelList({
    super.key,
    this.category,
    this.title = "Channels",
    this.height = 80,
    this.cardWidth = 140,
    this.onChannelTap, required List<Channel> channels,
  });

  @override
  State<HorizontalChannelList> createState() => _HorizontalChannelListState();
}

class _HorizontalChannelListState extends State<HorizontalChannelList> {
  late final Stream<List<Map<String, dynamic>>> _channelStream;

  @override
  void initState() {
    super.initState();
    // stream rows from Supabase table "channel_list"
    _channelStream = Supabase.instance.client
        .from('channel_list')
        .stream(primaryKey: ['id'])
        .order('channel_name');
  }

  // Map raw Supabase row -> Channel model
  Channel _mapToChannel(Map<String, dynamic> m) => Channel.fromMap(m);

  List<Map<String, dynamic>> _applyCategoryFilterRaw(
      List<Map<String, dynamic>> raw) {
    if (widget.category == null) return raw;

    final lower = widget.category!.toLowerCase();
    return raw.where((m) {
      final cat =
          (m['channel_categories'] ?? '').toString().toLowerCase();
      return cat == lower;
    }).toList();
  }

  Widget _buildHeader() {
    final headerText = widget.category != null
        ? '${widget.title} • ${widget.category![0].toUpperCase()}${widget.category!.substring(1)}'
        : widget.title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        headerText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _channelStream,
      builder: (context, snapshot) {
        // header + loader while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              SizedBox(
                height: widget.height,
                child:
                    const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        // no data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              SizedBox(
                height: widget.height,
                child: Center(
                  child: Text(widget.category == null
                      ? 'No channels available'
                      : 'No channels in "${widget.category}"'),
                ),
              ),
            ],
          );
        }

        final raw = snapshot.data!;
        final filteredRaw = _applyCategoryFilterRaw(raw);
        final channels =
            filteredRaw.map((m) => _mapToChannel(m)).toList();

        if (channels.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              SizedBox(
                height: widget.height,
                child: Center(
                  child: Text(widget.category == null
                      ? 'No channels available'
                      : 'No channels in "${widget.category}"'),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            SizedBox(
              height: widget.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: channels.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final link = channel.link.trim();

                  // raw row (includes id, all fields)
                  final rawMap = filteredRaw[index];

                  return _HorizontalChannelCard(
                    key: ValueKey(
                        'channel_${channel.id}_${link}_$index'),
                    channel: channel,
                    width: widget.cardWidth,
                    onTap: () async {
                      if (link.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No stream link available for this channel')),
                        );
                        return;
                      }

                      // basic URL-ish validation
                      final uri = Uri.tryParse(link);
                      if (uri == null ||
                          (uri.scheme.isEmpty &&
                              !link.startsWith('http'))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Invalid stream link')),
                        );
                        return;
                      }

                      // debounce per-link
                      if (HorizontalChannelList._tapLocks
                          .contains(link)) return;
                      HorizontalChannelList._tapLocks.add(link);

                      try {
                        // if parent passed onChannelTap, use it
                        if (widget.onChannelTap != null) {
                          await widget.onChannelTap!(rawMap);
                          return;
                        }

                        // If we're already inside a VideoScreen, change stream instead of navigating
                        final state = context
                            .findAncestorStateOfType<VideoScreenState>();
                        if (state != null) {
                          try {
                            await state.changeStream(
                              link,
                              placeholderImage: channel.image,
                            );
                          } catch (e) {
                            debugPrint(
                                'changeStream failed: $e');
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Could not change stream')));
                          } finally {
                            HorizontalChannelList._tapLocks
                                .remove(link);
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
                          debugPrint(
                              'Navigator.push failed: $pushError — trying pushReplacement');

                          try {
                            await Navigator.of(context)
                                .pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => VideoScreen(
                                  url: link,
                                  placeholderImage: channel.image,
                                  name: channel.name,
                                ),
                              ),
                            );
                          } catch (replaceError) {
                            debugPrint(
                                'pushReplacement also failed: $replaceError');
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Unable to open player')));
                          }
                        }
                      } finally {
                        HorizontalChannelList._tapLocks
                            .remove(link);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
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
    if (img.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    final lower = img.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            const Center(
          child: Icon(Icons.broken_image,
              size: 32, color: Colors.black26),
        ),
      );
    }

    // assume asset path
    return Image.asset(
      img,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
