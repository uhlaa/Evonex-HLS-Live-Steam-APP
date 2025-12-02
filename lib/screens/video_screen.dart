// // lib/screens/video_screen.dart
// import 'package:evonex/elements/horizontal_channel.dart';
// import 'package:evonex/models/channel_list.dart';
// import 'package:evonex/screens/home_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:omni_video_player/omni_video_player.dart';
// import 'package:evonex/elements/live_badge.dart';

// /// Public State class name so other widgets can find it with findAncestorStateOfType<VideoScreenState>()
// class VideoScreen extends StatefulWidget {
//   final String url; // initial url
//   final String? name;

//   const VideoScreen({
//     super.key,
//     required this.url,
//     this.name,
//   });

//   /// Helper: open by replacing current route (no stacking of multiple VideoScreens)
//   static Future<void> openReplace(String url, {String? name}) async {
//     try {
//       await Get.off(() => VideoScreen(url: url, name: name));
//     } catch (_) {
//       // fallback: pushReplacement using Navigator
//       final ctx = Get.context;
//       if (ctx != null) {
//         Navigator.of(ctx).pushReplacement(
//           MaterialPageRoute(builder: (_) => VideoScreen(url: url, name: name)),
//         );
//       }
//     }
//   }

//   @override
//   VideoScreenState createState() => VideoScreenState();
// }

// class VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
//   OmniPlaybackController? _controller;

//   // current stream url shown by this screen (changes when user taps another channel)
//   late String currentUrl;

//   // Schedule guard to avoid continuous setState spam
//   bool _setStateScheduled = false;

//   // Track whether we intentionally paused from UI to avoid auto-retry fighting user
//   bool _userPaused = false;

//   // Ensure only one navigation attempt from this screen at a time
//   bool _navigatingAway = false;

//   // Track if switching stream to avoid repeated rapid taps
//   bool _switchingStream = false;

//   @override
//   void initState() {
//     super.initState();
//     currentUrl = widget.url;
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     try {
//       _controller?.removeListener(_update);
//     } catch (_) {}
//     try {
//       _controller?.pause();
//     } catch (_) {}
//     try {
//       _controller?.dispose();
//     } catch (_) {}
//     _controller = null;
//     super.dispose();
//   }

//   void _update() {
//     if (_setStateScheduled) return;
//     _setStateScheduled = true;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       _setStateScheduled = false;
//       setState(() {});
//     });
//   }

//   Future<void> _cleanUpController() async {
//     try {
//       _controller?.removeListener(_update);
//     } catch (_) {}

//     try {
//       await _controller?.pause();
//     } catch (_) {}

//     try {
//       _controller?.dispose();
//     } catch (_) {}

//     _controller = null;
//   }

//   /// Public method other widgets can call to change the stream without navigation
//   Future<void> changeStream(String newUrl) async {
//     if (_switchingStream) return;
//     if (newUrl.isEmpty) return;

//     // If same url, ignore
//     if (newUrl == currentUrl) return;

//     _switchingStream = true;
//     // Clean up current controller
//     await _cleanUpController();

//     // Update URL and rebuild OmniVideoPlayer (ValueKey ensures widget rebuild)
//     setState(() {
//       currentUrl = newUrl;
//     });

//     // small delay so OmniVideoPlayer rebuilds and onControllerCreated will create new controller
//     await Future.delayed(const Duration(milliseconds: 120));
//     _switchingStream = false;
//   }

//   // Intercept system lifecycle to pause/resume playback appropriately
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (_controller == null) return;
//     if (state == AppLifecycleState.paused) {
//       try {
//         _controller?.pause();
//       } catch (_) {}
//     } else if (state == AppLifecycleState.resumed && !_userPaused) {
//       try {
//         _controller?.play();
//       } catch (_) {}
//     }
//   }

//   Future<bool> _onWillPop() async {
//     // Prevent double navigation
//     if (_navigatingAway) return false;
//     _navigatingAway = true;

//     await _cleanUpController();

//     // Replace entire navigation stack with HomeScreen to avoid
//     // accidental stacked VideoScreens in history (optional)
//     try {
//       Get.offAll(() => const HomeScreen(), predicate: (_) => false);
//     } catch (_) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//         (route) => false,
//       );
//     }

//     return false;
//   }

//   Future<void> _handleBackTap() async {
//     if (_navigatingAway) return;
//     _navigatingAway = true;
//     await _cleanUpController();
//     try {
//       Get.offAll(() => const HomeScreen(), predicate: (_) => false);
//     } catch (_) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//         (route) => false,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: const Color.fromARGB(250, 240, 240, 240),
//         body: SafeArea(
//           child: Column(
//             children: [
//               AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: Container(
//                   color: Colors.black,
//                   child: Stack(
//                     children: [
//                       // Use ValueKey(currentUrl) so changing currentUrl rebuilds the OmniVideoPlayer
//                       Positioned.fill(
//                         child: OmniVideoPlayer(
//                           key: ValueKey(currentUrl),
//                           callbacks: VideoPlayerCallbacks(
//                             onControllerCreated: (controller) async {
//                               try {
//                                 _controller?.removeListener(_update);
//                               } catch (_) {}
//                               _controller = controller..addListener(_update);

//                               // Try safe autoplay
//                               try {
//                                 await _controller!.play();
//                                 // debugPrint('Auto-play requested successfully.');
//                               } catch (e) {
//                                 await Future.delayed(const Duration(milliseconds: 350));
//                                 try {
//                                   await _controller!.play();
//                                 } catch (_) {}
//                               }

//                               _update();
//                             },
//                           ),
//                           configuration: VideoPlayerConfiguration(
//                             liveLabel: "Live",
//                             videoSourceConfiguration: VideoSourceConfiguration.network(
//                               videoUrl: Uri.parse(currentUrl),
//                             ),
//                             playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
//                               enableForwardGesture: false,
//                               enableBackwardGesture: false,
//                               showReplayButton: false,
//                               showSeekBar: false,
//                               showPlayPauseReplayButton: true,
//                               showFullScreenButton: true,
//                               showSwitchVideoQuality: true,
//                               showLiveIndicator: true,
//                               showMuteUnMuteButton: false,
//                               fullscreenOrientation: Orientation.landscape,
//                             ),
//                           ),
//                         ),
//                       ),

//                       // custom back button (top-left)
//                       Positioned(
//                         top: 10,
//                         left: 10,
//                         child: GestureDetector(
//                           onTap: _handleBackTap,
//                           child: Container(
//                             padding: const EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               color: Colors.black12,
//                               borderRadius: BorderRadius.circular(50),
//                             ),
//                             child: const Icon(
//                               Icons.arrow_back,
//                               color: Colors.white,
//                               size: 22,
//                             ),
//                           ),
//                         ),
//                       ),

//                       // optional custom live badge
//                       const Positioned(
//                         left: 15,
//                         bottom: 10,
//                         child: LiveBadge(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Channel lists (horizontal) — these will call changeStream when inside this screen
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 20),
//                       HorizontalChannelList(
//                         channels: channels,
//                         category: 'sports',
//                         title: 'Live Channels',
//                       ),
//                       const SizedBox(height: 20),
//                       HorizontalChannelList(
//                         channels: channels,
//                         category: 'entertainment',
//                         title: 'Live Channels',
//                       ),
//                       const SizedBox(height: 20),
//                       HorizontalChannelList(
//                         channels: channels,
//                         category: 'News',
//                         title: 'Live Channels',
//                       ),
//                       const SizedBox(height: 30),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// lib/screens/video_screen.dart
import 'package:evonex/elements/horizontal_channel.dart';
import 'package:evonex/models/channel_list.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:evonex/elements/live_badge.dart';

class VideoScreen extends StatefulWidget {
  final String url;
  final String? name;
  const VideoScreen({super.key, required this.url, this.name});

  @override
  VideoScreenState createState() => VideoScreenState();
}

class VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  OmniPlaybackController? _controller;
  late String currentUrl;
  bool _setStateScheduled = false;
  bool _userPaused = false;
  bool _navigatingAway = false;
  bool _switchingStream = false;

  @override
  void initState() {
    super.initState();
    currentUrl = widget.url;
    WidgetsBinding.instance.addObserver(this);
  }

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);

  // Best-effort cleanup — do not call controller.dispose synchronously here.
  try {
    _controller?.removeListener(_update);
  } catch (_) {}
  try {
    _controller?.pause();
  } catch (_) {}
  // Defer final disposal through _cleanUpController which schedules post-frame dispose.
  _cleanUpController();

  _controller = null;
  super.dispose();
}


  void _update() {
    if (_setStateScheduled) return;
    _setStateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setStateScheduled = false;
      setState(() {});
    });
  }

  /// Idempotent cleanup used everywhere
Future<void> _cleanUpController() async {
  final ctrl = _controller;
  if (ctrl == null) return;

  // Remove listeners synchronously so they won't emit during disposal.
  try { ctrl.removeListener(_update); } catch (_) {}

  // Try to pause gracefully (await if supported).
  try { await ctrl.pause(); } catch (_) {}

  // Clear our reference immediately so the rest of the code won't try to use it.
  _controller = null;

  // Defer the actual dispose to the next frame to avoid disposing while
  // inherited dependents are still registered by the framework.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      ctrl.dispose();
    } catch (e, st) {
      debugPrint('Controller dispose error (deferred): $e\n$st');
    }
  });
}

  /// Switch stream inside same screen (no navigation).
  Future<void> changeStream(String newUrl) async {
    if (_switchingStream) return;
    if (newUrl.isEmpty) return;
    if (newUrl == currentUrl) return;

    _switchingStream = true;
    await _cleanUpController();

    if (!mounted) {
      _switchingStream = false;
      return;
    }

    setState(() {
      currentUrl = newUrl;
    });

    // small delay so the OmniVideoPlayer rebuilds and creates new controller
    await Future.delayed(const Duration(milliseconds: 120));
    _switchingStream = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused) {
      try {
        _controller?.pause();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed && !_userPaused) {
      try {
        _controller?.play();
      } catch (_) {}
    }
  }

  /// Shared handler for both system back and custom back button.
  /// For system back (WillPopScope) we return true after cleanup and let framework pop.
  Future<bool> _handleWillPop() async {
    // If already navigating away, allow framework to pop (prevents stuck)
    if (_navigatingAway) return true;

    _navigatingAway = true;
    try {
      await _cleanUpController();
    } catch (e, st) {
      debugPrint('Error cleaning controller in onWillPop: $e\n$st');
    } finally {
      // reset guard — allow subsequent navigations if pop didn't remove screen
      _navigatingAway = false;
    }

    // Returning true lets Navigator.pop happen normally (system back behavior).
    return true;
  }

  /// Called by the top-left custom back button to mimic system back safely.
  Future<void> _onCustomBackPressed() async {
    if (_navigatingAway) return;
    _navigatingAway = true;

    try {
      await _cleanUpController();
    } catch (e, st) {
      debugPrint('Error cleaning controller on custom back: $e\n$st');
    }

    if (!mounted) return;

    // Try to pop (this matches the system back). If can't pop, fallback to pushing Home.
    final didPop = Navigator.of(context).maybePop();
    // maybePop returns a Future<bool?> in some versions, but it's fine to not await here.
    // Reset the guard a bit later to avoid rapid-double taps.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _navigatingAway = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(250, 240, 240, 240),
        body: SafeArea(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: OmniVideoPlayer(
                          key: ValueKey(currentUrl),
                          callbacks: VideoPlayerCallbacks(
                            onControllerCreated: (controller) async {
                              try {
                                _controller?.removeListener(_update);
                              } catch (_) {}
                              _controller = controller..addListener(_update);

                              try {
                                await _controller!.play();
                              } catch (e) {
                                await Future.delayed(const Duration(milliseconds: 350));
                                try {
                                  await _controller!.play();
                                } catch (_) {}
                              }

                              _update();
                            },
                          ),
                          configuration: VideoPlayerConfiguration(
                            liveLabel: "Live",
                            videoSourceConfiguration: VideoSourceConfiguration.network(
                              videoUrl: Uri.parse(currentUrl),
                            ),
                            playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
                              enableForwardGesture: false,
                              enableBackwardGesture: false,
                              showReplayButton: false,
                              showSeekBar: false,
                              showPlayPauseReplayButton: true,
                              showFullScreenButton: true,
                              showSwitchVideoQuality: true,
                              showLiveIndicator: true,
                              showMuteUnMuteButton: false,
                              fullscreenOrientation: Orientation.landscape,
                            ),
                          ),
                        ),
                      ),

                      // custom back button (uses same safe logic)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: _onCustomBackPressed,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      const Positioned(
                        left: 15,
                        bottom: 10,
                        child: LiveBadge(),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      HorizontalChannelList(
                        channels: channels,
                        category: 'sports',
                        title: 'Live Channels',
                      ),
                      const SizedBox(height: 20),
                      HorizontalChannelList(
                        channels: channels,
                        category: 'entertainment',
                        title: 'Live Channels',
                      ),
                      const SizedBox(height: 20),
                      HorizontalChannelList(
                        channels: channels,
                        category: 'News',
                        title: 'Live Channels',
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
