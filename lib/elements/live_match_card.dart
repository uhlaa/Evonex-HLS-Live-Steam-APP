// lib/elements/live_match_card.dart

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evonex/elements/live_badge.dart';
import 'package:flutter/material.dart';

/// Generic team model – jekono league er jonno use hobe
class Team {
  final int id; // team_id (INT2)
  final String name; // team_name
  final String? logoUrl; // team_logo_url
  final String? league; // optional: "BBL", "BPL", etc.

  Team({
    required this.id,
    required this.name,
    this.logoUrl,
    this.league,
  });
}

class LiveMatchCard extends StatefulWidget {
  final String matchName;
  final String? matchCategories;

  /// team table (team_a_id / team_b_id)
  final Team teamA;
  final Team teamB;

  /// DB theke asha isLive flag (chaile use korte paro)
  final bool isLive;

  /// DB match_start_time (should be a UTC-aware DateTime or parsed from ISO string)
  final DateTime matchStartTime;

  /// DB match_end_time (NEW) — required so widget can decide live window
  final DateTime matchEndTime;

  final VoidCallback? onTap;

  /// NEW: যদি true হলে match sesh hole card hide korbe.
  /// ডিফল্ট false — যার মানে card কখনই নিজে থেকে hide করবে না।
  final bool hideWhenEnded;

  /// Optional debug prints for local testing
  final bool debugLogs;

  const LiveMatchCard({
    super.key,
    required this.matchName,
    this.matchCategories,
    required this.teamA,
    required this.teamB,
    required this.matchStartTime,
    required this.matchEndTime,
    this.isLive = false,
    this.onTap,
    this.hideWhenEnded = false,
    this.debugLogs = false,
  });

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard> {
  Timer? _liveTimer;
  bool _timeBasedLive = false; // ⬅ time diye live check

  /// How often we re-evaluate time-based live state.
  /// Keep 30s for production; while debugging you can set lower via edit.
  static const Duration _defaultCheckInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _checkLiveByTime();
    _startLiveTimer();
  }

  @override
  void didUpdateWidget(covariant LiveMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if start/end changed, re-evaluate and restart timer
    if (oldWidget.matchStartTime != widget.matchStartTime ||
        oldWidget.matchEndTime != widget.matchEndTime ||
        oldWidget.isLive != widget.isLive ||
        oldWidget.hideWhenEnded != widget.hideWhenEnded) {
      _checkLiveByTime();
      _startLiveTimer();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();

    // 30 sec por por check korbo – testing-e choto korte paro.
    _liveTimer = Timer.periodic(_defaultCheckInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkLiveByTime();
    });
  }

  void _checkLiveByTime() {
    // Compare in UTC so client timezone differences don't break logic.
    final nowUtc = DateTime.now().toUtc();
    final startUtc = widget.matchStartTime.toUtc();
    final endUtc = widget.matchEndTime.toUtc();

    // inclusive: now >= start && now <= end
    final isNowLive = (nowUtc.isAtSameMomentAs(startUtc) || nowUtc.isAfter(startUtc)) &&
        (nowUtc.isAtSameMomentAs(endUtc) || nowUtc.isBefore(endUtc));

    if (widget.debugLogs) {
      debugPrint('LiveMatchCard.debug -> nowUtc: $nowUtc');
      debugPrint('LiveMatchCard.debug -> startUtc: $startUtc');
      debugPrint('LiveMatchCard.debug -> endUtc: $endUtc');
      debugPrint('LiveMatchCard.debug -> isNowLive: $isNowLive widget.isLive: ${widget.isLive}');
    }

    if (isNowLive != _timeBasedLive) {
      if (mounted) {
        setState(() {
          _timeBasedLive = isNowLive;
        });
      }
    }
  }

  /// Format: 14-12-2025
  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return "$day-$month-$year";
  }

  /// Format time: 8:30 PM
  String _formatTime(DateTime dt) {
    final local = dt.toLocal();

    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final isPM = hour >= 12;
    final suffix = isPM ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return "$hour:$minute $suffix";
  }

  /// TODAY / TOMORROW / FULL DATE / MATCH ENDED
  String _statusText() {
    // jodi live hoy (DB ba time diye), text lagbe na
    if (_isActuallyLive) return "";

    final nowUtc = DateTime.now().toUtc();
    final endUtc = widget.matchEndTime.toUtc();

    // If match already ended, show "MATCH ENDED" with end time.
    if (nowUtc.isAfter(endUtc)) {
      return "MATCH ENDED";
    }

    final now = DateTime.now();
    final start = widget.matchStartTime.toLocal();

    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(start.year, start.month, start.day);

    final diffDays = matchDay.difference(today).inDays;
    final timeText = _formatTime(start);

    if (diffDays == 0) {
      // ajker match
      return "TODAY · $timeText";
    } else if (diffDays == 1) {
      // agamikaler match
      return "TOMORROW · $timeText";
    } else {
      // onno kono din
      return "${_formatDateTime(start)}";
    }
  }

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final time = _formatTime(dt);
    return "$date · $time";
  }

  bool get _isActuallyLive {
    // Respect DB's isLive flag OR the time-based live check.
    return widget.isLive || _timeBasedLive;
  }

  /// TOP RIGHT widget
  Widget get _statusWidget {
    if (_isActuallyLive) {
      // live match → show LIVE badge
      return const LiveBadge();
    }

    final text = _statusText();

    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.inversePrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Optional self-hide: only when widget.hideWhenEnded == true
    final nowUtc = DateTime.now().toUtc();
    if (widget.hideWhenEnded && nowUtc.isAfter(widget.matchEndTime.toUtc())) {
      // card will not take space
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
              color: Colors.black.withOpacity(0.02),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP: Title + LIVE / TODAY / TOMORROW / DATE / MATCH ENDED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.matchName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.matchCategories != null &&
                          widget.matchCategories!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.matchCategories!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.inverseSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                _statusWidget,
              ],
            ),

            const SizedBox(height: 16),

            /// MIDDLE: Team logos + VS
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _TeamBlock(team: widget.teamA),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _TeamBlock(team: widget.teamB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final Team team;

  const _TeamBlock({required this.team});

  @override
  Widget build(BuildContext context) {
    final logoUrl = team.logoUrl?.trim() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: logoUrl.isEmpty
              ? const Icon(Icons.sports_cricket, size: 32)
              : CachedNetworkImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 0),
                  fadeOutDuration: const Duration(milliseconds: 0),
                  placeholder: (context, url) => const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          team.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ],
    );
  }
}

