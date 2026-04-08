# Feature Implementation: Full Screen Media for Body Measurements

Here are the manual instructions to add full-screen image viewing and video playback (with controls) functionality to the profile page.

## Step 1: Create the FullScreenMediaPage
Create a new file called `lib/pages/profile/full_screen_media_page.dart` and paste the following code into it:

```dart
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
```

## Step 2: Update the Profile Page
Open `lib/pages/profile/profile.dart` and make the following changes:

**1. Import the new page:**
At the top of the file, add the import near the other imports:
```dart
import 'package:fitnora/pages/profile/full_screen_media_page.dart';
```

**2. Update `_ProgressVideoPlayer` widget:**
Find the `_ProgressVideoPlayer` class (usually near the bottom) and modify its constructor to accept an `onLongPress` callback:
```dart
class _ProgressVideoPlayer extends StatefulWidget {
  final File file;
  final VoidCallback? onLongPress; // Add this line
  const _ProgressVideoPlayer({required this.file, this.onLongPress}); // Modify this line
```
And inside `_ProgressVideoPlayerState`'s `build` method, find the `GestureDetector` that wraps the `Stack` and modify it:
```dart
        child: GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          onLongPress: widget.onLongPress, // Add this line here
          child: Stack(
```

**3. Update image and video display in the Daily Card:**
Find the line `if (isVideoFile(fileName))` in `_buildDailyMeasurementCard` (around line 324) and replace it and the subsequent `Image.file` returning statement with the following snippet:
```dart
                    if (isVideoFile(fileName)) {
                      return _ProgressVideoPlayer(
                        file: file,
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenMediaPage(
                                file: file,
                                isVideo: true,
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return GestureDetector(
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenMediaPage(
                              file: file,
                              isVideo: false,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
```
