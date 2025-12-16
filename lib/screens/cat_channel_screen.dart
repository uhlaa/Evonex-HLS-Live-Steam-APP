// lib/screens/category_channels_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_screen.dart';

class CategoryChannelsScreen extends StatefulWidget {
  final String category; // sports / news / entertainment / kids

  const CategoryChannelsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryChannelsScreen> createState() =>
      _CategoryChannelsScreenState();
}

class _CategoryChannelsScreenState
    extends State<CategoryChannelsScreen> {
  late final Stream<List<Map<String, dynamic>>> _channelStream;

  @override
  void initState() {
    super.initState();

    _channelStream = Supabase.instance.client
        .from('channel_list')
        .stream(primaryKey: ['id'])
        .order('channel_name');
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          '${_capitalize(widget.category)} Channel',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _channelStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No channels available'),
            );
          }

          /// 🔥 CATEGORY FILTER
          final channels = snapshot.data!.where((m) {
            final cat = (m['channel_categories'] ?? '')
                .toString()
                .toLowerCase();
            return cat == widget.category.toLowerCase();
          }).toList();

          if (channels.isEmpty) {
            return Center(
              child: Text(
                'No channels in ${widget.category}',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: channels.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 16 / 10,
              ),
              itemBuilder: (context, index) {
                final channel = channels[index];

                return _ChannelCard(
                  channelMap: channel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoScreen(
                          url: channel['channel_link']?.toString() ?? '',
                          placeholderImage:
                              channel['channel_image']?.toString(),
                          name: channel['channel_name']?.toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Map<String, dynamic> channelMap;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channelMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final rawImage = channelMap['channel_image'];
    final image =
        rawImage == null ? null : rawImage.toString().trim();

    if (image == null || image.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    final isNetwork =
        image.startsWith('http://') || image.startsWith('https://');

    return isNetwork
        ? Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image),
          )
        : Image.asset(image, fit: BoxFit.cover);
  }
}
