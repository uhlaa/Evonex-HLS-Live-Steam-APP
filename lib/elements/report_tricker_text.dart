import 'package:flutter/material.dart';

class NewsTickerText extends StatefulWidget {
  final String message;
  final double height;
  final Duration speed;

  const NewsTickerText({
    super.key,
    required this.message,
    this.height = 30,
    this.speed = const Duration(seconds: 30),
  });

  @override
  State<NewsTickerText> createState() => _NewsTickerTextState();
}

class _NewsTickerTextState extends State<NewsTickerText>
    with SingleTickerProviderStateMixin {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));

      if (!_controller.hasClients) continue;

      // Scroll to the end (left direction)
      await _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: widget.speed,
        curve: Curves.linear,
      );

      // Instantly jump back to start (right side)
      if (_controller.hasClients) {
        _controller.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        children: [
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 60), // gap before repeat
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
