import 'package:evonex/controller/match_repository.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:evonex/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../elements/live_match_card.dart';
import '../elements/match_tab.dart';
import '../screens/video_screen.dart';
import 'package:iconsax/iconsax.dart';

class MatchHomeScreen extends StatefulWidget {
  final AdvancedDrawerController advancedDrawerController;

  const MatchHomeScreen({
    super.key,
    required this.advancedDrawerController,
  });

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

  void _handleMenuButtonPressed() {
    widget.advancedDrawerController.toggleDrawer();
  }

  // ------------------------------------------------------------
  // LOAD TEAMS
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
  // HELPERS
  // ------------------------------------------------------------
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
    if (endRaw == null) {
      return startUtc.add(const Duration(hours: 4));
    }

    final endStr = endRaw.toString();

    final full = DateTime.tryParse(endStr);
    if (full != null) {
      final endUtc = full.toUtc();
      return endUtc.isAfter(startUtc)
          ? endUtc
          : startUtc.add(const Duration(hours: 4));
    }

    final parts = endStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

      final startLocal = startUtc.toLocal();
      final endLocal = DateTime(
        startLocal.year,
        startLocal.month,
        startLocal.day,
        h,
        m,
        s,
      );

      final endUtc = endLocal.toUtc();
      if (!endUtc.isAfter(startUtc)) {
        return endUtc.add(const Duration(days: 1));
      }
      return endUtc;
    }

    return startUtc.add(const Duration(hours: 8));
  }

  // ------------------------------------------------------------
  // OPEN CHANNEL
  // ------------------------------------------------------------
  Future<void> _openChannelById(int channelId) async {
    try {
      final channel = await MatchRepository.getChannelById(channelId);
      if (channel == null) return;

      final url = channel['channel_link']?.toString() ?? '';
      if (url.isEmpty) return;

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
    } catch (_) {}
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
        title: SvgPicture.asset(
  "assets/images/Sportee.svg",
  height: 18,
  colorFilter: ColorFilter.mode(
   Color.fromARGB(255, 255, 255, 255),
    BlendMode.srcIn,
  ),
),
        leading: IconButton(
          onPressed: _handleMenuButtonPressed,
          icon: ValueListenableBuilder<AdvancedDrawerValue>(
            valueListenable: widget.advancedDrawerController,
            builder: (_, value, __) {
              return Icon(value.visible ? Icons.clear : Icons.menu);
            },
          ),
        ),
        actions: [
          IconButton(onPressed: (){
            Get.to(ALLChannelScreen());

          }, icon: Icon(Icons.tv_rounded))
        ],
      ),
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
                if (!teamSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teamMap = teamSnap.data!;
                final nowUtc = DateTime.now().toUtc();

                return StreamBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(_currentFilter), // 🔥 FORCE LOADING ON TAB CHANGE
                  stream: _matchStream,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final matches = snap.data!
                        .where((m) {
                          if (_currentFilter == 'ALL') return true;
                          final cat = (m['match_categories'] ?? '')
                              .toString()
                              .toUpperCase();
                          return cat.contains(_currentFilter);
                        })
                        .toList();

                    // 🔥 SORTING: LIVE → UPCOMING → ENDED
                    matches.sort((a, b) {
                      final s1 =
                          _parseDateTimeSafe(a['match_start_time']) ?? nowUtc;
                      final s2 =
                          _parseDateTimeSafe(b['match_start_time']) ?? nowUtc;

                      final e1 =
                          buildEndUtcUsingStartLocal(s1, a['match_end_time']);
                      final e2 =
                          buildEndUtcUsingStartLocal(s2, b['match_end_time']);

                      final aLive =
                          nowUtc.isAfter(s1) && nowUtc.isBefore(e1);
                      final bLive =
                          nowUtc.isAfter(s2) && nowUtc.isBefore(e2);

                      final aEnded = nowUtc.isAfter(e1);
                      final bEnded = nowUtc.isAfter(e2);

                      if (aLive && !bLive) return -1;
                      if (!aLive && bLive) return 1;

                      if (!aEnded && !bEnded) {
                        return s1.compareTo(s2);
                      }

                      if (aEnded && !bEnded) return 1;
                      if (!aEnded && bEnded) return -1;

                      return 0;
                    });

                    if (matches.isEmpty) {
                      return const Center(child: Text('No matches found'));
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final m = matches[i];

                        final teamA =
                            teamMap[m['team_a_id']] ??
                                Team(id: -1, name: 'TEAM A');
                        final teamB =
                            teamMap[m['team_b_id']] ??
                                Team(id: -2, name: 'TEAM B');

                        final start =
                            _parseDateTimeSafe(m['match_start_time']) ??
                                nowUtc;
                        final end =
                            buildEndUtcUsingStartLocal(
                                start, m['match_end_time']);

                        return LiveMatchCard(
                          matchName:
                              m['match_name']?.toString() ?? '',
                          matchCategories:
                              m['match_categories']?.toString(),
                          teamA: teamA,
                          teamB: teamB,
                          matchStartTime: start,
                          matchEndTime: end,
                          forceLive: m['is_live'] == true,
                          hideWhenEnded: false,
                          onTap: () {
                            final raw = m['live_video_url'];
                            final id = raw is int
                                ? raw
                                : int.tryParse(
                                    raw?.toString() ?? '');
                            if (id != null) {
                              _openChannelById(id);
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
