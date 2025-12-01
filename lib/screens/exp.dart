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

