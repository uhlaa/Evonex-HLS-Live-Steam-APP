// lib/screens/match_home_screen.dart

import 'package:evonex/elements/live_match_card.dart';
import 'package:evonex/elements/match_tab.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:evonex/screens/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchHomeScreen extends StatefulWidget {
  const MatchHomeScreen({super.key});

  @override
  State<MatchHomeScreen> createState() => _MatchHomeScreenState();
}

class _MatchHomeScreenState extends State<MatchHomeScreen> {
  late final Stream<List<Map<String, dynamic>>> _matchStream;
  late final Future<Map<int, Team>> _teamMapFuture;

  /// ALL / CRICKET / FOOTBALL
  String _currentFilter = 'ALL';

  @override
  void initState() {
    super.initState();

    // live_match table stream
    _matchStream = Supabase.instance.client.from('live_match').stream(primaryKey: ['id']);

    // load all teams from `team` table
    _teamMapFuture = _loadTeams();
  }

  /// team table: id, name, logo_url, league
  Future<Map<int, Team>> _loadTeams() async {
    final supabase = Supabase.instance.client;
    final data = await supabase.from('team').select();

    final List<dynamic> rows = data as List<dynamic>;
    final Map<int, Team> result = {};

    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final rawId = map['id'];
      if (rawId == null) continue;

      final int? id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id == null) continue;

      result[id] = Team(
        id: id,
        name: (map['name'] ?? map['team_name'] ?? 'UNKNOWN TEAM').toString(),
        logoUrl: (map['logo_url'] ?? map['team_logo_url'])?.toString(),
        league: map['league']?.toString(),
      );
    }

    return result;
  }

  /// Safe parser: returns null if value is null or can't be parsed.
  DateTime? _parseMatchTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is DateTime) return value;
      if (value is String) {
        if (value.trim().isEmpty) return null;
        return DateTime.parse(value);
      }
      // sometimes Supabase returns a map/object or int timestamp
      if (value is int) {
        // treat as epoch millis if obviously large, else epoch seconds
        if (value > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
        }
      }
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _openChannelById(int channelId) async {
    try {
      final supabase = Supabase.instance.client;

      final channel = await supabase.from('channel_list').select().eq('id', channelId).maybeSingle();

      if (channel == null) {
        debugPrint('Channel not found for id $channelId');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel not found')),
        );
        return;
      }

      if (!mounted) return;

      final url = channel['channel_link']?.toString() ?? '';
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel link is empty')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoScreen(
            url: url,
            placeholderImage: channel['channel_image']?.toString(),
            name: channel['channel_name']?.toString(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading channel: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open channel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Matches",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.to(ALLChannelScreen());
            },
            icon: Icon(Icons.tv_rounded, color: Colors.black54),
          )
        ],
      ),
      body: Column(
        children: [
          // 🔼 Top TabBar (ALL / CRICKET / FOOTBALL)
          MatchCategoryTabs(
            initial: _currentFilter,
            onChanged: (value) {
              setState(() {
                _currentFilter = value;
              });
            },
          ),

          Expanded(
            child: FutureBuilder<Map<int, Team>>(
              future: _teamMapFuture,
              builder: (context, teamSnapshot) {
                if (teamSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (teamSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading teams: ${teamSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
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
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final matches = snapshot.data ?? [];

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // 🔥 1) শুধু TODAY & TOMORROW match রাখি (null-safe)
                    final filteredByDate = matches.where((match) {
                      final startUtc = _parseMatchTime(match['match_start_time']);
                      if (startUtc == null) return false; // can't determine day -> skip

                      final startLocal = startUtc.toLocal();
                      final matchDay = DateTime(startLocal.year, startLocal.month, startLocal.day);

                      final diffDays = matchDay.difference(today).inDays;
                      return diffDays == 0 || diffDays == 1;
                    }).toList();

                    // ⚡ 2) এইগুলো থেকে match_end_time পেরিয়ে গেলে drop করব (expired)
                    final filteredByEndTime = filteredByDate.where((match) {
                      final startUtc = _parseMatchTime(match['match_start_time']);
                      final endUtc = _parseMatchTime(match['match_end_time']);

                      // if start missing, skip; if end missing, assume 3 hours after start
                      if (startUtc == null) return false;

                      final DateTime start = startUtc.toUtc();
                      final DateTime end = (endUtc ?? start.add(const Duration(hours: 3))).toUtc();

                      final nowUtc = DateTime.now().toUtc();

                      // show match only if current time is before end
                      return nowUtc.isBefore(end);
                    }).toList();

                    // 🔥 3) Category filter (ALL / CRICKET / FOOTBALL) applied on end-time filtered list
                    final filteredByCategory = filteredByEndTime.where((match) {
                      if (_currentFilter == 'ALL') return true;

                      final cat = (match['match_categories'] ?? '').toString().toUpperCase();
                      return cat.contains(_currentFilter.toUpperCase());
                    }).toList();

                    // 🔁 Sort: nearest match first (null-safe)
                    filteredByCategory.sort((a, b) {
                      final t1 = _parseMatchTime(a['match_start_time']) ?? DateTime.now().toUtc();
                      final t2 = _parseMatchTime(b['match_start_time']) ?? DateTime.now().toUtc();
                      return t1.compareTo(t2);
                    });

                    if (filteredByCategory.isEmpty) {
                      return const Center(
                        child: Text('No matches for selected filter'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredByCategory.length,
                      itemBuilder: (context, index) {
                        final match = filteredByCategory[index];

                        final int? teamAId = match['team_a_id'] as int?;
                        final int? teamBId = match['team_b_id'] as int?;

                        final Team teamA = (teamAId != null && teamMap.containsKey(teamAId))
                            ? teamMap[teamAId]!
                            : Team(
                                id: -1,
                                name: 'TEAM A',
                                logoUrl: null,
                              );

                        final Team teamB = (teamBId != null && teamMap.containsKey(teamBId))
                            ? teamMap[teamBId]!
                            : Team(
                                id: -2,
                                name: 'TEAM B',
                                logoUrl: null,
                              );

                        // parse start and end safely (use UTC for comparisons)
                        final DateTime start =
                            (_parseMatchTime(match['match_start_time']) ?? DateTime.now().toUtc()).toUtc();

                        final DateTime end = ((_parseMatchTime(match['match_end_time']) ?? start.add(const Duration(hours: 3)))
                                .toUtc());

                        return LiveMatchCard(
                          matchName: match['match_name']?.toString() ?? '',
                          matchCategories: match['match_categories']?.toString(),
                          teamA: teamA,
                          teamB: teamB,
                          isLive: (match['is_live'] ?? false) as bool,
                          matchStartTime: start,
                          matchEndTime: end, // <-- ensures card knows end time
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
