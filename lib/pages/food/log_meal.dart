import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/search_field.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class LogMealPage extends StatefulWidget {
  final DateTime? loggedDate;
  const LogMealPage({super.key, this.loggedDate});

  @override
  State<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends State<LogMealPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _gramsCtrl = TextEditingController(text: "100");

  List<Map<String, dynamic>> _allFoods = [];
  List<Map<String, dynamic>> _filtered = [];
  int? _selectedFoodId;
  Map<String, dynamic>? _selectedFood;
  String _selectedMealType = "Breakfast";

  final List<String> _mealTypes = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack",
  ];

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _gramsCtrl.addListener(_onGramsChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    final data = await WorkoutDatabaseService.instance.getFoodItems();
    if (!mounted) return;
    setState(() {
      _allFoods = data;
      _filtered = data;
    });
  }

  void _search(String q) {
    setState(() {
      _filtered = _allFoods
          .where(
            (f) => f['food_name'].toString().toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    });
  }

  void _onGramsChanged() {
    setState(() {}); // Rebuild to update the macro preview
  }

  double get _multiplier {
    final grams = double.tryParse(_gramsCtrl.text.trim()) ?? 100;
    return grams / 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Meal"),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Save", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 10),
      ),
      body: Column(
        children: [
          // ================= MEAL TYPE SELECTOR =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mealTypes.length,
                itemBuilder: (context, index) {
                  final type = _mealTypes[index];
                  final isSelected = type == _selectedMealType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: Colors.blue[700],
                      backgroundColor: Colors.grey.shade900,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontFamily: "Poppins",
                      ),
                      onSelected: (_) {
                        setState(() => _selectedMealType = type);
                      },
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ================= GRAMS INPUT =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    "Amount",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _gramsCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "g",
                    style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // ================= MACRO PREVIEW =================
          if (_selectedFood != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroPill("Cal", ((_selectedFood!['calories'] as num) * _multiplier).toStringAsFixed(0), Colors.amber),
                    _macroPill("Prot", "${((_selectedFood!['protein'] as num) * _multiplier).toStringAsFixed(1)}g", Colors.redAccent),
                    _macroPill("Carbs", "${((_selectedFood!['carbs'] as num) * _multiplier).toStringAsFixed(1)}g", Colors.lightBlueAccent),
                    _macroPill("Fat", "${((_selectedFood!['fat'] as num) * _multiplier).toStringAsFixed(1)}g", Colors.orangeAccent),
                  ],
                ),
              ),
            ),
          ],

          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchField(
              hintText: "Search food items",
              controller: _searchCtrl,
              onChanged: _search,
            ),
          ),

          // ================= FOOD LIST =================
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      "No food items found.\nCreate one from the Food tab first.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final food = _filtered[index];
                      final id = food['food_id'] as int;
                      final isSelected = _selectedFoodId == id;

                      return Column(
                        children: [
                          ListTile(
                            tileColor: isSelected
                                ? Colors.blue.withValues(alpha: 0.15)
                                : Colors.transparent,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade800,
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              food['food_name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Per 100g: ${food['calories']} cal · ${food['protein']}g P · ${food['carbs']}g C · ${food['fat']}g F",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.blue, size: 24)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedFoodId = id;
                                _selectedFood = food;
                              });
                            },
                          ),
                          const Divider(
                            height: 1,
                            color: Colors.white12,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _macroPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedFoodId == null) {
      showMessageDialog(context, "Please select a food item.");
      return;
    }

    final grams = double.tryParse(_gramsCtrl.text.trim()) ?? 100;
    if (grams <= 0) {
      showMessageDialog(context, "Please enter a valid amount in grams.");
      return;
    }

    // Store as servings = grams / 100 (since food values are per 100g)
    final logAt = widget.loggedDate ?? DateTime.now();
    await WorkoutDatabaseService.instance.logMeal({
      'food_id': _selectedFoodId,
      'meal_type': _selectedMealType,
      'servings': grams / 100,
      'logged_at': logAt.millisecondsSinceEpoch,
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
