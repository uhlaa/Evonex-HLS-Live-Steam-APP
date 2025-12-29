import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evonex/elements/live_badge.dart';
import 'package:flutter/material.dart';

/// Generic team model
class Team {
  final int id;
  final String name;
  final String? logoUrl;
  final String? league;
  

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
  final Team teamA;
  final Team teamB;
  final bool forceLive;


  final DateTime matchStartTime;
  final DateTime matchEndTime;

  final VoidCallback? onTap;
  final bool hideWhenEnded;
  final bool debugLogs;

  const LiveMatchCard({
  super.key,
  required this.matchName,
  this.matchCategories,
  required this.teamA,
  required this.teamB,
  required this.matchStartTime,
  required this.matchEndTime,
  this.onTap,
  this.hideWhenEnded = false,
  this.debugLogs = false,
  this.forceLive = false, // ✅ NEW
});


  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard> {
  Timer? _timer;
  bool? _isLiveByTime;

  late final DateTime _safeEndTime;

  static const Duration _checkInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    /// ✅ FIXED END TIME LOGIC
    _safeEndTime = widget.matchEndTime;


    _evaluateLiveStatus();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant LiveMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchStartTime != widget.matchStartTime ||
        oldWidget.matchEndTime != widget.matchEndTime) {
      _evaluateLiveStatus();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) {
      if (!mounted) return;
      _evaluateLiveStatus();
    });
  }

  /// 🧠 CATEGORY BASED FALLBACK DURATION
  Duration _fallbackDuration() {
    final cat = (widget.matchCategories ?? '').toUpperCase();

    if (cat.contains('FOOTBALL') || cat.contains('SOCCER')) {
      return const Duration(hours: 3);
    }

    if (cat.contains('T20')) {
      return const Duration(hours: 4);
    }

    if (cat.contains('ODI')) {
      return const Duration(hours: 8);
    }

    if (cat.contains('TEST')) {
      return const Duration(hours: 48);
    }

    return const Duration(hours: 3);
  }

  void _evaluateLiveStatus() {
  final nowUtc = DateTime.now().toUtc();
  final startUtc = widget.matchStartTime.toUtc();
  final endUtc = _safeEndTime.toUtc();

  final ended = nowUtc.isAfter(endUtc);

  bool isLive;

  if (ended) {
    // 1️⃣ ended always false
    isLive = false;
  } else if (widget.forceLive) {
    // 2️⃣ admin forced live
    isLive = true;
  } else {
    // 3️⃣ normal time-based live
    isLive =
        nowUtc.isAfter(startUtc) && nowUtc.isBefore(endUtc);
  }

  if (widget.debugLogs) {
    debugPrint('----- LIVE HYBRID DEBUG -----');
    debugPrint('NOW    : $nowUtc');
    debugPrint('START  : $startUtc');
    debugPrint('END    : $endUtc');
    debugPrint('FORCE  : ${widget.forceLive}');
    debugPrint('LIVE   : $isLive');
  }

  if (_isLiveByTime == null || _isLiveByTime != isLive) {
    setState(() {
      _isLiveByTime = isLive;
    });
  }
}


  bool get _isLive => _isLiveByTime ?? false;

 bool get _isEnded =>
    DateTime.now().toUtc().isAfter(_safeEndTime.toUtc());


  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
  }

  String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    int hour = d.hour;
    final min = d.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;

    return "$hour:$min $suffix";
  }

  String _statusText() {
    if (_isLive) return "";

    if (_isEnded) {
      return "MATCH ENDED";
    }

    final now = DateTime.now();
    final start = widget.matchStartTime.toLocal();

    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(start.year, start.month, start.day);

    final diff = matchDay.difference(today).inDays;

    if (diff == 0) {
      return "TODAY · ${_formatTime(start)}";
    } else if (diff == 1) {
      return "TOMORROW · ${_formatTime(start)}";
    } else {
      return "${_formatDate(start)} · ${_formatTime(start)}";
    }
  }

  Widget get _statusWidget {
    if (_isLive) {
      return const LiveBadge();
    }

    return Text(
      _statusText(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideWhenEnded && _isEnded) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isEnded
              ? Theme.of(context)
                  .colorScheme
                  .tertiary
                  .withOpacity(0.4)
              : Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.matchCategories != null)
                        Text(
                          widget.matchCategories!.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                _statusWidget,
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TeamBlock(team: widget.teamA)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "VS",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: _TeamBlock(team: widget.teamB)),
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
    final logo = team.logoUrl?.trim() ?? '';

    return Column(
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: logo.isEmpty
              ? const Icon(Icons.sports)
              : CachedNetworkImage(
                  imageUrl: logo,
                  fit: BoxFit.contain,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          team.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
