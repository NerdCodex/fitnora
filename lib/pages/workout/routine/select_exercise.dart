import 'dart:io';

import 'package:fitnora/components/search_field.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/user_session.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SelectExercisePage extends StatefulWidget {
  final Set<int> alreadySelectedIds;
  const SelectExercisePage({super.key, required this.alreadySelectedIds});

  @override
  State<SelectExercisePage> createState() => _SelectExercisePageState();
}

class _SelectExercisePageState extends State<SelectExercisePage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final data = await WorkoutDatabaseService.instance.getExercises();
    setState(() {
      _allExercises = data;
      _filtered = data;
    });
  }

  void _search(String q) {
    setState(() {
      _filtered = _allExercises
          .where(
            (e) => e['exercise_name'].toLowerCase().startsWith(q.toLowerCase()),
          )
          .toList();
    });
  }

  void _confirm() {
    final selected = _allExercises
        .where((e) => _selected.contains(e['exercise_id']))
        .toList();

    Navigator.pop(context, selected);
  }

  Future<File?> resolveExerciseImage(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${UserSession().imagesPath}/$fileName');

    return await file.exists() ? file : null;
  }

  Widget _exerciseImage(File? file) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CircleAvatar(
        backgroundColor: const Color.fromARGB(255, 73, 42, 42),
        backgroundImage: file != null ? FileImage(file) : null,
        child: file == null
            ? ClipOval(
                child: Image.asset(
                  'assets/dumbell.png', // 👈 your asset
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Select Exercises"),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text("Done", style: TextStyle(color: Colors.blue)),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 10),
      ),
      body: Column(
        children: [
          // ===== Search =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchField(hintText: "Search Exercise", controller: _searchController, onChanged: _search)
            ),

          // ===== List =====
          Expanded(
            child: _filtered.isNotEmpty
                ? ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final ex = _filtered[index];
                      final id = ex['exercise_id'];

                      // already added to routine → hide
                      if (widget.alreadySelectedIds.contains(id)) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          CheckboxListTile(
                            value: _selected.contains(id),
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.trailing,

                            // 👇 SAFE, FIXED-SIZE LEADING
                            secondary: FutureBuilder<File?>(
                              future: resolveExerciseImage(
                                ex['exercise_image'],
                              ),
                              builder: (context, snapshot) {
                                return _exerciseImage(snapshot.data);
                              },
                            ),

                            title: Text(
                              ex['exercise_name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${ex['exercise_equipment']} | ${ex['exercise_type']}",
                              style: const TextStyle(color: Colors.white54),
                            ),

                            onChanged: (v) {
                              setState(() {
                                v! ? _selected.add(id) : _selected.remove(id);
                              });
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.white12,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  )
                : _emptyState(),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        "No exercises found",
        style: TextStyle(color: Colors.white54, fontSize: 14),
      ),
    );
  }
}
