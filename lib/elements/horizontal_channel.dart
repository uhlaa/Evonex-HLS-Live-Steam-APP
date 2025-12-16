import 'package:evonex/controller/channel_repository.dart';
import 'package:flutter/material.dart';


import '../models/channel.dart';
import '../screens/video_screen.dart';

typedef ChannelTapCallback = Future<void> Function(
  Map<String, dynamic> rawChannel,
);

class HorizontalChannelList extends StatefulWidget {
  final String? category; // sports, news, entertainment, kids
  final String title;
  final double height;
  final double cardWidth;
  final ChannelTapCallback? onChannelTap;

  /// tap lock to prevent double tap
  static final Set<String> _tapLocks = <String>{};

  const HorizontalChannelList({
    super.key,
    this.category,
    this.title = "Channels",
    this.height = 80,
    this.cardWidth = 140,
    this.onChannelTap,
  });

  @override
  State<HorizontalChannelList> createState() =>
      _HorizontalChannelListState();
}

class _HorizontalChannelListState
    extends State<HorizontalChannelList> {
  late final Stream<List<Map<String, dynamic>>> _channelStream;

  @override
  void initState() {
    super.initState();
    _channelStream = ChannelRepository.streamChannels();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
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

  Widget _buildHeader() {
    final title = widget.category != null
        ? '${widget.category![0].toUpperCase()}${widget.category!.substring(1)} Channel'
        : '${widget.title} Channel';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context)
              .colorScheme
              .inversePrimary,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _channelStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoading();
        }

        final raw = snapshot.data!;
        final filteredRaw = _filterByCategory(raw);
        final channels =
            filteredRaw.map(_mapToChannel).toList();

        if (channels.isEmpty) {
          return _buildEmpty();
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
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final rawMap = filteredRaw[index];

                  return _HorizontalChannelCard(
                    key: ValueKey(
                      'channel_${channel.id}_${channel.link}_$index',
                    ),
                    channel: channel,
                    width: widget.cardWidth,
                    onTap: () => _onTap(
                      context,
                      channel,
                      rawMap,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.height,
          child: Center(
            child: Text(
              widget.category == null
                  ? 'No channels available'
                  : 'No channels in "${widget.category}"',
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TAP HANDLER
  // ------------------------------------------------------------
  Future<void> _onTap(
    BuildContext context,
    Channel channel,
    Map<String, dynamic> rawMap,
  ) async {
    final link = channel.link.trim();

    if (link.isEmpty) {
      _snack(context, 'No stream link available');
      return;
    }

    if (HorizontalChannelList._tapLocks.contains(link)) {
      return;
    }
    HorizontalChannelList._tapLocks.add(link);

    try {
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

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            url: link,
            placeholderImage: channel.image,
            name: channel.name,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Channel tap error: $e');
      _snack(context, 'Unable to open player');
    } finally {
      HorizontalChannelList._tapLocks.remove(link);
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ------------------------------------------------------------
// CHANNEL CARD
// ------------------------------------------------------------
class _HorizontalChannelCard extends StatelessWidget {
  final Channel channel;
  final double width;
  final VoidCallback onTap;

  const _HorizontalChannelCard({
    super.key,
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
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

    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 32),
        ),
      );
    }

    return Image.asset(
      img,
      fit: BoxFit.cover,
    );
  }
}
