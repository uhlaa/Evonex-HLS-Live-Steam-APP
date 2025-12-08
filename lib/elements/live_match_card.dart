import 'dart:async';
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

  /// DB match_start_time
  final DateTime matchStartTime;

  final VoidCallback? onTap;

  const LiveMatchCard({
    super.key,
    required this.matchName,
    this.matchCategories,
    required this.teamA,
    required this.teamB,
    required this.matchStartTime,
    this.isLive = false,
    this.onTap,
  });

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard> {
  Timer? _liveTimer;
  bool _timeBasedLive = false; // ⬅ time diye live check

  @override
  void initState() {
    super.initState();
    _checkLiveByTime();
    _startLiveTimer();
  }

  @override
  void didUpdateWidget(covariant LiveMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchStartTime != widget.matchStartTime) {
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

    // 30 sec por por check korbo – beshi frequent lagle 5 sec o dite paro
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkLiveByTime();
    });
  }

  void _checkLiveByTime() {
    final now = DateTime.now();
    final start = widget.matchStartTime.toLocal();

    // minimum logic:
    // start time er por theke shob shomoy live dhorchi
    final isNowLive = now.isAfter(start);

    if (isNowLive != _timeBasedLive) {
      setState(() {
        _timeBasedLive = isNowLive;
      });
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

  /// Fallback: 14-12-2025 · 8:30 PM
  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final time = _formatTime(dt);
    return "$date · $time";
  }

  /// TODAY / TOMORROW / FULL DATE
  String _statusText() {
    // jodi live hoy (DB ba time diye), text lagbe na
    if (_isActuallyLive) return "";

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
      return _formatDateTime(start);
    }
  }

  bool get _isActuallyLive {
    // jodi DB theke isLive true ashe, oitao respect korchi
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
      style: const TextStyle(
        fontSize: 11,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
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
            /// TOP: Title + LIVE / TODAY / TOMORROW / DATE
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
                          color: Colors.black87,
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
                              color: Colors.grey.shade600,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
              : Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          team.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}




// import 'dart:async';
// import 'package:evonex/elements/live_badge.dart';
// import 'package:flutter/material.dart';

// /// Generic team model – jekono league er jonno use hobe
// class Team {
//   final int id;          // team_id (INT2)
//   final String name;     // team_name
//   final String? logoUrl; // team_logo_url
//   final String? league;  // optional: "BBL", "BPL", etc.

//   Team({
//     required this.id,
//     required this.name,
//     this.logoUrl,
//     this.league,
//   });
// }

// class LiveMatchCard extends StatefulWidget {
//   final String matchName;
//   final String? matchCategories;

//   /// team table (team_a_id / team_b_id)
//   final Team teamA;
//   final Team teamB;

//   /// isLive = true hole direct LIVE badge
//   final bool isLive;

//   /// DB match_start_time
//   final DateTime matchStartTime;

//   final VoidCallback? onTap;

//   const LiveMatchCard({
//     super.key,
//     required this.matchName,
//     this.matchCategories,
//     required this.teamA,
//     required this.teamB,
//     required this.matchStartTime,
//     this.isLive = true,
//     this.onTap,
//   });

//   @override
//   State<LiveMatchCard> createState() => _LiveMatchCardState();
// }

// class _LiveMatchCardState extends State<LiveMatchCard> {
//   Timer? _timer;
//   Duration _remaining = Duration.zero;

//   bool get _isUpcoming =>
//       !widget.isLive && DateTime.now().isBefore(widget.matchStartTime);

//   bool get _countdownFinished =>
//       _remaining.inSeconds == 0 && !_remaining.isNegative;

//   @override
//   void initState() {
//     super.initState();
//     _updateRemaining();
//     _startTimer();
//   }

//   void _updateRemaining() {
//     final now = DateTime.now();
//     final diff = widget.matchStartTime.difference(now);

//     setState(() {
//       _remaining = diff.isNegative ? Duration.zero : diff;
//     });
//   }

//   void _startTimer() {
//     final now = DateTime.now();
//     final diff = widget.matchStartTime.difference(now);

//     // upcoming na ba 24h er beshi dure → timer lagbe na
//     if (!_isUpcoming || diff.inHours >= 24) {
//       _timer?.cancel();
//       return;
//     }

//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       _updateRemaining();
//       if (_remaining == Duration.zero) {
//         setState(() {});
//         timer.cancel();
//       }
//     });
//   }

//   @override
//   void didUpdateWidget(covariant LiveMatchCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.matchStartTime != widget.matchStartTime ||
//         oldWidget.isLive != widget.isLive) {
//       _updateRemaining();
//       _startTimer();
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   /// Short date: Sun, Dec 14 · 6:14 PM
//   String _formatShortDate(DateTime dt) {
//     final local = dt.toLocal();

//     const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
//     const months = [
//       "Jan", "Feb", "Mar", "Apr", "May", "Jun",
//       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
//     ];

//     final weekday = weekdays[local.weekday - 1].toUpperCase();
//     final month = months[local.month - 1].toUpperCase();
//     final day = local.day;

//     int hour = local.hour;
//     final minute = local.minute.toString().padLeft(2, '0');
//     final suffix = hour >= 12 ? "PM" : "AM";

//     if (hour == 0) hour = 12;
//     else if (hour > 12) hour -= 12;

//     return "$weekday, $month $day · $hour:$minute $suffix";
//   }

//   /// Countdown: STARTS IN 18H 22M / 45M / 30S
//   String _formatCountdown() {
//     if (_remaining <= Duration.zero) return "Starting...";

//     final days = _remaining.inDays;
//     final hours = _remaining.inHours.remainder(24);
//     final minutes = _remaining.inMinutes.remainder(60);
//     final seconds = _remaining.inSeconds.remainder(60);

//     if (days > 0) return "Starts at ${days}d ${hours}h".toUpperCase();
//     if (hours > 0) return "Starts at ${hours}h ${minutes}m".toUpperCase();
//     if (minutes > 0) return "Starts at ${minutes}m".toUpperCase();

//     return "Starts in ${seconds}s";
//   }

//   /// Top-right status text / badge
//   Widget get _statusWidget {
//     final now = DateTime.now();
//     final diff = widget.matchStartTime.difference(now);

//     // Live or countdown sesh → LIVE badge
//     if (widget.isLive || _countdownFinished) {
//       return const LiveBadge();
//     }

//     // 24h er beshi pore → date
//     if (diff.inHours >= 24) {
//       return Text(
//         _formatShortDate(widget.matchStartTime),
//         style: const TextStyle(
//           fontSize: 11,
//           color: Colors.black87,
//           fontWeight: FontWeight.w600,
//         ),
//       );
//     }

//     // upcoming & 24h er vitore → countdown
//     if (_isUpcoming) {
//       return Text(
//         _formatCountdown(),
//         style: const TextStyle(
//           fontSize: 11,
//           color: Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       );
//     }

//     // Past match → sudhu date
//     return Text(
//       _formatShortDate(widget.matchStartTime),
//       style: const TextStyle(
//         fontSize: 11,
//         color: Colors.black87,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: widget.onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: 10,
//               spreadRadius: 1,
//               offset: const Offset(0, 2),
//               color: Colors.black.withOpacity(0.02),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// TOP: Title + LIVE / COUNTDOWN / DATE
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.matchName.toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.black87,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (widget.matchCategories != null &&
//                           widget.matchCategories!.trim().isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 2),
//                           child: Text(
//                             widget.matchCategories!.toUpperCase(),
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey.shade600,
//                               fontWeight: FontWeight.w500,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 _statusWidget,
//               ],
//             ),

//             const SizedBox(height: 16),

//             /// MIDDLE: Team logos + VS
//             Row(
//               children: [
//                 Expanded(
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: _TeamBlock(team: widget.teamA),
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20),
//                   child: Text(
//                     'VS',
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: _TeamBlock(team: widget.teamB),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TeamBlock extends StatelessWidget {
//   final Team team;

//   const _TeamBlock({required this.team});

//   @override
//   Widget build(BuildContext context) {
//     final logoUrl = team.logoUrl?.trim() ?? '';

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         SizedBox(
//           height: 52,
//           width: 52,
//           child: logoUrl.isEmpty
//               ? const Icon(Icons.sports_cricket, size: 32)
//               : Image.network(
//                   logoUrl,
//                   fit: BoxFit.contain,
//                   errorBuilder: (_, __, ___) =>
//                       const Icon(Icons.broken_image),
//                 ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           team.name.toUpperCase(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w700,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }



// import 'dart:async';
// import 'package:evonex/elements/live_badge.dart';
// import 'package:flutter/material.dart';

// /// Generic team model – jekono league er jonno use hobe
// class Team {
//   final int id; // team_id (INT2)
//   final String name; // team_name
//   final String? logoUrl; // team_logo_url
//   final String? league; // optional: "BBL", "BPL", etc.

//   Team({
//     required this.id,
//     required this.name,
//     this.logoUrl,
//     this.league,
//   });
// }

// class LiveMatchCard extends StatefulWidget {
//   final String matchName;
//   final String? matchCategories;

//   /// team table (team_a_id / team_b_id)
//   final Team teamA;
//   final Team teamB;

//   /// DB theke asha isLive flag (chaile use korte paro)
//   final bool isLive;

//   /// DB match_start_time
//   final DateTime matchStartTime;

//   final VoidCallback? onTap;

//   const LiveMatchCard({
//     super.key,
//     required this.matchName,
//     this.matchCategories,
//     required this.teamA,
//     required this.teamB,
//     required this.matchStartTime,
//     this.isLive = false,
//     this.onTap,
//   });

//   @override
//   State<LiveMatchCard> createState() => _LiveMatchCardState();
// }

// class _LiveMatchCardState extends State<LiveMatchCard> {
//   Timer? _liveTimer;
//   bool _timeBasedLive = false; // ⬅ time diye live check

//   @override
//   void initState() {
//     super.initState();
//     _checkLiveByTime();
//     _startLiveTimer();
//   }

//   @override
//   void didUpdateWidget(covariant LiveMatchCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.matchStartTime != widget.matchStartTime) {
//       _checkLiveByTime();
//       _startLiveTimer();
//     }
//   }

//   @override
//   void dispose() {
//     _liveTimer?.cancel();
//     super.dispose();
//   }

//   void _startLiveTimer() {
//     _liveTimer?.cancel();

//     // 30 sec por por check korbo – beshi frequent lagle 5 sec o dite paro
//     _liveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       _checkLiveByTime();
//     });
//   }

//   void _checkLiveByTime() {
//     final now = DateTime.now();
//     final start = widget.matchStartTime.toLocal();

//     // start time er por theke shob shomoy live dhorchi
//     final isNowLive = now.isAfter(start);

//     if (isNowLive != _timeBasedLive) {
//       setState(() {
//         _timeBasedLive = isNowLive;
//       });
//     }
//   }

//   /// Format: 14-12-2025
//   String _formatDate(DateTime dt) {
//     final local = dt.toLocal();
//     final day = local.day.toString().padLeft(2, '0');
//     final month = local.month.toString().padLeft(2, '0');
//     final year = local.year.toString();
//     return "$day-$month-$year";
//   }

//   /// Format time: 8:30 PM
//   String _formatTime(DateTime dt) {
//     final local = dt.toLocal();

//     int hour = local.hour;
//     final minute = local.minute.toString().padLeft(2, '0');
//     final isPM = hour >= 12;
//     final suffix = isPM ? 'PM' : 'AM';

//     if (hour == 0) {
//       hour = 12;
//     } else if (hour > 12) {
//       hour -= 12;
//     }

//     return "$hour:$minute $suffix";
//   }

//   /// Fallback: 14-12-2025 · 8:30 PM
//   String _formatDateTime(DateTime dt) {
//     final date = _formatDate(dt);
//     final time = _formatTime(dt);
//     return "$date · $time";
//   }

//   /// TODAY / TOMORROW / FULL DATE
//   String _statusText() {
//     // jodi live hoy (DB ba time diye), text lagbe na
//     if (_isActuallyLive) return "";

//     final now = DateTime.now();
//     final start = widget.matchStartTime.toLocal();

//     final today = DateTime(now.year, now.month, now.day);
//     final matchDay = DateTime(start.year, start.month, start.day);

//     final diffDays = matchDay.difference(today).inDays;
//     final timeText = _formatTime(start);

//     if (diffDays == 0) {
//       // ajker match
//       return "TODAY · $timeText";
//     } else if (diffDays == 1) {
//       // agamikaler match
//       return "TOMORROW · $timeText";
//     } else {
//       // onno kono din
//       return _formatDateTime(start);
//     }
//   }

//   bool get _isActuallyLive {
//     // jodi DB theke isLive true ashe, oitao respect korchi
//     return widget.isLive || _timeBasedLive;
//   }

//   /// TOP RIGHT widget
//   Widget get _statusWidget {
//     if (_isActuallyLive) {
//       // live match → show LIVE badge
//       return const LiveBadge();
//     }

//     final text = _statusText();

//     return Text(
//       text.toUpperCase(),
//       style: const TextStyle(
//         fontSize: 11,
//         color: Colors.black87,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: 10,
//               spreadRadius: 1,
//               offset: const Offset(0, 2),
//               color: Colors.black.withOpacity(0.02),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// TOP: Title + LIVE / TODAY / TOMORROW / DATE
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.matchName.toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.black87,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (widget.matchCategories != null &&
//                           widget.matchCategories!.trim().isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 2),
//                           child: Text(
//                             widget.matchCategories!.toUpperCase(),
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey.shade600,
//                               fontWeight: FontWeight.w500,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 _statusWidget,
//               ],
//             ),

//             const SizedBox(height: 16),

//             /// MIDDLE: Team logos + VS
//             Row(
//               children: [
//                 Expanded(
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: _TeamBlock(team: widget.teamA),
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20),
//                   child: Text(
//                     'VS',
//                     style: TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Align(
//                     alignment: Alignment.bottomCenter,
//                     child: _TeamBlock(team: widget.teamB),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TeamBlock extends StatelessWidget {
//   final Team team;

//   const _TeamBlock({required this.team});

//   @override
//   Widget build(BuildContext context) {
//     final logoUrl = team.logoUrl?.trim() ?? '';

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         SizedBox(
//           height: 52,
//           width: 52,
//           child: logoUrl.isEmpty
//               ? const Icon(Icons.sports_cricket, size: 32)
//               : Image.network(
//                   logoUrl,
//                   fit: BoxFit.contain,
//                   errorBuilder: (_, __, ___) =>
//                       const Icon(Icons.broken_image),
//                 ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           team.name.toUpperCase(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w700,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }
