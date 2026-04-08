import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenMediaPage extends StatelessWidget {
  final File file;
  final bool isVideo;

  const FullScreenMediaPage({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: isVideo
            ? _FullScreenVideoPlayer(file: file)
            : InteractiveViewer(
                child: Image.file(file),
              ),
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  final File file;

  const _FullScreenVideoPlayer({required this.file});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rewind() {
    final newPosition = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _unwind() {
    final newPosition = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPosition > _controller.value.duration ? _controller.value.duration : newPosition);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          Positioned(
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _rewind,
                  icon: const Icon(Icons.fast_rewind, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: _unwind,
                  icon: const Icon(Icons.fast_forward, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blueAccent,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
