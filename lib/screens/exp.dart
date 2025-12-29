// // lib/screens/video_screen.dart
// import 'package:flutter/material.dart';
// import 'package:omni_video_player/omni_video_player.dart';
// import 'package:evonex/elements/live_badge.dart';

// class VideoScreen extends StatefulWidget {
//   final String url; // required
//   final String? name; // optional

//   const VideoScreen({
//     super.key,
//     required this.url,
//     this.name,
//   });

//   @override
//   State<VideoScreen> createState() => _VideoScreenState();
// }

// class _VideoScreenState extends State<VideoScreen> {
//   OmniPlaybackController? _controller;

//   // Schedule guard to avoid continuous setState spam
//   bool _setStateScheduled = false;

//   // Track whether we intentionally paused from UI to avoid auto-retry fighting user
//   bool _userPaused = false;

//   void _update() {
//     // If we've already scheduled a rebuild, do nothing.
//     if (_setStateScheduled) return;
//     _setStateScheduled = true;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       _setStateScheduled = false;
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _controller?.removeListener(_update);
//     // Optionally: stop playback before dispose
//     try {
//       _controller?.pause();
//     } catch (_) {}
//     super.dispose();
//   }

//   final bool showCustomLiveBadge = true;

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Column(
//           children: [
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: Container(
//                 color: Colors.black,
//                 child: Stack(
//                   children: [
//                     Positioned.fill(
//                       child: OmniVideoPlayer(
//                         callbacks: VideoPlayerCallbacks(
//                           onControllerCreated: (controller) async {
//                             // detach old listener
//                             _controller?.removeListener(_update);

//                             // attach new controller and listener
//                             _controller = controller..addListener(_update);

//                             // Try a safe autoplay sequence:
//                             // 1) mute (some platforms allow muted autoplay)
//                             // 2) play
//                             // 3) unmute after short delay
//                             try {
//                               // // set volume to 0 to improve autoplay reliability on some devices
//                               // await _controller!.setVolume(0);
//                             } catch (e) {
//                               debugPrint('setVolume(0) not supported: $e');
//                             }

//                             try {
//                               await _controller!.play();
//                               debugPrint('Auto-play requested successfully.');
//                             } catch (e) {
//                               debugPrint('Auto-play failed first attempt: $e');
//                               // Retry once after short delay
//                               await Future.delayed(const Duration(milliseconds: 350));
//                               try {
//                                 await _controller!.play();
//                                 debugPrint('Auto-play retry succeeded.');
//                               } catch (e) {
//                                 debugPrint('Auto-play retry failed: $e');
//                               }
//                             }

//                             // // Restore audible volume after short delay (optional)
//                             // Future.delayed(const Duration(milliseconds: 700), () async {
//                             //   try {
//                             //     await _controller?.setVolume(1);
//                             //   } catch (_) {}
//                             // });

//                             // Ensure UI updates at least once after controller ready
//                             _update();
//                           },
//                         ),
//                         configuration: VideoPlayerConfiguration(
//                           liveLabel: "Live",
//                           videoSourceConfiguration:
//                               VideoSourceConfiguration.network(
//                             videoUrl: Uri.parse(widget.url),
//                           ),
//                           playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
//                             enableForwardGesture: false,
//                             enableBackwardGesture: false,
//                             showReplayButton: false,
//                             showSeekBar: false,
//                             showPlayPauseReplayButton: true,
//                             showFullScreenButton: true,
//                             showSwitchVideoQuality: true,
//                             showLiveIndicator: true,
//                             showMuteUnMuteButton: false,
//                           ),
//                         ),
//                       ),
//                     ),

//                     if (showCustomLiveBadge)
//                       const Positioned(
//                         left: 15,
//                         bottom: 10,
//                         child: LiveBadge(),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

        
//           ],
//         ),
//       ),
//     );
//   }
// }




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

  /// DB theke asha isLive flag
  final bool isLive;

  /// DB match_start_time
  final DateTime matchStartTime;

  /// DB match_end_time
  final DateTime matchEndTime;

  final VoidCallback? onTap;

  /// true hole match sesh e card hide hobe
  final bool hideWhenEnded;

  /// debug print
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
  bool _timeBasedLive = false;

  static const Duration _checkInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _checkLiveByTime();
    _startLiveTimer();
  }

  @override
  void didUpdateWidget(covariant LiveMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _liveTimer = Timer.periodic(_checkInterval, (_) {
      if (!mounted) return;
      _checkLiveByTime();
    });
  }

  void _checkLiveByTime() {
    final nowUtc = DateTime.now().toUtc();
    final startUtc = widget.matchStartTime.toUtc();
    final endUtc = widget.matchEndTime.toUtc();

    final isNowLive =
        (nowUtc.isAtSameMomentAs(startUtc) || nowUtc.isAfter(startUtc)) &&
        (nowUtc.isAtSameMomentAs(endUtc) || nowUtc.isBefore(endUtc));

    if (widget.debugLogs) {
      debugPrint('nowUtc   : $nowUtc');
      debugPrint('startUtc : $startUtc');
      debugPrint('endUtc   : $endUtc');
      debugPrint('isLive   : $isNowLive');
    }

    if (isNowLive != _timeBasedLive) {
      setState(() {
        _timeBasedLive = isNowLive;
      });
    }
  }

  bool get _isActuallyLive => widget.isLive || _timeBasedLive;

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-${d.year}";
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
    if (_isActuallyLive) return "";

    final nowUtc = DateTime.now().toUtc();
    if (nowUtc.isAfter(widget.matchEndTime.toUtc())) {
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
    if (_isActuallyLive) {
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
    if (widget.hideWhenEnded &&
        DateTime.now().toUtc().isAfter(widget.matchEndTime.toUtc())) {
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.matchName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              ? const Icon(Icons.sports_cricket)
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


