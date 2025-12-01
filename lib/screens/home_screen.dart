// lib/screens/home_screen.dart
import 'package:evonex/models/channel_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/channel.dart';
import 'video_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Center(
        child: Text('No channels available'),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(250, 240, 240, 240),
      appBar: AppBar(
        title: Text('Channels', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              channel: channel,
              onTap: () {
                Get.to(VideoScreen(url: channel.link ?? ''),);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => VideoScreen(url: channel.link ?? ''),
                //   ),
                // );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channel,
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
    if (channel.image == null || channel.image!.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, size: 40, color: Colors.black26),
      );
    }

    // ONLY ASSET IMAGE
    return Image.asset(
      channel.image!,
      fit: BoxFit.fill,
    );
  }
}
