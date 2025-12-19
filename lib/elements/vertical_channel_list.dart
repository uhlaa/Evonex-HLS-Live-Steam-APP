import 'package:evonex/controller/channel_repository.dart';
import 'package:evonex/elements/horizontal_channel.dart';
import 'package:evonex/elements/vertical_channel_tile.dart';
import 'package:evonex/models/channel.dart';
import 'package:evonex/screens/video_screen.dart';
import 'package:flutter/material.dart';

class VerticalChannelList extends StatefulWidget {
  final String? category;
  final ChannelTapCallback? onChannelTap;

  const VerticalChannelList({
    super.key,
    this.category,
    this.onChannelTap,
  });

  @override
  State<VerticalChannelList> createState() =>
      _VerticalChannelListState();
}

class _VerticalChannelListState extends State<VerticalChannelList> {
  late final Stream<List<Map<String, dynamic>>> _channelStream;

  @override
  void initState() {
    super.initState();
    _channelStream = ChannelRepository.streamChannels();
  }

  Channel _mapToChannel(Map<String, dynamic> map) {
    return Channel.fromMap(map);
  }

  List<Map<String, dynamic>> _filterByCategory(
    List<Map<String, dynamic>> raw,
  ) {
    if (widget.category == null) return raw;

    final cat = widget.category!.toLowerCase();
    return raw.where((row) {
      final rowCat =
          (row['channel_categories'] ?? '').toString().toLowerCase();
      return rowCat == cat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _channelStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = _filterByCategory(snapshot.data!);
        final channels = raw.map(_mapToChannel).toList();

        if (channels.isEmpty) {
          return const Center(child: Text('No channels found'));
        }

 return Column(

  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      "Sports Channel".toUpperCase(),
      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
    ),
    const SizedBox(height: 15),

    Expanded( // ✅ FIX
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final rawMap = raw[index];

          final videoState =
              context.findAncestorStateOfType<VideoScreenState>();

          final isPlaying =
              videoState?.currentUrl == channel.link;

          return VerticalChannelTile(
            key: ValueKey(channel.id),
            channel: channel,
            isPlaying: isPlaying,
            onTap: () => _onTap(context, channel, rawMap),
          );
        },
      ),
    ),
  ],
);

      },
    );
  }

  Future<void> _onTap(
    BuildContext context,
    Channel channel,
    Map<String, dynamic> rawMap,
  ) async {
    final link = channel.link.trim();
    if (link.isEmpty) return;

    if (widget.onChannelTap != null) {
      await widget.onChannelTap!(rawMap);
      return;
    }

    final videoState =
        context.findAncestorStateOfType<VideoScreenState>();

    if (videoState != null) {
      await videoState.changeStream(
        link,
        placeholderImage: channel.image,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoScreen(
          url: link,
          placeholderImage: channel.image,
          name: channel.name,
        ),
      ),
    );
  }
}
