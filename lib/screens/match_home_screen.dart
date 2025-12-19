// lib/screens/match_home_screen.dart

import 'package:evonex/controller/match_repository.dart';
import 'package:evonex/theme/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';


import '../elements/live_match_card.dart';
import '../elements/match_tab.dart';
import '../elements/my_drawer.dart';
import '../screens/home_screen.dart';
import '../screens/video_screen.dart';

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
    _matchStream = MatchRepository.streamMatches();
    _teamMapFuture = _loadTeams();
  }

  // ------------------------------------------------------------
  // TEAM LOAD
  // ------------------------------------------------------------
  Future<Map<int, Team>> _loadTeams() async {
    final rows = await MatchRepository.fetchTeams();
    final Map<int, Team> result = {};

    for (final map in rows) {
      final rawId = map['id'];
      if (rawId is! int) continue;

      result[rawId] = Team(
        id: rawId,
        name: (map['name'] ?? map['team_name'] ?? 'UNKNOWN').toString(),
        logoUrl: map['logo_url']?.toString(),
        league: map['league']?.toString(),
      );
    }
    return result;
  }

  // ------------------------------------------------------------
  // UTIL HELPERS
  // ------------------------------------------------------------
  bool _isLiveValue(dynamic raw) {
    if (raw is bool) return raw;
    if (raw == null) return false;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 't' || s == 'yes';
  }

  DateTime? _parseDateTimeSafe(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  DateTime buildEndUtcUsingStartLocal(DateTime startUtc, dynamic endRaw) {
    if (endRaw == null) return startUtc;

    // full timestamp
    try {
      final parsed = DateTime.tryParse(endRaw.toString());
      if (parsed != null) {
        final dt = parsed.toUtc();
        return dt.isAfter(startUtc) ? dt : dt.add(const Duration(days: 1));
      }
    } catch (_) {}

    // time-only
    final startLocal = startUtc.toLocal();
    final baseDate = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day,
    );

    final parts = endRaw.toString().split(':');
    if (parts.isEmpty) return startUtc;

    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    var candidate = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      h,
      m,
    );

    if (!candidate.isAfter(startLocal)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate.toUtc();
  }

  // ------------------------------------------------------------
  // OPEN CHANNEL
  // ------------------------------------------------------------
  Future<void> _openChannelById(int channelId) async {
    try {
      final channel = await MatchRepository.getChannelById(channelId);

      if (channel == null) {
        _snack('Channel not found');
        return;
      }

      final url = channel['channel_link']?.toString() ?? '';
      if (url.isEmpty) {
        _snack('Channel link is empty');
        return;
      }

      if (!mounted) return;

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
      _snack('Failed to open channel');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
       scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('S P O R T E E', style: TextStyle( fontWeight: FontWeight.w700,fontSize: 20, color: Theme.of(context).colorScheme.inversePrimary,),),
        leading: IconButton(
                 icon: Icon(Icons.tv_rounded, color:Theme.of(context).colorScheme.inversePrimary,),
                 onPressed: () => Get.to(() => ALLChannelScreen()),
               ),
        actions: [
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                          value: Provider.of<ThemeProvider>(context).isDarkMode,
                          onChanged: (value) =>
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                        ),
              ),
              // IconButton(
              //   icon: Icon(Icons.tv_rounded, color:Theme.of(context).colorScheme.inversePrimary,),
              //   onPressed: () => Get.to(() => ALLChannelScreen()),
              // ),
            ],
          )
        ],
      ),
      // drawer: const MyDrawer(),
      body: Column(
        children: [
          MatchCategoryTabs(
            initial: _currentFilter,
            onChanged: (v) => setState(() => _currentFilter = v),
          ),
          Expanded(
            child: FutureBuilder<Map<int, Team>>(
              future: _teamMapFuture,
              builder: (context, teamSnap) {
                if (teamSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teamMap = teamSnap.data ?? {};

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _matchStream,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final nowUtc = DateTime.now().toUtc();

                    final matches = snap.data!
                        .where((m) {
                          if (_currentFilter == 'ALL') return true;
                          final cat = (m['match_categories'] ?? '')
                              .toString()
                              .toUpperCase();
                          return cat.contains(_currentFilter);
                        })
                        .toList();

                    matches.sort((a, b) {
                      final s1 =
                          _parseDateTimeSafe(a['match_start_time']) ??
                              nowUtc;
                      final s2 =
                          _parseDateTimeSafe(b['match_start_time']) ??
                              nowUtc;

                      final e1 =
                          buildEndUtcUsingStartLocal(s1, a['match_end_time']);
                      final e2 =
                          buildEndUtcUsingStartLocal(s2, b['match_end_time']);

                      int status(Map<String, dynamic> m, DateTime s, DateTime e) {
                        if (_isLiveValue(m['is_live'])) return 0;
                        if (nowUtc.isBefore(s)) return 1;
                        return 2;
                      }

                      return status(a, s1, e1)
                          .compareTo(status(b, s2, e2));
                    });

                    if (matches.isEmpty) {
                      return const Center(
                        child: Text('No matches found'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final m = matches[i];

                        final Team teamA =
                            teamMap[m['team_a_id']] ??
                                Team(id: -1, name: 'TEAM A');
                        final Team teamB =
                            teamMap[m['team_b_id']] ??
                                Team(id: -2, name: 'TEAM B');

                        final start =
                            _parseDateTimeSafe(m['match_start_time']) ??
                                nowUtc;
                        final end =
                            buildEndUtcUsingStartLocal(start, m['match_end_time']);

                        return LiveMatchCard(
                          matchName: m['match_name']?.toString() ?? '',
                          matchCategories:
                              m['match_categories']?.toString(),
                          teamA: teamA,
                          teamB: teamB,
                          isLive: _isLiveValue(m['is_live']),
                          matchStartTime: start,
                          matchEndTime: end,
                          hideWhenEnded: false,
                          onTap: () {
                            final raw = m['live_video_url'];
                            final id = raw is int
                                ? raw
                                : int.tryParse(raw?.toString() ?? '');
                            if (id != null) {
                              _openChannelById(id);
                            } else {
                              _snack('Channel not available');
                            }
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
