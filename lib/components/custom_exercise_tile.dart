import 'dart:io';

import 'package:fitnora/components/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CustomExerciseTile extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final bool options;
  const CustomExerciseTile({
    super.key,
    required this.exercise,
    this.options = true,
  });

  @override
  State<CustomExerciseTile> createState() => _CustomExerciseTileState();
}

class _CustomExerciseTileState extends State<CustomExerciseTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF1E1E1E),
        child: ClipOval(
          child:
              widget.exercise['exercise_image'] != null &&
                  widget.exercise['exercise_image'].toString().isNotEmpty
              ? FutureBuilder<File>(
                  future: _loadExerciseImage(widget.exercise['exercise_image']),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.existsSync()) {
                      return Image.file(
                        snapshot.data!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      );
                    }
                    return Image.asset(
                      "assets/dumbell.png",
                      width: 48,
                      height: 48,
                    );
                  },
                )
              : Image.asset("assets/dumbell.png", width: 48, height: 48),
        ),
      ),
      title: Text(
        widget.exercise['exercise_name'],
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        "${widget.exercise['exercise_equipment']} | ${widget.exercise['exercise_type']}",
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: widget.options
          ? IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              // onPressed: () => _showExerciseActionsSheet(ex),
              onPressed: _showExerciseActions,
            )
          : null,
    );
  }

  Future<File> _loadExerciseImage(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/exerciseimages/$fileName');
  }

  void _showExerciseActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CustomBottomSheet(
          items: [
            CustomBottomSheetItem(
              icon: Icons.edit_rounded,
              label: "Edit Exercise",
              onTap: () {},
            ),
            CustomBottomSheetItem(
              icon: Icons.delete_forever_rounded,
              label: "Delete Exercise",
              isDestructive: true,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}
