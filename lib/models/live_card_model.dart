// // models/live_match_model.dart
// import 'package:evonex/elements/live_match_card.dart';

// class LiveMatchModel {
//   final int id;
//   final String matchName;
//   final String? matchCategories;
//   final int? teamAId;
//   final int? teamBId;
//   final DateTime matchStart;
//   final DateTime matchEnd;
//   final bool isLive;
//   final int? liveVideoUrl;

//   LiveMatchModel({
//     required this.id,
//     required this.matchName,
//     this.matchCategories,
//     this.teamAId,
//     this.teamBId,
//     required this.matchStart,
//     required this.matchEnd,
//     required this.isLive,
//     this.liveVideoUrl,
//   });

//   factory LiveMatchModel.fromMap(Map<String, dynamic> m) {
//     return LiveMatchModel(
//       id: (m['id'] as int),
//       matchName: (m['match_name'] as String),
//       matchCategories: m['match_categories'] as String?,
//       teamAId: m['team_a_id'] as int?,
//       teamBId: m['team_b_id'] as int?,
//       matchStart: parseDbTimestamp(m['match_start_time']),
//       matchEnd: parseDbTimestamp(m['match_end_time']),
//       isLive: (m['is_live'] as bool?) ?? false,
//       liveVideoUrl: m['live_video_url'] as int?,
//     );
//   }
// }
