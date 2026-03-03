import 'dart:io';
import 'package:fitnora/animations.dart';
import 'package:fitnora/components/custom_bottom_sheet.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/pages/workout/exercises/create_exercise.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CustomExerciseTile extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final bool options;
  final VoidCallback? onChanged;

  const CustomExerciseTile({
    super.key,
    required this.exercise,
    this.options = true,
    this.onChanged,
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 48, height: 48);
                    }

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
              onPressed: _showExerciseActions,
            )
          : null,
    );
  }

  Future<File> _loadExerciseImage(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagePath = '${dir.path}/$local_images/$fileName';
    return File(imagePath);
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
              onTap: editExercise,
            ),
            CustomBottomSheetItem(
              icon: Icons.delete_forever_rounded,
              label: "Delete Exercise",
              isDestructive: true,
              onTap: _deleteExercise,
            ),
          ],
        );
      },
    );
  }

  Future<void> editExercise() async {
    Navigator.pop(context); // <-- Close bottom sheet first

    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(
        CreateExercisePage(exerciseId: "${widget.exercise["exercise_id"]}"),
      ),
    );

    if (result == true) {
      widget.onChanged?.call();
    }
  }

  Future<void> _deleteExercise() async {
    Navigator.pop(context); // Close bottom sheet first

    final confirm = await showConfirmDialog(
      context,
      title: "Delete Exercise?",
      content: "Are you sure you want to delete \"${widget.exercise['exercise_name']}\"?",
      trueText: "DELETE",
      falseText: "CANCEL",
    );

    if (confirm != true) return;

    final exerciseId = widget.exercise['exercise_id'] as int;
    final hasSessions = await WorkoutDatabaseService.instance.hasExerciseSessions(exerciseId);

    if (hasSessions) {
      // Soft-delete: hide from lists but keep session history intact
      await WorkoutDatabaseService.instance.softDeleteExercise(exerciseId);
    } else {
      // Hard-delete: no session data, safe to remove completely
      await WorkoutDatabaseService.instance.hardDeleteExercise(exerciseId);
    }

    widget.onChanged?.call();
  }
}
