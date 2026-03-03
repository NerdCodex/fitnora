import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class AddMeasurementPage extends StatefulWidget {
  final int? measurementId;
  const AddMeasurementPage({super.key, this.measurementId});

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

    final Map<String, dynamic> data = {
      'weight': weight,
      'height': double.tryParse(_heightCtrl.text.trim()),
      'body_fat': double.tryParse(_bodyFatCtrl.text.trim()),
      'chest': double.tryParse(_chestCtrl.text.trim()),
      'waist': double.tryParse(_waistCtrl.text.trim()),
      'hips': double.tryParse(_hipsCtrl.text.trim()),
    };

    if (_isEdit) {
      data['measurement_id'] = widget.measurementId!;
      await WorkoutDatabaseService.instance.updateMeasurement(data);
    } else {
      await WorkoutDatabaseService.instance.addMeasurement(data);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final hasInput = _weightCtrl.text.isNotEmpty ||
        _heightCtrl.text.isNotEmpty ||
        _bodyFatCtrl.text.isNotEmpty;

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
