// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

// class ChewieQualityPlayer extends StatefulWidget {
//   final Map<String, String> qualityUrls;  
//   // Example:
//   // {
//   //   "480p": "https://example.com/480.m3u8",
//   //   "720p": "https://example.com/720.m3u8",
//   //   "1080p": "https://example.com/1080.m3u8",
//   // }

//   const ChewieQualityPlayer({super.key, required this.qualityUrls});

//   @override
//   _ChewieQualityPlayerState createState() => _ChewieQualityPlayerState();
// }

// class _ChewieQualityPlayerState extends State<ChewieQualityPlayer> {
//   VideoPlayerController? videoController;
//   ChewieController? chewieController;

//   String selectedQuality = "";

//   @override
//   void initState() {
//     super.initState();
//     selectedQuality = widget.qualityUrls.keys.first;
//     _loadVideo(selectedQuality);
//   }

//   Future<void> _loadVideo(String quality) async {
//     final url = widget.qualityUrls[quality]!;

//     // Dispose old controllers
//     chewieController?.dispose();
//     await videoController?.dispose();

//     videoController = VideoPlayerController.networkUrl(Uri.parse(url));
//     await videoController!.initialize();

//     chewieController = ChewieController(
//       videoPlayerController: videoController!,
//       autoPlay: true,
//       looping: true,
//       allowFullScreen: true,
//       allowPlaybackSpeedChanging: true,
//       showControls: true,
//     );

//     setState(() {});
//   }

//   @override
//   void dispose() {
//     chewieController?.dispose();
//     videoController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (chewieController == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Column(
//       children: [
//         // ---------------------- VIDEO PLAYER ----------------------
//         AspectRatio(
//           aspectRatio: videoController!.value.aspectRatio,
//           child: Chewie(controller: chewieController!),
//         ),

//         // ---------------------- QUALITY BUTTON ----------------------
//         Padding(
//           padding: const EdgeInsets.all(10),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: widget.qualityUrls.keys.map((q) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 5),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         q == selectedQuality ? Colors.blue : Colors.grey[800],
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       selectedQuality = q;
//                     });
//                     _loadVideo(q);
//                   },
//                   child: Text(q),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }
