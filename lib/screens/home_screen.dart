// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    // initialize Supabase stream for the 'channel_list' table
    _channelStream = Supabase.instance.client
        .from('channel_list')
        .stream(primaryKey: ['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      appBar: AppBar(
        title: const Text(
          'Channels',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        // automaticallyImplyLeading: false,
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

          final channelList = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: channelList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 16 / 10,
              ),
              itemBuilder: (context, index) {
                final channelMap = channelList[index];

                return _ChannelCard(
                  channelMap: channelMap,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoScreen(
                          url: channelMap['channel_link']?.toString() ?? '',
                          placeholderImage: channelMap['channel_image']?.toString(),
                          name: channelMap['channel_name']?.toString(),
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
            child: _buildImageOrPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    final rawImage = channelMap['channel_image'];
    final image = (rawImage == null) ? null : rawImage.toString().trim();

    if (image == null || image.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    // If image looks like a URL, use network; otherwise try asset
    final isNetwork = image.startsWith('http://') || image.startsWith('https://');

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isNetwork)
          Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
            return const Center(child: Icon(Icons.broken_image, size: 36));
          })
        else
          Image.asset(image, fit: BoxFit.cover),
        // optional gradient + title overlay
      
      ],
    );
  }
}
