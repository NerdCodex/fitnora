import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class AddFoodPage extends StatefulWidget {
  final int? foodId;
  const AddFoodPage({super.key, this.foodId});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.foodId != null) {
      _loadFood();
    }
  }

  Future<void> _loadFood() async {
    setState(() => _isLoading = true);
    final foods = await WorkoutDatabaseService.instance.getFoodItems();
    final food = foods.firstWhere((f) => f['food_id'] == widget.foodId, orElse: () => {});
    
    if (food.isNotEmpty && mounted) {
      setState(() {
        _nameCtrl.text = food['food_name'] ?? "";
        _caloriesCtrl.text = food['calories']?.toString() ?? "";
        _proteinCtrl.text = food['protein']?.toString() ?? "";
        _carbsCtrl.text = food['carbs']?.toString() ?? "";
        _fatCtrl.text = food['fat']?.toString() ?? "";
        _servingCtrl.text = food['serving_size'] == "1 serving" ? "" : food['serving_size'] ?? "";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.foodId == null ? "Add Food" : "Edit Food"),
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
                  "Add a food item with its nutritional info per serving.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                FormLabel(text: "Food Name *"),
                AppTextField(hintText: "e.g. Chicken Breast", controller: _nameCtrl),

                const SizedBox(height: 10),
                FormLabel(text: "Serving Size"),
                AppTextField(hintText: "e.g. 100g, 1 cup", controller: _servingCtrl),

                const SizedBox(height: 20),
                const Text(
                  "Nutrition (per serving)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                FormLabel(text: "Calories *"),
                AppTextField(
                  hintText: "e.g. 165",
                  controller: _caloriesCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),

                const SizedBox(height: 10),
                FormLabel(text: "Protein (g)"),
                AppTextField(
                  hintText: "e.g. 31",
                  controller: _proteinCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),

                const SizedBox(height: 10),
                FormLabel(text: "Carbs (g)"),
                AppTextField(
                  hintText: "e.g. 0",
                  controller: _carbsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),

                const SizedBox(height: 10),
                FormLabel(text: "Fat (g)"),
                AppTextField(
                  hintText: "e.g. 3.6",
                  controller: _fatCtrl,
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
    final name = _nameCtrl.text.trim();
    final calories = double.tryParse(_caloriesCtrl.text.trim());

    if (name.isEmpty) {
      showMessageDialog(context, "Food name cannot be empty.");
      return;
    }
    if (calories == null || calories < 0) {
      showMessageDialog(context, "Please enter valid calories.");
      return;
    }

    final foodData = {
      'food_name': name,
      'calories': calories,
      'protein': double.tryParse(_proteinCtrl.text.trim()) ?? 0,
      'carbs': double.tryParse(_carbsCtrl.text.trim()) ?? 0,
      'fat': double.tryParse(_fatCtrl.text.trim()) ?? 0,
      'serving_size': _servingCtrl.text.trim().isEmpty
          ? '1 serving'
          : _servingCtrl.text.trim(),
    };

    if (widget.foodId == null) {
      await WorkoutDatabaseService.instance.addFoodItem(foodData);
    } else {
      foodData['food_id'] = widget.foodId!;
      await WorkoutDatabaseService.instance.updateFoodItem(foodData);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final hasInput = _nameCtrl.text.isNotEmpty || _caloriesCtrl.text.isNotEmpty;

    if (!hasInput) {
      Navigator.pop(context);
      return;
    }

    final exit = await showConfirmDialog(
      context,
      title: "Discard food item?",
      content: "You have unsaved data. Do you want to leave?",
      trueText: "DISCARD",
      falseText: "STAY",
    );

    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }
}
