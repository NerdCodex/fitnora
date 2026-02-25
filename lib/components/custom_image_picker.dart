import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomImagePicker extends StatefulWidget {
  final String initialImage;
  final Function(String path) onChange;
  const CustomImagePicker({
    super.key,
    required this.onChange,
    this.initialImage = "",
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  File? image;
  final ImagePicker _picker = ImagePicker();

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
                  image: image != null
                      ? DecorationImage(
                          image: FileImage(image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null
                    ? const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 32,
                      )
                    : null,
              ),
            ),
            if (image != null)
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: onRemove,
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
          image == null ? "Add Asset" : "Change Asset",
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> onPick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      image = File(picked.path);
      widget.onChange.call(picked.path);
    });
  }

  Future<void> onRemove() async {
    if (image == null) {
      return;
    }

    setState(() {
      image = null;
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
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white,),
                title: const Text("Camera", style: TextStyle(color: Colors.white),),
                onTap: () {
                  Navigator.pop(context);
                  onPick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white,),
                title: const Text("Gallery", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onPick(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
