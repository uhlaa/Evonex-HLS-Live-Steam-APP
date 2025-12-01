// lib/screens/video_screen.dart
import 'package:evonex/elements/horizontal_channel.dart';
import 'package:evonex/models/channel_list.dart';
import 'package:evonex/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:evonex/elements/live_badge.dart';

class VideoScreen extends StatefulWidget {
  final String url; // required
  final String? name; // optional

  const VideoScreen({
    super.key,
    required this.url,
    this.name,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  OmniPlaybackController? _controller;

  // Schedule guard to avoid continuous setState spam
  bool _setStateScheduled = false;

  // Track whether we intentionally paused from UI to avoid auto-retry fighting user
  bool _userPaused = false;

  void _update() {
    // If we've already scheduled a rebuild, do nothing.
    if (_setStateScheduled) return;
    _setStateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setStateScheduled = false;
      setState(() {});
    });
  }

  Future<void> _cleanUpController() async {
    // detach listener
    try {
      _controller?.removeListener(_update);
    } catch (_) {}

    // pause and dispose if supported by controller
    try {
      await _controller?.pause();
    } catch (_) {}

    try {
      // Some controllers expose dispose; others might not.
      // If OmniPlaybackController has dispose, this will call it.
       _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Best effort cleanup (non-await inside dispose is okay because we used try catches)
    // But we also call the async cleanup in WillPopScope before navigation.
    try {
      _controller?.removeListener(_update);
    } catch (_) {}
    try {
      _controller?.pause();
    } catch (_) {}
    try {
      _controller?.dispose();
    } catch (_) {}
    _controller = null;
    super.dispose();
  }

  final bool showCustomLiveBadge = true;

  // Intercept system lifecycle to pause/resume playback appropriately
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

  Future<bool> _onWillPop() async {
    // When user navigates back, ensure controller is cleaned then replace route
    await _cleanUpController();
    // Replace this screen with Home (so we don't leave multiple stacked video screens)
    // Use Get.off to replace current route
    try {
      Get.off(() => HomeScreen(), preventDuplicates: true);
    } catch (_) {
      // fallback to normal Navigator if Get fails for any reason
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
    // returning false because we already handled navigation
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                          callbacks: VideoPlayerCallbacks(
                            onControllerCreated: (controller) async {
                              // detach old listener
                              try {
                                _controller?.removeListener(_update);
                              } catch (_) {}

                              // attach new controller and listener
                              _controller = controller..addListener(_update);

                              // Try a safe autoplay sequence:
                              // 1) try play
                              // 2) retry once after short delay if needed
                              try {
                                await _controller!.play();
                                debugPrint('Auto-play requested successfully.');
                              } catch (e) {
                                debugPrint('Auto-play failed first attempt: $e');
                                await Future.delayed(const Duration(milliseconds: 350));
                                try {
                                  await _controller!.play();
                                  debugPrint('Auto-play retry succeeded.');
                                } catch (e) {
                                  debugPrint('Auto-play retry failed: $e');
                                }
                              }

                              // Ensure UI updates at least once after controller ready
                              _update();
                            },
                          ),
                          configuration: VideoPlayerConfiguration(
                            liveLabel: "Live",
                            videoSourceConfiguration: VideoSourceConfiguration.network(
                              videoUrl: Uri.parse(widget.url),
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
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: () async {
                            // Clean up controller then replace route
                            await _cleanUpController();
                            Get.off(() => HomeScreen(), preventDuplicates: true);
                          },
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
                      if (showCustomLiveBadge)
                        const Positioned(
                          left: 15,
                          bottom: 10,
                          child: LiveBadge(),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
