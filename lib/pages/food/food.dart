
import 'package:fitnora/animations.dart';
import 'package:fitnora/pages/food/add_food.dart';
import 'package:fitnora/pages/food/log_meal.dart';
import 'package:fitnora/pages/food/view_foods.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  DateTime _selectedDate = DateTime.now();
  Map<String, double> _nutrition = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };
  List<Map<String, dynamic>> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final nutrition = await WorkoutDatabaseService.instance
        .getDailyNutritionSummary(_selectedDate);
    final meals =
        await WorkoutDatabaseService.instance.getMealsByDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      _nutrition = nutrition;
      _meals = meals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food"),
        actions: [
          TextButton.icon(
            onPressed: _goViewFoods,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Food"),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= DATE PICKER =================
                  _buildDateRow(),
                  const SizedBox(height: 16),

                  // ================= NUTRITION SUMMARY =================
                  _buildNutritionCard(),
                  const SizedBox(height: 24),

                  // ================= MEAL SECTIONS =================
                  _buildMealSection("Breakfast", Icons.wb_sunny_outlined),
                  _buildMealSection("Lunch", Icons.restaurant_outlined),
                  _buildMealSection("Dinner", Icons.nightlight_outlined),
                  _buildMealSection("Snack", Icons.cookie_outlined),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'food_fab',
        onPressed: _goLogMeal,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= DATE ROW =================

  Widget _buildDateRow() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final dateStr = isToday
        ? "Today"
        : "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeDate(-1),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: isToday ? null : () => _changeDate(1),
          icon: Icon(
            Icons.chevron_right,
            color: isToday ? Colors.grey.shade800 : Colors.white,
          ),
        ),
      ],
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              surface: Colors.grey.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  // ================= NUTRITION CARD =================

  Widget _buildNutritionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _nutrition['calories']!.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            "Calories",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMacro("Protein", _nutrition['protein']!, Colors.redAccent),
              _buildMacro("Carbs", _nutrition['carbs']!, Colors.lightBlueAccent),
              _buildMacro("Fat", _nutrition['fat']!, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            "${value.toStringAsFixed(1)}g",
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= MEAL SECTION =================

  Widget _buildMealSection(String mealType, IconData icon) {
    final filtered = _meals
        .where((m) => m['meal_type'] == mealType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              mealType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 16),
            child: Text(
              "No items logged",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else
          ...filtered.map((meal) => _buildMealTile(meal)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMealTile(Map<String, dynamic> meal) {
    final cal = ((meal['calories'] as num) * (meal['servings'] as num))
        .toStringAsFixed(0);

    return Dismissible(
      key: ValueKey(meal['meal_log_id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8, left: 28),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await WorkoutDatabaseService.instance
            .deleteMealLog(meal['meal_log_id'] as int);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 28),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['food_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${((meal['servings'] as num) * 100).toStringAsFixed(0)}g",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$cal cal",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NAVIGATION =================

  Future<void> _goLogMeal() async {
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(LogMealPage(loggedDate: _selectedDate)),
    );
    if (result == true) _loadData();
  }

  Future<void> _goViewFoods() async {
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(const ViewFoodsPage()),
    );
    // Reload if anything changed (user might have edited/deleted a food item, affecting past logic if we cared, but mostly just for consistency)
    _loadData();
  }
}