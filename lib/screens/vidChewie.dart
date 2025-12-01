// // file: lib/pages/video_screen_chewie.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:evonex/elements/live_badge.dart';

// class VideoScreen extends StatefulWidget {
//   final String url;
//   final bool showLiveBadge;
//   const VideoScreen({
//     super.key,
//     required this.url,
//     this.showLiveBadge = false,
//   });

//   @override
//   State<VideoScreen> createState() => _VideoScreenState();
// }

// class _VideoScreenState extends State<VideoScreen> {
//   VideoPlayerController? _videoController;
//   ChewieController? _chewieController;

//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _createControllers();
//   }

//   Future<void> _createControllers() async {
//     // Dispose previous if any
//     await _disposeControllers();

//     _videoController = VideoPlayerController.network(
//       widget.url,
//       videoPlayerOptions:  VideoPlayerOptions(mixWithOthers: false),
//     );

//     try {
//       await _videoController!.initialize().timeout(const Duration(seconds: 30));
//     } catch (e) {
//       debugPrint('[CHEWIE] initialize failed: $e');
//       return;
//     }

//     _chewieController = ChewieController(
//       videoPlayerController: _videoController!,
//       autoPlay: true,
//       looping: true,
//       allowFullScreen: true,
//       allowMuting: false,
//       showControlsOnInitialize: true,
//       isLive: true, showOptions: false, systemOverlaysAfterFullScreen: SystemUiOverlay.values, deviceOrientationsAfterFullScreen: DeviceOrientation.values, useRootNavigator: false,
//       allowPlaybackSpeedChanging: false,
//       allowedScreenSleep: false,
//       systemOverlaysOnEnterFullScreen: SystemUiOverlay.values, // Keep screen ON while playing
//       // systemOverlaysAfterFullScreen: SystemUiOverlay.values,
//       // Return to portrait after exiting fullscreen (recommended)

    

//       // Route builder for fullscreen: includes a back button that exits fullscreen only
//       routePageBuilder:
//           (context, animation, secondaryAnimation, controllerProvider) {
//         return Scaffold(
//           backgroundColor: Colors.black,
//           body: SafeArea(
//             child: Stack(
//               children: [
//                 // FULLSCREEN PLAYER
//                 Center(child: controllerProvider),

//                 // BACK BUTTON (exits fullscreen only)
//                 Positioned(
//                   top: 12,
//                   left: 12,
//                   child: GestureDetector(
//                     onTap: () => Navigator.of(context).pop(),
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: Colors.black12,
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       child: const Icon(
//                         Icons.arrow_back,
//                         color: Colors.white,
//                         size: 26,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     _isInitialized = true;
//     if (mounted) setState(() {});
//   }

//   Future<void> _disposeControllers() async {
//     try {
//       _chewieController?.dispose();
//     } catch (_) {}
//     _chewieController = null;

//     try {
//       if (_videoController != null) {
//         await _videoController!.pause();
//         await _videoController!.dispose();
//       }
//     } catch (_) {}
//     _videoController = null;

//     _isInitialized = false;
//   }

//   @override
//   void dispose() {
//     _disposeControllers();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Centered 16:9 player
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: Container(
//                 color: Colors.black,
//                 child: _chewieController != null && _isInitialized
//                     ? Chewie(controller: _chewieController!)
//                     : const Center(
//                         child: CircularProgressIndicator(
//                           color: Colors.redAccent,
//                         ),
//                       ),
//               ),
//             ),

//             // Back Button (non-fullscreen) - pops the VideoScreen
//             Positioned(
//               top: 12,
//               left: 12,
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.black45,
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   child: const Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
