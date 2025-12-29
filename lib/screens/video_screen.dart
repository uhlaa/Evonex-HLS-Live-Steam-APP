import 'package:evonex/controller/channel_repository.dart';
import 'package:evonex/elements/vertical_channel_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../elements/horizontal_channel.dart';

class PiPManager {
  static const MethodChannel _channel = MethodChannel('pip_channel');

  static Future<void> enterPiP() async {
    try {
      await _channel.invokeMethod('enterPiP');
    } on PlatformException catch (e) {
      debugPrint('PiP error: $e');
    }
  }
}

class VideoScreen extends StatefulWidget {
  final String url;
  final String? name;
  final String? placeholderImage;

  const VideoScreen({
    super.key,
    required this.url,
    this.placeholderImage,
    this.name,
  });

  @override
  VideoScreenState createState() => VideoScreenState();
}

class VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  late String currentUrl;
  String? _currentPlaceholder;

  bool _userPaused = false;
  bool _switchingStream = false;
  bool _navigatingAway = false;

  // 🔑 IMPORTANT FLAG (fixes logo issue)
  bool _forceShowPlaceholder = false;

  VoidCallback? _videoListener;

  late final Stream<List<Map<String, dynamic>>> _channelStream;

  // ------------------------------------------------------------
  // INIT / DISPOSE
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _channelStream = ChannelRepository.streamChannels();

    currentUrl = widget.url;
    _currentPlaceholder = widget.placeholderImage;

    _initializeForUrl(currentUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanUpControllers();
    super.dispose();
  }

  // ------------------------------------------------------------
  // VIDEO INIT
  // ------------------------------------------------------------
  Future<void> _initializeForUrl(String url) async {
    if (url.isEmpty) return;

    await _cleanUpControllers();

    final videoCtrl = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _videoController = videoCtrl;

    _videoListener = () {
      final vc = _videoController;
      if (vc == null || !vc.value.isInitialized) return;

      if (!vc.value.isPlaying && vc.value.position > Duration.zero) {
        _userPaused = true;
      } else if (vc.value.isPlaying) {
        _userPaused = false;
      }

      if (mounted) setState(() {});
    };

    videoCtrl.addListener(_videoListener!);

    try {
      await videoCtrl.initialize();
    } catch (e) {
      debugPrint('Video init error: $e');
    }

    _chewieController = ChewieController(
      videoPlayerController: videoCtrl,
      autoPlay: true,
      looping: true,
      isLive: true,
      allowPlaybackSpeedChanging: false,
      allowMuting: false,
      autoInitialize: true,
      
      allowedScreenSleep: false,
      aspectRatio: 16 / 9,
      // aspectRatio: videoCtrl.value.aspectRatio,
      deviceOrientationsOnEnterFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
    );

    if (mounted) setState(() {});
  }

  Future<void> _cleanUpControllers() async {
    try {
      if (_videoListener != null) {
        _videoController?.removeListener(_videoListener!);
      }
      await _videoController?.pause();
    } catch (_) {}

    final v = _videoController;
    final c = _chewieController;

    _videoController = null;
    _chewieController = null;
    _videoListener = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        c?.dispose();
        v?.dispose();
      } catch (_) {}
    });
  }

  // ------------------------------------------------------------
  // STREAM SWITCH (FIXED)
  // ------------------------------------------------------------
  Future<void> changeStream(String newUrl, {String? placeholderImage}) async {
    if (_switchingStream) return;
    if (newUrl.isEmpty) return;

    _switchingStream = true;

    setState(() {
      currentUrl = newUrl;
      _currentPlaceholder = placeholderImage;
      _forceShowPlaceholder = true; // 🔑 FIX
    });

    await _initializeForUrl(newUrl);

    // ⏳ minimum logo display time
    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _forceShowPlaceholder = false;
      });
    }

    _switchingStream = false;
  }

  // ------------------------------------------------------------
  // APP LIFECYCLE
  // ------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null) return;

    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed && !_userPaused) {
      _videoController?.play();
    }
  }

  Future<bool> _onWillPop() async {
    if (_navigatingAway) return true;
    _navigatingAway = true;
    await _cleanUpControllers();
    return true;
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final playerReady =
        _chewieController != null &&
        _videoController != null &&
        _videoController!.value.isInitialized;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ---------------- VIDEO ----------------
              // ---------------- VIDEO ----------------
AspectRatio(
  aspectRatio: 16 / 9, // ✅ FORCE 16:9
  child: Container(
    color: Colors.black,
    child: Stack(
      children: [
        // 🔹 PLACEHOLDER
        if (_currentPlaceholder != null &&
            (!playerReady || _forceShowPlaceholder))
          Center(
            child: AnimatedOpacity(
              opacity: 0.4,
              duration: const Duration(milliseconds: 250),
              child: _currentPlaceholder!.startsWith('http')
                  ? Image.network(
                      _currentPlaceholder!,
                      width: 160,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      _currentPlaceholder!,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
            ),
          ),

        // 🔹 VIDEO PLAYER
        if (playerReady)
          Positioned.fill(
            child: Chewie(controller: _chewieController!),
          ),
      ],
    ),
  ),
),


              // ---------------- CHANNEL LISTS ----------------
              Expanded(
                child:    Padding(
                  padding: const EdgeInsets.symmetric( vertical: 16, horizontal: 16),
                  child: VerticalChannelList(),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
