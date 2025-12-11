// lib/screens/match_home_screen.dart

import 'package:evonex/elements/live_match_card.dart';
import 'package:evonex/elements/match_tab.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:evonex/screens/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchHomeScreen extends StatefulWidget {
  const MatchHomeScreen({super.key});

  @override
  State<MatchHomeScreen> createState() => _MatchHomeScreenState();
}

class _MatchHomeScreenState extends State<MatchHomeScreen> {
  // keep stream type loose to avoid cast problems with Supabase realtime payloads
  late final Stream _matchStream;
  late final Future<Map<int, Team>> _teamMapFuture;

  /// ALL / CRICKET / FOOTBALL
  String _currentFilter = 'ALL';

  @override
  void initState() {
    super.initState();

    // live_match table stream (primaryKey ensures realtime diffing)
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

  /// Safe parser for full timestamp-like values (ISO / epoch)
  DateTime? _parseDateTimeSafe(dynamic value) {
    if (value == null) return null;

    try {
      if (value is DateTime) return value;
      if (value is String) {
        if (value.trim().isEmpty) return null;
        return DateTime.parse(value);
      }
      if (value is int) {
        // epoch seconds vs millis
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

  /// Build an end DateTime in UTC from either:
  ///  - full timestamp (ISO) stored in DB OR
  ///  - time-only string (e.g. "04:30:00" or "12:30 AM") stored in DB as time without date.
  /// If time-only is provided, it uses the startUtc's local date (and adds 1 day if end <= start).
  DateTime buildEndUtcUsingStartLocal(DateTime startUtc, dynamic endRaw) {
    // fallback: 3 hours after start (UTC)
    if (endRaw == null) return startUtc.add(const Duration(hours: 3));

    // 1) if endRaw is a full timestamp, parse it and use (normalize cross-day)
    try {
      if (endRaw is DateTime) {
        final dt = endRaw.toUtc();
        return dt.isAfter(startUtc) ? dt : dt.add(const Duration(days: 1));
      }
      final parsed = DateTime.tryParse(endRaw.toString());
      if (parsed != null) {
        final dt = parsed.toUtc();
        return dt.isAfter(startUtc) ? dt : dt.add(const Duration(days: 1));
      }
    } catch (_) {}

    // 2) Otherwise interpret endRaw as a local time string (same local zone as start).
    final startLocal = startUtc.toLocal();
    final localDate = DateTime(startLocal.year, startLocal.month, startLocal.day);

    String s = endRaw.toString().trim();

    // parse "12:30 AM/PM" or "hh:mm[:ss] am/pm"
    final ampmMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)$', caseSensitive: false).firstMatch(s);
    if (ampmMatch != null) {
      int h = int.parse(ampmMatch.group(1)!);
      final int min = int.parse(ampmMatch.group(2)!);
      final int sec = ampmMatch.group(3) != null ? int.parse(ampmMatch.group(3)!) : 0;
      final isPm = ampmMatch.group(4)!.toLowerCase() == 'pm';
      if (h == 12) {
        h = isPm ? 12 : 0;
      } else if (isPm) {
        h += 12;
      }

      DateTime candidateLocal = DateTime(localDate.year, localDate.month, localDate.day, h, min, sec);
      if (!candidateLocal.isAfter(startLocal)) candidateLocal = candidateLocal.add(const Duration(days: 1));
      return candidateLocal.toUtc();
    }

    // parse plain "HH:mm" or "HH:mm:ss"
    final parts = s.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.isNotEmpty) {
      final h = parts[0];
      final m = parts.length > 1 ? parts[1] : 0;
      final sec = parts.length > 2 ? parts[2] : 0;
      DateTime candidateLocal = DateTime(localDate.year, localDate.month, localDate.day, h, m, sec);
      if (!candidateLocal.isAfter(startLocal)) candidateLocal = candidateLocal.add(const Duration(days: 1));
      return candidateLocal.toUtc();
    }

    // final fallback
    return startUtc.add(const Duration(hours: 3));
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

  bool _isLiveValue(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 't' || s == 'yes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: SvgPicture.asset(
          'assets/images/golazos.svg',
          height: 28,
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
                  // map the loose stream into the expected shape safely
                  stream: _matchStream.map((event) {
                    try {
                      final List<dynamic> raw = event as List<dynamic>;
                      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                    } catch (_) {
                      return <Map<String, dynamic>>[];
                    }
                  }),
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

                    final nowLocal = DateTime.now();
                    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
                    final nowUtc = DateTime.now().toUtc();

                    // ----------------------------------------------------------------
                    // IMPORTANT: Keep ended matches visible until DB row is deleted.
                    // So we DO NOT filter-out by end-time here.
                    // ----------------------------------------------------------------
                    final filteredByDate = matches.toList();

                    // ------------------------------------------------------------
                    // filteredByEndTime is same as filteredByDate (keeps ended rows)
                    // ------------------------------------------------------------
                    final filteredByEndTime = List<Map<String, dynamic>>.from(filteredByDate);

                    // 3) Category filter (ALL / CRICKET / FOOTBALL)
                    final filteredByCategory = filteredByEndTime.where((match) {
                      if (_currentFilter == 'ALL') return true;

                      final cat = (match['match_categories'] ?? '').toString().toUpperCase();
                      return cat.contains(_currentFilter.toUpperCase());
                    }).toList();

                    // 4) Sort: LIVE -> UPCOMING -> ENDED, stable within-group ordering
                    filteredByCategory.sort((a, b) {
                      final nowUtc = DateTime.now().toUtc();

                      final DateTime t1Start = (_parseDateTimeSafe(a['match_start_time']) ?? DateTime.now().toUtc()).toUtc();
                      final DateTime t2Start = (_parseDateTimeSafe(b['match_start_time']) ?? DateTime.now().toUtc()).toUtc();

                      final DateTime t1End = buildEndUtcUsingStartLocal(t1Start, a['match_end_time']);
                      final DateTime t2End = buildEndUtcUsingStartLocal(t2Start, b['match_end_time']);

                      int status(DateTime start, DateTime end, dynamic rawIsLive) {
                        final bool dbLive = _isLiveValue(rawIsLive);
                        final bool timeLive = (nowUtc.isAtSameMomentAs(start) || nowUtc.isAfter(start)) &&
                            (nowUtc.isAtSameMomentAs(end) || nowUtc.isBefore(end));
                        if (dbLive || timeLive) return 0; // live
                        if (nowUtc.isBefore(start)) return 1; // upcoming
                        return 2; // ended
                      }

                      final s1 = status(t1Start, t1End, a['is_live']);
                      final s2 = status(t2Start, t2End, b['is_live']);

                      // primary by status
                      if (s1 != s2) return s1.compareTo(s2);

                      // within same status group:
                      if (s1 == 0) {
                        // both live -> earliest start first
                        return t1Start.compareTo(t2Start);
                      } else if (s1 == 1) {
                        // both upcoming -> nearest start first
                        return t1Start.compareTo(t2Start);
                      } else {
                        // both ended -> most recently ended first
                        return t2End.compareTo(t1End);
                      }
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

                        final int? teamAId = match['team_a_id'] is int
                            ? match['team_a_id'] as int
                            : (int.tryParse(match['team_a_id']?.toString() ?? ''));

                        final int? teamBId = match['team_b_id'] is int
                            ? match['team_b_id'] as int
                            : (int.tryParse(match['team_b_id']?.toString() ?? ''));

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

                        // parse start safely (use UTC for comparisons)
                        final DateTime startUtc =
                            (_parseDateTimeSafe(match['match_start_time']) ?? DateTime.now().toUtc()).toUtc();

                        // build a normalized end UTC (handles time-only and cross-midnight)
                        final DateTime endUtc = buildEndUtcUsingStartLocal(startUtc, match['match_end_time']);

                        return LiveMatchCard(
                          matchName: match['match_name']?.toString() ?? '',
                          matchCategories: match['match_categories']?.toString(),
                          teamA: teamA,
                          teamB: teamB,
                          isLive: _isLiveValue(match['is_live']),
                          matchStartTime: startUtc,
                          matchEndTime: endUtc, // normalized end time in UTC
                          hideWhenEnded: false, // KEEP the card visible until DB row deleted
                          // debugLogs: true,
                          onTap: () {
                            final channelIdRaw = match['live_video_url'];
                            final int? channelId = channelIdRaw is int
                                ? channelIdRaw
                                : int.tryParse(channelIdRaw?.toString() ?? '');

                            if (channelId == null) {
                              debugPrint('live_video_url is null for match ${match['id']}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Channel not available')),
                              );
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
