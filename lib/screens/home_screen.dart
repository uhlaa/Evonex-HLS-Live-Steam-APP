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
         
         title: Text('Live Channels', style: TextStyle( fontWeight: FontWeight.w700,fontSize: 18, color: Theme.of(context).colorScheme.inversePrimary,),),
         leading: IconButton(
  icon: Icon(
    Icons.arrow_back_ios_new,
    color: Theme.of(context).colorScheme.onSurface,
    size: 18,
  ),
  onPressed: () => Navigator.pop(context),
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

          final channels = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: channels.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
  crossAxisSpacing: 14,
  mainAxisSpacing: 14,
  childAspectRatio: .99,
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
    super.key,
    required this.channelMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: theme.colorScheme.tertiary,
          
          // boxShadow: [
          //   BoxShadow(
          //     color:  Color.fromARGB(255, 155, 238, 2).withOpacity(.12),
          //     blurRadius: 20,
          //     spreadRadius: 1,
          //   )
          // ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Channel Number
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:Color.fromARGB(255, 155, 238, 2).withOpacity(.12),
                  border: Border.all(
                    color:  Color.fromARGB(255, 155, 238, 2).withOpacity(.4),
                  ),
                ),
                child: Text(
                  "${(channelMap["id"] ?? 0).toString().padLeft(3, "0")}",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 155, 238, 2),
                    fontSize: 10,
      fontWeight: FontWeight.w900,
                  ),
                ),
              ),


              Expanded(
                child: Center(
                  child: _buildImage(),
                ),
              ),

             

              Text(
                channelMap["channel_name"] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),

            

              Text(
                channelMap["channel_categories"] ?? "Sports",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final image =
        (channelMap["channel_image"] ?? "").toString().trim();

    if (image.isEmpty) {
      return const Icon(
        Icons.tv,
        size: 65,
        color: Colors.white38,
      );
    }

    final isNetwork =
        image.startsWith("http://") ||
            image.startsWith("https://");

    return Center(
  child: SizedBox(
   
    height: 60,
    child: isNetwork
        ? Image.network(
            image,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image),
          )
        : Image.asset(
            image,
            fit: BoxFit.contain,
          ),
  ),
);
  }
}