import 'package:fitnora/animations.dart';
import 'package:fitnora/components/custom_exercise_tile.dart';
import 'package:fitnora/components/search_field.dart';
import 'package:fitnora/pages/workout/exercises/create_exercise.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';

class ViewExercisesPage extends StatefulWidget {
  const ViewExercisesPage({super.key});

  @override
  State<ViewExercisesPage> createState() => _ViewExercisesPageState();
}

class _ViewExercisesPageState extends State<ViewExercisesPage> {
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];

  final TextEditingController _searchController = TextEditingController();
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase();

    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final name = ex['exercise_name'].toString().toLowerCase();
        return name.startsWith(q);
      }).toList();
    });
  }

  Future<void> loadExercises() async {
    setState(() => isLoaded = false);
    final result = await WorkoutDatabaseService.instance.getExercises();
    if (!mounted) return;
    setState(() {
      _allExercises = result;
      _filteredExercises = result;
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercises"),
        actions: [
          TextButton(
            onPressed: openCreatePage,
            child: const Text("Create", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 10),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchField(hintText: "Search Exercise", controller: _searchController, onChanged: _onSearchChanged),

            const SizedBox(height: 12),
            Expanded(
              child: isLoaded
                  ? _filteredExercises.isNotEmpty
                        ? ListView.separated(
                            itemCount: _filteredExercises.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: Color(0xFF1E1E1E),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final exercise = _filteredExercises[index];

                              return CustomExerciseTile(exercise: exercise, onChanged: loadExercises,);
                            },
                          )
                        : NoExerciseFound()
                  : Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openCreatePage() async {
    await Navigator.push(
      context,
      AppRoutes.slideFromRight(CreateExercisePage()),
    );
    await loadExercises();
  }
}

class NoExerciseFound extends StatelessWidget {
  const NoExerciseFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white54,
            size: 50,
          ),
          const SizedBox(height: 8),
          const Text(
            "No Exercises Found",
            style: TextStyle(color: Colors.white54, fontFamily: "Poppins"),
          ),
        ],
      ),
    );
  }
}
