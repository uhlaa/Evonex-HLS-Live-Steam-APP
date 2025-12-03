import 'package:evonex/elements/horizontal_channel.dart';
import 'package:evonex/models/channel_list.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:evonex/elements/live_badge.dart';
import 'package:flutter/services.dart';

class VideoScreen extends StatefulWidget {
  final String url;
  final String? name;
  final String? placeholderImage;
  const VideoScreen({super.key, required this.url, this.placeholderImage, this.name});

  @override
  VideoScreenState createState() => VideoScreenState();
}

class VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  late String currentUrl;
  String? _currentPlaceholder; // <-- holds current placeholder (asset or network)
  bool _setStateScheduled = false;
  bool _userPaused = false;
  bool _navigatingAway = false;
  bool _switchingStream = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentUrl = widget.url;
    _currentPlaceholder = widget.placeholderImage;
    _initializeForUrl(currentUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      _removeControllersListeners();
    } catch (_) {}
    try {
      _pauseControllers();
    } catch (_) {}
    _cleanUpControllers();
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

  Future<void> _initializeForUrl(String url) async {
    if (url.isEmpty) return;
    await _cleanUpControllers();

    final videoCtrl = VideoPlayerController.network(url,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));

    _videoController = videoCtrl;

    try {
      await videoCtrl.initialize();
    } catch (e) {
      debugPrint('Video initialize error: $e');
    }

    // internal listener to detect play/pause and refresh UI
    void listener() {
      final vc = _videoController;
      if (vc == null) return;
      final playing = vc.value.isPlaying;
      if (!playing && vc.value.isInitialized && vc.value.position > Duration.zero) {
        _userPaused = true;
      } else if (playing) {
        _userPaused = false;
      }
      _update();
    }

    videoCtrl.addListener(listener);

    _chewieController = ChewieController(
      videoPlayerController: videoCtrl,
      autoPlay: true,
      looping: true,
      showControls: true,
      showOptions: false,
      isLive: true,
    
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
      ],
      allowPlaybackSpeedChanging: false,
      allowMuting: false,
      allowFullScreen: true,
      additionalOptions: (context) => [],
      // Chewie placeholder still provided (optional) — but we also show our own image layer for fade
      // placeholder: Image.asset("assets/images/zeetv.png")
    );

    _update();
  }

  Future<void> _removeControllersListeners() async {
    try {
      _videoController?.removeListener(_update);
    } catch (_) {}
    // NOTE: we added a listener inline in _initializeForUrl; disposing the controller
    // will remove it — we leave that to _cleanUpControllers deferred disposal.
  }

  Future<void> _pauseControllers() async {
    try {
      if (_videoController != null && _videoController!.value.isPlaying) {
        await _videoController!.pause();
      }
    } catch (_) {}
  }

  Future<void> _cleanUpControllers() async {
    final vctrl = _videoController;
    final cctrl = _chewieController;

    if (vctrl == null && cctrl == null) return;

    try {
      vctrl?.removeListener(_update);
    } catch (_) {}

    try {
      await vctrl?.pause();
    } catch (_) {}

    _videoController = null;
    _chewieController = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        cctrl?.dispose();
      } catch (e, st) {
        debugPrint('Chewie dispose error (deferred): $e\n$st');
      }
      try {
        vctrl?.dispose();
      } catch (e, st) {
        debugPrint('VideoController dispose error (deferred): $e\n$st');
      }
    });
  }

  /// Switch stream inside same screen (no navigation). Also accept an optional placeholder to update image.
  Future<void> changeStream(String newUrl, {String? placeholderImage}) async {
    if (_switchingStream) return;
    if (newUrl.isEmpty) return;
    if (newUrl == currentUrl && placeholderImage == _currentPlaceholder) return;

    _switchingStream = true;

    // Update placeholder immediately so UI shows new image while switching
    setState(() {
      _currentPlaceholder = placeholderImage ?? _currentPlaceholder;
    });

    await _cleanUpControllers();

    if (!mounted) {
      _switchingStream = false;
      return;
    }

    setState(() {
      currentUrl = newUrl;
    });

    // small delay so the rebuild completes and we can initialize
    await Future.delayed(const Duration(milliseconds: 120));
    await _initializeForUrl(newUrl);

    _switchingStream = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null) return;
    if (state == AppLifecycleState.paused) {
      try {
        _videoController?.pause();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed && !_userPaused) {
      try {
        _videoController?.play();
      } catch (_) {}
    }
  }

  Future<bool> _handleWillPop() async {
    if (_navigatingAway) return true;

    _navigatingAway = true;
    try {
      await _cleanUpControllers();
    } catch (e, st) {
      debugPrint('Error cleaning controllers in onWillPop: $e\n$st');
    } finally {
      _navigatingAway = false;
    }

    return true;
  }

  Future<void> _onCustomBackPressed() async {
    if (_navigatingAway) return;
    _navigatingAway = true;

    try {
      await _cleanUpControllers();
    } catch (e, st) {
      debugPrint('Error cleaning controllers on custom back: $e\n$st');
    }

    if (!mounted) return;

    Navigator.of(context).maybePop();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _navigatingAway = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    final playerReady = chewie != null && _videoController != null && _videoController!.value.isInitialized;

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
                      // Placeholder image layer (underneath). Fade out when player is ready.
                      Positioned(
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: playerReady ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _currentPlaceholder != null
                                ? (_currentPlaceholder!.startsWith('http')
                                    ? Image.network(
                                        _currentPlaceholder!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Center(
                                      child: Opacity(
                                        opacity: 0.4,
                                        child: Image.asset(
                                            _currentPlaceholder!,
                                       fit: BoxFit.fill,
                                          width: 160,
                                          // height: double.infinity,
                                         
                                          ),
                                      ),
                                    ))
                                : const SizedBox.expand(child: SizedBox()),
                          ),
                        ),
                      ),

                      // Video player layer (on top). Fade in when ready.
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: playerReady ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Center(
                            child: playerReady ? Chewie(controller: chewie!) : const SizedBox.shrink(),
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
                              color: Colors.white60,
                              size: 22,
                            ),
                          ),
                        ),
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
