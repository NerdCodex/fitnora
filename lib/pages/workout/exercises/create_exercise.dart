import 'dart:io';

import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/custom_dropdown.dart';
import 'package:fitnora/components/custom_image_picker.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CreateExercisePage extends StatefulWidget {
  final String exerciseId;
  const CreateExercisePage({super.key, this.exerciseId = ""});

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final TextEditingController _exerciseNameController = TextEditingController();
  String imagePath = "";
  String selectedEquipment = "";
  String selectedExerciseType = "";
  bool imageChanged = false;
  bool isLoading = false;

  final List<String> equipmentList = [
    "None",
    "Barbell",
    "Dumbbell",
    "Kettlebell",
    "Machine",
    "Plate",
    "Resistance Band",
    "Suspension Band",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.exerciseId.isNotEmpty) {
      loadExercise();
    }
  }

  Future<void> loadExercise() async {
    setState(() {
      isLoading = true;
    });
    final result = await WorkoutDatabaseService.instance.getExercise(
      widget.exerciseId,
    );

    setState(() {
      debugPrint("exercise_id: ${widget.exerciseId}");
      imagePath = result!["exercise_image"];
      _exerciseNameController.text = result["exercise_name"];
      selectedEquipment = result["exercise_equipment"];
      selectedExerciseType = result["exercise_type"];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.exerciseId.isEmpty ? "Create Exercise" : "Edit Exercise",
          ),
          actions: [
            TextButton(
              onPressed: saveExercise,
              child: const Text("Save", style: TextStyle(color: Colors.blue)),
            ),
          ],
          actionsPadding: EdgeInsets.only(right: 10),
        ),
        body: isLoading
            ? Center(child: const CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: CustomImagePicker(
                          initialImage: imagePath,
                          onChange: (path) {
                            setState(() {
                              imagePath = path;
                              imageChanged = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      FormLabel(text: "Exercise Name"),
                      AppTextField(
                        hintText: "Exercise Name",
                        controller: _exerciseNameController,
                      ),
                      const SizedBox(height: 10),
                      FormLabel(text: "Exercise Equipment"),
                      CustomDropDown(
                        items: equipmentList,
                        initialValue: selectedEquipment,
                        hintText: "Select Equipment",
                        onChange: (value) {
                          selectedEquipment = value!;
                        },
                      ),
                      const SizedBox(height: 10),
                      FormLabel(text: "Exercise measurement"),
                      CustomDropDown(
                        items: ["reps", "seconds"],
                        initialValue: selectedExerciseType,
                        hintText: "Select Measurement",
                        onChange: (value) {
                          selectedExerciseType = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> saveExercise() async {
    final name = _exerciseNameController.text.trim();

    if (name.isEmpty ||
        selectedEquipment.isEmpty ||
        selectedExerciseType.isEmpty) {
      showMessageDialog(context, "Fields cannot be empty");
      return;
    }

    String savedImageFileName = imagePath;
    String oldImageFileName = "";

    // If editing, keep reference of old image
    if (widget.exerciseId.isNotEmpty) {
      final old = await WorkoutDatabaseService.instance.getExercise(
        widget.exerciseId,
      );
      oldImageFileName = old?["exercise_image"] ?? "";
    }

    // If image changed → save new image
    if (imageChanged && imagePath.isNotEmpty) {
      savedImageFileName = await saveImage(File(imagePath));
    }

    if (widget.exerciseId.isEmpty) {
      // CREATE
      await WorkoutDatabaseService.instance.addExercise(
        savedImageFileName,
        name,
        selectedEquipment,
        selectedExerciseType,
      );
    } else {
      // UPDATE
      await WorkoutDatabaseService.instance.updateExercise(
        widget.exerciseId,
        savedImageFileName,
        name,
        selectedEquipment,
        selectedExerciseType,
      );

      // Delete old image AFTER successful update
      if (imageChanged &&
          oldImageFileName.isNotEmpty &&
          oldImageFileName != savedImageFileName) {
        await deleteImage(oldImageFileName);
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<String> saveImage(File imageFile) async {
    // Get app documents directory (persistent storage)
    final appDir = await getApplicationDocumentsDirectory();

    // Create images folder path
    final imagesDir = Directory(p.join(appDir.path, local_images));

    // Create folder if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // Generate file name
    final fileName =
        "exercise_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}";

    final savedPath = p.join(imagesDir.path, fileName);

    // Copy file
    await imageFile.copy(savedPath);

    return fileName;
  }

  Future<void> deleteImage(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, local_images, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint("Deleted old image: $fileName");
      }
    } catch (e) {
      debugPrint("Image delete error: $e");
    }
  }

  void goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final exit = await showConfirmDialog(
      context,
      title: widget.exerciseId.isEmpty
          ? "Do you want to stop creating exercise?"
          : "Do you want to stop editing exercise?",
      content: "if you stop now, you'll lose any progress you've made.",
      trueText: "EXIT",
      falseText: "CONTINUE",
    );

    if (exit == true) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
