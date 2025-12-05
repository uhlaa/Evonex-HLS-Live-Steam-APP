import 'package:evonex/elements/live_match_card.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:evonex/screens/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  late final Stream<List<Map<String, dynamic>>> _matchStream;

  @override
  void initState() {
    super.initState();
    // Stream from 'live_match' table
    _matchStream = Supabase.instance.client
        .from('live_match')
        .stream(primaryKey: ['id']);
  }

  /// 🔹 Open channel by FK id from live_match.live_video_url
  Future<void> _openChannelById(int channelId) async {
    try {
      final supabase = Supabase.instance.client;

      final channel = await supabase
          .from('channel_list')
          .select()
          .eq('id', channelId)
          .maybeSingle(); // Map<String, dynamic>? or null

      if (channel == null) {
        debugPrint('Channel not found for id $channelId');
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            url: channel['channel_link']?.toString() ?? '',
            placeholderImage: channel['channel_image']?.toString(),
            name: channel['channel_name']?.toString(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading channel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "LumiCast",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(onPressed: (){
Get.to(ALLChannelScreen());
          }, icon: Icon(Icons.tv))
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _matchStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No live matches'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];

              return LiveMatchCard(
                matchName: match['match_name'] ?? '',
                matchCategories: match['match_categories'],
                teamAName: match['team_a_name'] ?? '',
                teamAImage: match['team_a_image'] ?? '',
                teamBName: match['team_b_name'] ?? '',
                teamBImage: match['team_b_image'] ?? '',
                isLive: (match['is_live'] ?? false) as bool,
                onTap: () {
                  final channelId = match['live_video_url'] as int?;
                  if (channelId == null) {
                    debugPrint('live_video_url is null for match ${match['id']}');
                    return;
                  }
                  _openChannelById(channelId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
