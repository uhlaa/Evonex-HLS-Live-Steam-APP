import 'package:flutter/material.dart';

class PlayingEqualizer extends StatefulWidget {
  const PlayingEqualizer({super.key});

  @override
  State<PlayingEqualizer> createState() => _PlayingEqualizerState();
}

class _PlayingEqualizerState extends State<PlayingEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget bar(double min, double max) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final height = min + (max - min) * _controller.value;
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Color(0xFFFF4C5B) ,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      // mainAxisSize: MainAxisSize.max,
      // crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bar(5, 15),
        bar(8, 20),
        bar(6, 17),
        bar(8, 12),
         bar(7, 15),
      ],
    );
  }
}
