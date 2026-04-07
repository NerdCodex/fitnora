import 'dart:io';
import 'package:fitnora/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Checks whether a file name or path points to a video.
bool isVideoFile(String path) {
  final ext = path.split('.').last.toLowerCase();
  return ['mp4', 'mov', 'avi', '3gp', 'mkv', 'webm'].contains(ext);
}

class CustomMediaPicker extends StatefulWidget {
  final String initialMedia;
  final Function(String path) onChange;
  final bool allowVideo;
  const CustomMediaPicker({
    super.key,
    required this.onChange,
    this.initialMedia = "",
    this.allowVideo = true,
  });

  @override
  State<CustomMediaPicker> createState() => _CustomMediaPickerState();
}

class _CustomMediaPickerState extends State<CustomMediaPicker> {
  File? _media;
  bool _isVideo = false;
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _previewController;

  @override
  void initState() {
    super.initState();
    if (widget.initialMedia.isNotEmpty) {
      _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaPath =
        '${dir.path}/${UserSession().imagesPath}/${widget.initialMedia}';
    final file = File(mediaPath);
    if (await file.exists()) {
      final video = isVideoFile(mediaPath);
      setState(() {
        _media = file;
        _isVideo = video;
      });
      if (video) {
        _initPreview(file);
      }
    }
  }

  Future<void> _initPreview(File file) async {
    _previewController?.dispose();
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (mounted) {
      setState(() {
        _previewController = controller;
      });
    }
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: _showSourcePicker,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  image: (_media != null && !_isVideo)
                      ? DecorationImage(
                          image: FileImage(_media!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _media == null
                    ? const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 32,
                      )
                    : _isVideo
                        ? ClipOval(
                            child: _previewController != null &&
                                    _previewController!.value.isInitialized
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 140,
                                        width: 140,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _previewController!
                                                .value.size.width,
                                            height: _previewController!
                                                .value.size.height,
                                            child: VideoPlayer(
                                                _previewController!),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.videocam,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.videocam,
                                      color: Colors.white54,
                                      size: 32,
                                    ),
                                  ),
                          )
                        : null,
              ),
            ),
            if (_media != null)
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: _onRemove,
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black87,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _media == null ? "Add Asset" : "Change Asset",
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _onPickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    _previewController?.dispose();
    _previewController = null;

    setState(() {
      _media = File(picked.path);
      _isVideo = false;
      widget.onChange.call(picked.path);
    });
  }

  Future<void> _onPickVideo(ImageSource source) async {
    final XFile? picked = await _picker.pickVideo(
      source: source,
    );
    if (picked == null) return;

    final file = File(picked.path);
    await _initPreview(file);

    setState(() {
      _media = file;
      _isVideo = true;
      widget.onChange.call(picked.path);
    });
  }

  Future<void> _onRemove() async {
    if (_media == null) return;

    _previewController?.dispose();
    _previewController = null;

    setState(() {
      _media = null;
      _isVideo = false;
      widget.onChange.call("");
    });
  }

  Future<void> _showSourcePicker() async {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Choose Media",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text("Take Photo",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _onPickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: Colors.white),
                  title: const Text("Choose Photo from Gallery",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _onPickImage(ImageSource.gallery);
                  },
                ),
                if (widget.allowVideo) ...[
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.videocam, color: Colors.orangeAccent),
                    title: const Text("Record Video",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _onPickVideo(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library,
                        color: Colors.orangeAccent),
                    title: const Text("Choose Video from Gallery",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _onPickVideo(ImageSource.gallery);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Keep backward compatibility — old name still works
typedef CustomImagePicker = CustomMediaPicker;
