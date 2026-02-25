import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/custom_image_picker.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:flutter/material.dart';

class CreateExercisePage extends StatefulWidget {
  final int exerciseId;
  const CreateExercisePage({super.key, this.exerciseId = -1});

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  String imagePath = "";

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
    if (widget.exerciseId != -1) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseId != -1 ? "Edit Exercise" : "Create Exercise",
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Save", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(child: CustomImagePicker(onChange: (path) {
              showMessageDialog(context, path);
            })),
            const SizedBox(height: 32),
            FormLabel(text: "Exercise Name",),
            AppTextField(hintText: "Exercise Name")
          ],
        ),
      ),
    );
  }
}
