import 'package:fitnora/animations.dart';
import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/search_field.dart';
import 'package:fitnora/pages/food/add_food.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class ViewFoodsPage extends StatefulWidget {
  const ViewFoodsPage({super.key});

  @override
  State<ViewFoodsPage> createState() => _ViewFoodsPageState();
}

class _ViewFoodsPageState extends State<ViewFoodsPage> {
  List<Map<String, dynamic>> _allFoods = [];
  List<Map<String, dynamic>> _filteredFoods = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase();

    setState(() {
      _filteredFoods = _allFoods.where((f) {
        final name = f['food_name'].toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoaded = false);
    final result = await WorkoutDatabaseService.instance.getFoodItems();
    if (!mounted) return;
    setState(() {
      _allFoods = result;
      _filteredFoods = result;
      _isLoaded = true;
    });
  }

  Future<void> _deleteFood(int foodId) async {
    final confirm = await showConfirmDialog(
      context,
      title: "Delete Food Item?",
      content: "Are you sure you want to delete this food item? This won't affect past meal logs.",
      trueText: "DELETE",
      falseText: "CANCEL",
    );

    if (confirm == true) {
      await WorkoutDatabaseService.instance.deleteFoodItem(foodId);
      await _loadFoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Foods"),
        actions: [
          TextButton(
            onPressed: () => _openAddPage(),
            child: const Text("Create", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 10),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchField(
              hintText: "Search Food Items",
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoaded
                  ? _filteredFoods.isNotEmpty
                      ? ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredFoods.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0xFF1E1E1E),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final food = _filteredFoods[index];
                            return _buildFoodTile(food);
                          },
                        )
                      : const _NoFoodFound()
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTile(Map<String, dynamic> food) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant, color: Colors.white54, size: 24),
      ),
      title: Text(
        food['food_name'],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "Serving: ${food['serving_size']}",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            "${food['calories']} cal · ${food['protein']}g P · ${food['carbs']}g C · ${food['fat']}g F",
            style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () => _openAddPage(foodId: food['food_id']),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteFood(food['food_id'] as int),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPage({int? foodId}) async {
    // If foodId is provided, we would pass it to AddFoodPage to edit.
    // For now, AddFoodPage only supports creating, so we just navigate to it
    // and let the user create a new one, or we can update AddFoodPage to support editing.
    final result = await Navigator.push(
      context,
      AppRoutes.slideFromRight(
        AddFoodPage(foodId: foodId),
      ),
    );
    if (result == true) {
      await _loadFoods();
    }
  }
}

class _NoFoodFound extends StatelessWidget {
  const _NoFoodFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fastfood_outlined,
            color: Colors.white24,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Food Items Found",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontFamily: "Poppins",
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap Create to add a new food item",
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
