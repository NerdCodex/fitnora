import 'dart:io';
import 'dart:math';

import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/custom_image_picker.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AddMeasurementPage extends StatefulWidget {
  final int? measurementId;
  final DateTime? measuredDate;
  const AddMeasurementPage({super.key, this.measurementId, this.measuredDate});

  @override
  State<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends State<AddMeasurementPage> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();
  bool _isEdit = false;
  bool _isLoading = false;

  String _imagePath = "";
  bool _imageChanged = false;
  final List<String> _unsavedImagePaths = [];

  @override
  void initState() {
    super.initState();
    if (widget.measurementId != null) {
      _isEdit = true;
      _loadMeasurement();
    }
  }

  Future<void> _loadMeasurement() async {
    setState(() => _isLoading = true);
    final m = await WorkoutDatabaseService.instance.getMeasurement(widget.measurementId!);
    if (m != null && mounted) {
      setState(() {
        _weightCtrl.text = m['weight']?.toString() ?? '';
        _heightCtrl.text = m['height']?.toString() ?? '';
        _bodyFatCtrl.text = m['body_fat']?.toString() ?? '';
        _chestCtrl.text = m['chest']?.toString() ?? '';
        _waistCtrl.text = m['waist']?.toString() ?? '';
        _hipsCtrl.text = m['hips']?.toString() ?? '';
        _imagePath = m['progress_image']?.toString() ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();

    // Cleanup unsaved images when leaving screen
    for (var path in _unsavedImagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        try { file.deleteSync(); } catch (_) {}
      }
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? "Edit Measurement" : "Add Measurement"),
          leading: BackButton(onPressed: () => _goBack(false, null)),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text("Save", style: TextStyle(color: Colors.blue)),
            ),
          ],
          actionsPadding: const EdgeInsets.only(right: 10),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Record your body measurements. Only weight is required.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // ============ PROGRESS IMAGE ============
                      Center(
                        child: CustomImagePicker(
                          initialImage: _imagePath,
                          onChange: (path) async {
                            if (path.isEmpty) {
                              setState(() {
                                _imagePath = path;
                                _imageChanged = true;
                              });
                              return;
                            }
                            // Save picked image to app document directory temporarily
                            final savedName = await _saveImage(File(path));
                            final appDir = await getApplicationDocumentsDirectory();
                            final newPath = p.join(appDir.path, local_images, savedName);
                            _unsavedImagePaths.add(newPath);

                            setState(() {
                              _imagePath = newPath;
                              _imageChanged = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      FormLabel(text: "Weight (kg) *"),
                      AppTextField(
                        hintText: "e.g. 75",
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 10),
                      FormLabel(text: "Height (cm)"),
                      AppTextField(
                        hintText: "e.g. 175",
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 10),
                      FormLabel(text: "Body Fat (%)"),
                      AppTextField(
                        hintText: "e.g. 15",
                        controller: _bodyFatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Circumferences (cm)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      FormLabel(text: "Chest"),
                      AppTextField(
                        hintText: "e.g. 100",
                        controller: _chestCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 10),
                      FormLabel(text: "Waist"),
                      AppTextField(
                        hintText: "e.g. 80",
                        controller: _waistCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 10),
                      FormLabel(text: "Hips"),
                      AppTextField(
                        hintText: "e.g. 95",
                        controller: _hipsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || weight <= 0) {
      showMessageDialog(context, "Please enter a valid weight.");
      return;
    }

    String savedImageFileName = _imagePath;
    String oldImageFileName = "";

    // If editing, keep reference of old image
    if (_isEdit) {
      final old = await WorkoutDatabaseService.instance.getMeasurement(widget.measurementId!);
      oldImageFileName = old?['progress_image']?.toString() ?? "";
    }

    // New logic: _imagePath is already saved in app doc by onChange (CustomImagePicker)
    // We just need to extract the filename relative to the local_images dir
    if (_imageChanged && _imagePath.isNotEmpty) {
      savedImageFileName = p.basename(_imagePath);
      // Remove it from unsaved paths so it doesn't get deleted on dispose
      _unsavedImagePaths.removeWhere((path) => path == _imagePath);
    }

    final Map<String, dynamic> data = {
      'weight': weight,
      'height': double.tryParse(_heightCtrl.text.trim()),
      'body_fat': double.tryParse(_bodyFatCtrl.text.trim()),
      'chest': double.tryParse(_chestCtrl.text.trim()),
      'waist': double.tryParse(_waistCtrl.text.trim()),
      'hips': double.tryParse(_hipsCtrl.text.trim()),
      'progress_image': savedImageFileName,
    };

    if (_isEdit) {
      data['measurement_id'] = widget.measurementId!;
      await WorkoutDatabaseService.instance.updateMeasurement(data);

      // Delete old image AFTER successful update
      if (_imageChanged &&
          oldImageFileName.isNotEmpty &&
          oldImageFileName != savedImageFileName) {
        await _deleteImage(oldImageFileName);
      }
    } else {
      if (widget.measuredDate != null) {
        data['measured_at'] = widget.measuredDate!.millisecondsSinceEpoch;
      }
      await WorkoutDatabaseService.instance.addMeasurement(data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<String> _saveImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, local_images));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final randomInt = Random().nextInt(999999999);
    final fileName =
        "progress_image_$randomInt${p.extension(imageFile.path)}";
    final savedPath = p.join(imagesDir.path, fileName);

    await imageFile.copy(savedPath);
    return fileName;
  }

  Future<void> _deleteImage(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, local_images, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint("Deleted old progress image: $fileName");
      }
    } catch (e) {
      debugPrint("Image delete error: $e");
    }
  }

  void _goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final hasInput = _weightCtrl.text.isNotEmpty ||
        _heightCtrl.text.isNotEmpty ||
        _bodyFatCtrl.text.isNotEmpty ||
        _imageChanged;

    if (!hasInput) {
      Navigator.pop(context);
      return;
    }

    final exit = await showConfirmDialog(
      context,
      title: "Discard measurement?",
      content: "You have unsaved data. Do you want to leave?",
      trueText: "DISCARD",
      falseText: "STAY",
    );

    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }
}
