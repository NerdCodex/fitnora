import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/custom_dropdown.dart';
import 'package:fitnora/components/custom_image_picker.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

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
    if (widget.exerciseId.isEmpty) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseId.isEmpty ? "Edit Exercise" : "Create Exercise",
        ),
        actions: [
          TextButton(
            onPressed: saveExercise,
            child: const Text("Save", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: CustomImagePicker(
                  onChange: (path) {
                    showMessageDialog(context, path);
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
                hintText: "Select Equipment",
                onChange: (value) {
                  selectedEquipment = value!;
                },
              ),
              const SizedBox(height: 10),
              FormLabel(text: "Exercise measurement"),
              CustomDropDown(
                items: ["reps", "seconds"],
                hintText: "Select Measurement",
                onChange: (value) {
                  selectedExerciseType = value!;
                },
              ),
            ],
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

    if (widget.exerciseId.isEmpty) {
      WorkoutDatabaseService.instance.addExercise(
        "",
        name,
        selectedEquipment,
        selectedExerciseType,
      );
      debugPrint("Saved Exercise Successfully");
      Navigator.pop(context);
    }
  }
}
