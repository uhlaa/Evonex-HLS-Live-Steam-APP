// import 'package:evonex/elements/live_match_card.dart';
// import 'package:evonex/screens/video_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class HomeScreens extends StatefulWidget {
//   const HomeScreens({super.key});

//   @override
//   State<HomeScreens> createState() => _HomeScreensState();
// }

// class _HomeScreensState extends State<HomeScreens> {
//   late final Stream<List<Map<String, dynamic>>> _matchStream;
//   late final Future<Map<int, Team>> _teamMapFuture;

//   @override
//   void initState() {
//     super.initState();

//     // live_match table stream
//     _matchStream = Supabase.instance.client
//         .from('live_match')
//         .stream(primaryKey: ['id']);

//     // load all teams from team table
//     _teamMapFuture = _loadTeams();
//   }

//   Future<Map<int, Team>> _loadTeams() async {
//     final supabase = Supabase.instance.client;
//     final data = await supabase.from('team').select();

//     final List<dynamic> rows = data as List<dynamic>;
//     final Map<int, Team> result = {};

//     for (final row in rows) {
//       final map = row as Map<String, dynamic>;
//       final int id = map['id'] as int;

//       result[id] = Team(
//         id: id,
//         name: map['name'] ?? '',
//         logoUrl: map['logo_url'],
//         league: map['league'],
//       );
//     }

//     return result;
//   }

//   DateTime _parseMatchTime(dynamic value) {
//     if (value is DateTime) return value;
//     if (value is String) return DateTime.parse(value);
//     throw Exception('Invalid match_start_time: $value');
//   }

//   Future<void> _openChannelById(int channelId) async {
//     try {
//       final supabase = Supabase.instance.client;

//       final channel = await supabase
//           .from('channel_list')
//           .select()
//           .eq('id', channelId)
//           .maybeSingle();

//       if (channel == null) {
//         debugPrint('Channel not found for id $channelId');
//         return;
//       }

//       if (!mounted) return;

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => VideoScreen(
//             url: channel['channel_link']?.toString() ?? '',
//             placeholderImage: channel['channel_image']?.toString(),
//             name: channel['channel_name']?.toString(),
//           ),
//         ),
//       );
//     } catch (e) {
//       debugPrint('Error loading channel: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 244, 244, 244),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           "LumiCast",
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: FutureBuilder<Map<int, Team>>(
//         future: _teamMapFuture,
//         builder: (context, teamSnapshot) {
//           if (teamSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (teamSnapshot.hasError) {
//             return Center(
//               child: Text('Error loading teams: ${teamSnapshot.error}'),
//             );
//           }

//           final teamMap = teamSnapshot.data ?? {};

//           return StreamBuilder<List<Map<String, dynamic>>>(
//             stream: _matchStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               final matches = snapshot.data ?? [];

//               final now = DateTime.now();
//               final today = DateTime(now.year, now.month, now.day);

//               // 🔥 SHOW TODAY'S MATCHES + FUTURE MATCHES
//               final visibleMatches = matches.where((match) {
//                 final start = _parseMatchTime(match['match_start_time']);
//                 final startDate = DateTime(start.year, start.month, start.day);

//                 return !startDate.isBefore(today);
//                 // meaning → show if startDate >= today
//               }).toList();

//               // Sort: nearest match first
//               visibleMatches.sort((a, b) {
//                 final t1 = _parseMatchTime(a['match_start_time']);
//                 final t2 = _parseMatchTime(b['match_start_time']);
//                 return t1.compareTo(t2);
//               });

//               if (visibleMatches.isEmpty) {
//                 return const Center(
//                     child: Text('No matches today or upcoming'));
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: visibleMatches.length,
//                 itemBuilder: (context, index) {
//                   final match = visibleMatches[index];

//                   final int? teamAId = match['team_a_id'] as int?;
//                   final int? teamBId = match['team_b_id'] as int?;

//                   final Team teamA =
//                       (teamAId != null && teamMap.containsKey(teamAId))
//                           ? teamMap[teamAId]!
//                           : Team(id: -1, name: 'Team A', logoUrl: null);

//                   final Team teamB =
//                       (teamBId != null && teamMap.containsKey(teamBId))
//                           ? teamMap[teamBId]!
//                           : Team(id: -2, name: 'Team B', logoUrl: null);

//                   return LiveMatchCard(
//                     matchName: match['match_name'] ?? '',
//                     matchCategories: match['match_categories'],
//                     teamA: teamA,
//                     teamB: teamB,
//                     isLive: (match['is_live'] ?? false) as bool,
//                     matchStartTime: _parseMatchTime(match['match_start_time']),
//                     onTap: () {
//                       final channelId = match['live_video_url'] as int?;
//                       if (channelId == null) {
//                         debugPrint(
//                             'live_video_url is null for match ${match['id']}');
//                         return;
//                       }
//                       _openChannelById(channelId);
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:evonex/elements/live_match_card.dart';
import 'package:evonex/screens/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  late final Stream<List<Map<String, dynamic>>> _matchStream;
  late final Future<Map<int, Team>> _teamMapFuture;

  @override
  void initState() {
    super.initState();

    // live_match table stream
    _matchStream = Supabase.instance.client
        .from('live_match')
        .stream(primaryKey: ['id']);

    // load all teams from `team` table
    _teamMapFuture = _loadTeams();
  }

  Future<Map<int, Team>> _loadTeams() async {
    final supabase = Supabase.instance.client;
    final data = await supabase.from('team').select();

    final List<dynamic> rows = data as List<dynamic>;
    final Map<int, Team> result = {};

    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final int id = map['id'] as int;

      result[id] = Team(
        id: id,
        name: map['name'] ?? '',
        logoUrl: map['logo_url'],
        league: map['league'],
      );
    }

    return result;
  }

  DateTime _parseMatchTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw Exception('Invalid match_start_time: $value');
  }

  Future<void> _openChannelById(int channelId) async {
    try {
      final supabase = Supabase.instance.client;

      final channel = await supabase
          .from('channel_list')
          .select()
          .eq('id', channelId)
          .maybeSingle();

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
      ),
      body: FutureBuilder<Map<int, Team>>(
        future: _teamMapFuture,
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (teamSnapshot.hasError) {
            return Center(
              child: Text('Error loading teams: ${teamSnapshot.error}'),
            );
          }

          final teamMap = teamSnapshot.data ?? {};

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _matchStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final matches = snapshot.data ?? [];

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              // 🔥 শুধুমাত্র আজকের তারিখের match দেখাবে
              final visibleMatches = matches.where((match) {
                final startUtc =
                    _parseMatchTime(match['match_start_time']); // from DB
                final startLocal = startUtc.toLocal(); // BD/local time
                final startDate = DateTime(
                  startLocal.year,
                  startLocal.month,
                  startLocal.day,
                );

                // show only if startDate == today
                return startDate.isAtSameMomentAs(today);
              }).toList();

              // Sort: nearest match first (time অনুযায়ী)
              visibleMatches.sort((a, b) {
                final t1 = _parseMatchTime(a['match_start_time']);
                final t2 = _parseMatchTime(b['match_start_time']);
                return t1.compareTo(t2);
              });

              if (visibleMatches.isEmpty) {
                return const Center(
                  child: Text('No matches today'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visibleMatches.length,
                itemBuilder: (context, index) {
                  final match = visibleMatches[index];

                  final int? teamAId = match['team_a_id'] as int?;
                  final int? teamBId = match['team_b_id'] as int?;

                  final Team teamA =
                      (teamAId != null && teamMap.containsKey(teamAId))
                          ? teamMap[teamAId]!
                          : Team(id: -1, name: 'Team A', logoUrl: null);

                  final Team teamB =
                      (teamBId != null && teamMap.containsKey(teamBId))
                          ? teamMap[teamBId]!
                          : Team(id: -2, name: 'Team B', logoUrl: null);

                  return LiveMatchCard(
                    matchName: match['match_name'] ?? '',
                    matchCategories: match['match_categories'],
                    teamA: teamA,
                    teamB: teamB,
                    isLive: (match['is_live'] ?? false) as bool,
                    matchStartTime: _parseMatchTime(match['match_start_time']),
                    onTap: () {
                      final channelId = match['live_video_url'] as int?;
                      if (channelId == null) {
                        debugPrint(
                            'live_video_url is null for match ${match['id']}');
                        return;
                      }
                      _openChannelById(channelId);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
