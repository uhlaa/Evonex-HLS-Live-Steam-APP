// lib/screens/home_screen.dart

import 'package:evonex/controller/channel_repository.dart';
import 'package:flutter/material.dart';


import 'video_screen.dart';

class ALLChannelScreen extends StatefulWidget {
  const ALLChannelScreen({super.key});

  @override
  State<ALLChannelScreen> createState() => _ALLChannelScreenState();
}

class _ALLChannelScreenState extends State<ALLChannelScreen> {
  late final Stream<List<Map<String, dynamic>>> _channelStream;

  @override
  void initState() {
    super.initState();
    _channelStream = ChannelRepository.streamChannels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
           backgroundColor: Theme.of(context).colorScheme.tertiary,
        centerTitle: true,
         title: Text('All Channels', style: TextStyle( fontWeight: FontWeight.w700,fontSize: 20, color: Theme.of(context).colorScheme.inversePrimary,),),
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

          final channels = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: channels.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    final url =
                        channel['channel_link']?.toString() ?? '';

                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Channel link not available'),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoScreen(
                          url: url,
                          placeholderImage:
                              channel['channel_image']?.toString(),
                          name:
                              channel['channel_name']?.toString(),
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
    final raw = channelMap['channel_image'];
    final image = raw == null ? '' : raw.toString().trim();

    if (image.isEmpty) {
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
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 36),
            ),
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
          );
  }
}
