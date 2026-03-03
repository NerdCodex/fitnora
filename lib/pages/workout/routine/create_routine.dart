// import 'dart:io';

// import 'package:fitnora/components/alert.dart';
// import 'package:fitnora/components/dialog.dart';
// import 'package:fitnora/components/form_label.dart';
// import 'package:fitnora/components/text_field.dart';
// import 'package:fitnora/pages/workout/routine/select_exercise.dart';
// import 'package:fitnora/services/constants.dart';
// import 'package:fitnora/services/workout_db_service.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// class RoutineExercise {
//   final int exerciseId;
//   final String exerciseName;
//   final String exerciseEquipment;
//   final String exerciseType;
//   final String? exerciseImage;

//   RoutineExercise({
//     required this.exerciseId,
//     required this.exerciseName,
//     required this.exerciseEquipment,
//     required this.exerciseType,
//     this.exerciseImage,
//   });
// }

// class CreateRoutinePage extends StatefulWidget {
//   const CreateRoutinePage({super.key});

//   @override
//   State<CreateRoutinePage> createState() => _CreateRoutinePageState();
// }

// class _CreateRoutinePageState extends State<CreateRoutinePage> {
//   final TextEditingController _nameController = TextEditingController();
//   final List<RoutineExercise> _exercises = [];

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: goBack,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Create Routine"),
//           actions: [
//             TextButton(
//               onPressed: _saveRoutine,
//               child: const Text("Save", style: TextStyle(color: Colors.blue)),
//             ),
//           ],
//           actionsPadding: const EdgeInsets.only(right: 10),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               FormLabel(text: "Routine Name"),
//               AppTextField(hintText: "Routine Name", controller: _nameController,),
//               const SizedBox(height: 12),
//               Padding(
//                 padding: const EdgeInsets.only(left: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Exercises",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     TextButton.icon(
//                       onPressed: _openSelectExercise,
//                       icon: const Icon(Icons.add, size: 18),
//                       label: const Text("Add"),
//                       style: TextButton.styleFrom(foregroundColor: Colors.blue),
//                     ),
//                   ],
//                 ),
//               ),
      
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF121212),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.white12),
//                     ),
//                     child: _exercises.isEmpty
//                         ? RoutineEmpty()
//                         : ReorderableListView.builder(
//                             itemCount: _exercises.length,
//                             onReorder: (oldIndex, newIndex) {
//                               setState(() {
//                                 if (newIndex > oldIndex) newIndex--;
//                                 final item = _exercises.removeAt(oldIndex);
//                                 _exercises.insert(newIndex, item);
//                               });
//                             },
//                             itemBuilder: (context, index) {
//                               final ex = _exercises[index];
//                               return Dismissible(
//                                 key: ValueKey(ex.exerciseId),
//                                 direction: DismissDirection.endToStart,
//                                 background: Container(
//                                   alignment: Alignment.centerRight,
//                                   padding: const EdgeInsets.only(right: 16),
//                                   color: Colors.red,
//                                   child: const Icon(
//                                     Icons.delete,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 onDismissed: (_) {
//                                   setState(() => _exercises.removeAt(index));
//                                 },
//                                 child: Column(
//                                   children: [
//                                     ListTile(
//                                       leading: _exerciseAvatar(ex.exerciseImage),
//                                       title: Text(
//                                         ex.exerciseName,
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       subtitle: Text(
//                                         "${ex.exerciseEquipment} | ${ex.exerciseType}",
//                                         style: const TextStyle(
//                                           color: Colors.white54,
//                                         ),
//                                       ),
//                                       trailing: const Icon(
//                                         Icons.drag_handle,
//                                         color: Colors.white54,
//                                       ),
//                                     ),
//                                     const Divider(
//                                       height: 1,
//                                       indent: 72,
//                                       color: Colors.white12,
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _exerciseAvatar(String? imageName) {
//     return FutureBuilder<File?>(
//       future: _resolveExerciseImage(imageName),
//       builder: (context, snapshot) {
//         final file = snapshot.data;

//         return CircleAvatar(
//           radius: 22,
//           backgroundColor: const Color(0xFF1E1E1E),
//           backgroundImage: file != null ? FileImage(file) : null,
//           child: file == null
//               ? ClipOval(
//                   child: Image.asset(
//                     "assets/dumbell.png",
//                     width: 44,
//                     height: 44,
//                     fit: BoxFit.cover,
//                   ),
//                 )
//               : null,
//         );
//       },
//     );
//   }

//   Future<File?> _resolveExerciseImage(String? imageName) async {
//     if (imageName == null || imageName.isEmpty) return null;

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File('${dir.path}/$local_images/$imageName');

//     return file.existsSync() ? file : null;
//   }

//   Future<void> _openSelectExercise() async {
//     final result = await Navigator.push<List<Map<String, dynamic>>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SelectExercisePage(
//           alreadySelectedIds: _exercises.map((e) => e.exerciseId).toSet(),
//         ),
//       ),
//     );

//     if (result == null) return;

//     setState(() {
//       for (final ex in result) {
//         if (_exercises.any((e) => e.exerciseId == ex['exercise_id'])) continue;

//         _exercises.add(
//           RoutineExercise(
//             exerciseId: ex['exercise_id'],
//             exerciseName: ex['exercise_name'],
//             exerciseEquipment: ex['exercise_equipment'],
//             exerciseImage: ex['exercise_image'],
//             exerciseType: ex['exercise_type'],
//           ),
//         );
//       }
//     });
//   }

//   void goBack(bool didPop, dynamic result) async {
//     if (didPop) return;

//     final exit = await showConfirmDialog(
//       context,
//       title: "Do you want to stop creating routine?",
//       content: "if you stop now, you'll lose any progress you've made.",
//       trueText: "EXIT",
//       falseText: "CONTINUE",
//     );

//     if (exit == true) {
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     }
//   }

//   Future<void> _saveRoutine() async {
//     final name = _nameController.text.trim();

//     if (name.isEmpty) {
//       showMessageDialog(context, "Routine name cannot be empty");
//       return;
//     }

//     if (_exercises.isEmpty) {
//       showMessageDialog(context, "Add at least one exercise");
//       return;
//     }

//     final payload = {
//       "routine_name": name,
//       "exercises": _exercises.asMap().entries.map((entry) {
//         return {
//           "exercise_id": entry.value.exerciseId,
//           "exercise_order": entry.key,
//         };
//       }).toList(),
//     };

//     await WorkoutDatabaseService.instance.addRoutine(payload);
//     debugPrint("Saved Successfully");
//     if(!mounted) return;
//     Navigator.pop(context);
//   }
// }

// class RoutineEmpty extends StatelessWidget {
//   const RoutineEmpty({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.fitness_center_outlined, size: 42, color: Colors.white24),
//           SizedBox(height: 12),
//           Text("No exercises added", style: TextStyle(color: Colors.white54)),
//           SizedBox(height: 6),
//           Text(
//             "Tap Add to build your routine",
//             style: TextStyle(color: Colors.white30),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:fitnora/components/alert.dart';
import 'package:fitnora/components/dialog.dart';
import 'package:fitnora/components/form_label.dart';
import 'package:fitnora/components/text_field.dart';
import 'package:fitnora/pages/workout/routine/select_exercise.dart';
import 'package:fitnora/services/constants.dart';
import 'package:fitnora/services/workout_db_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RoutineExercise {
  final int exerciseId;
  final String exerciseName;
  final String exerciseEquipment;
  final String exerciseType;
  final String? exerciseImage;

  RoutineExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseEquipment,
    required this.exerciseType,
    this.exerciseImage,
  });
}

class CreateRoutinePage extends StatefulWidget {
  final int? routineId; // null = create, non-null = edit

  const CreateRoutinePage({super.key, this.routineId});

  bool get isEdit => routineId != null;

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  final TextEditingController _nameController = TextEditingController();
  final List<RoutineExercise> _exercises = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _loadRoutineForEdit();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ================= LOAD FOR EDIT =================

  Future<void> _loadRoutineForEdit() async {
    setState(() => _loading = true);

    final routine = await WorkoutDatabaseService.instance
        .getRoutineForEdit(widget.routineId!);

    _nameController.text = routine['routine_name'];

    final List<Map<String, dynamic>> exercises =
        List<Map<String, dynamic>>.from(routine['exercises']);

    exercises.sort(
      (a, b) => a['exercise_order'].compareTo(b['exercise_order']),
    );

    _exercises
      ..clear()
      ..addAll(
        exercises.map(
          (ex) => RoutineExercise(
            exerciseId: ex['exercise_id'],
            exerciseName: ex['exercise_name'],
            exerciseEquipment: ex['exercise_equipment'],
            exerciseType: ex['exercise_type'],
            exerciseImage: ex['exercise_image'],
          ),
        ),
      );

    setState(() => _loading = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: goBack,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? "Edit Routine" : "Create Routine"),
          actions: [
            TextButton(
              onPressed: _loading ? null : _saveRoutine,
              child: const Text("Save",
                  style: TextStyle(color: Colors.blue)),
            ),
          ],
          actionsPadding: const EdgeInsets.only(right: 10),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormLabel(text: "Routine Name"),
                    AppTextField(
                      hintText: "Routine Name",
                      controller: _nameController,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Exercises",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openSelectExercise,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add"),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white12),
                          ),
                          child: _exercises.isEmpty
                              ? const RoutineEmpty()
                              : ReorderableListView.builder(
                                  itemCount: _exercises.length,
                                  onReorder:
                                      (oldIndex, newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) {
                                        newIndex--;
                                      }
                                      final item =
                                          _exercises.removeAt(
                                              oldIndex);
                                      _exercises.insert(
                                          newIndex, item);
                                    });
                                  },
                                  itemBuilder:
                                      (context, index) {
                                    final ex =
                                        _exercises[index];
                                    return Dismissible(
                                      key: ValueKey(
                                          ex.exerciseId),
                                      direction:
                                          DismissDirection
                                              .endToStart,
                                      background: Container(
                                        alignment: Alignment
                                            .centerRight,
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                    right: 16),
                                        color: Colors.red,
                                        child: const Icon(
                                          Icons.delete,
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                                      onDismissed: (_) {
                                        setState(() =>
                                            _exercises
                                                .removeAt(
                                                    index));
                                      },
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading:
                                                _exerciseAvatar(
                                                    ex.exerciseImage),
                                            title: Text(
                                              ex.exerciseName,
                                              style:
                                                  const TextStyle(
                                                      color:
                                                          Colors
                                                              .white),
                                            ),
                                            subtitle: Text(
                                              "${ex.exerciseEquipment} | ${ex.exerciseType}",
                                              style:
                                                  const TextStyle(
                                                      color:
                                                          Colors
                                                              .white54),
                                            ),
                                            trailing:
                                                const Icon(
                                              Icons
                                                  .drag_handle,
                                              color: Colors
                                                  .white54,
                                            ),
                                          ),
                                          const Divider(
                                            height: 1,
                                            indent: 72,
                                            color: Colors
                                                .white12,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ================= IMAGE =================

  Widget _exerciseAvatar(String? imageName) {
    return FutureBuilder<File?>(
      future: _resolveExerciseImage(imageName),
      builder: (context, snapshot) {
        final file = snapshot.data;

        return CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1E1E1E),
          backgroundImage:
              file != null ? FileImage(file) : null,
          child: file == null
              ? ClipOval(
                  child: Image.asset(
                    "assets/dumbell.png",
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<File?> _resolveExerciseImage(
      String? imageName) async {
    if (imageName == null || imageName.isEmpty){
      return null;
    }
      

    final dir =
        await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/$local_images/$imageName');

    return file.existsSync() ? file : null;
  }

  // ================= SELECT =================

  Future<void> _openSelectExercise() async {
    final result =
        await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExercisePage(
          alreadySelectedIds:
              _exercises.map((e) => e.exerciseId).toSet(),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      for (final ex in result) {
        if (_exercises.any(
            (e) => e.exerciseId == ex['exercise_id'])) {
              continue;
            }
          

        _exercises.add(
          RoutineExercise(
            exerciseId: ex['exercise_id'],
            exerciseName: ex['exercise_name'],
            exerciseEquipment:
                ex['exercise_equipment'],
            exerciseImage: ex['exercise_image'],
            exerciseType: ex['exercise_type'],
          ),
        );
      }
    });
  }

  // ================= SAVE =================

  Future<void> _saveRoutine() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      showMessageDialog(
          context, "Routine name cannot be empty");
      return;
    }

    if (_exercises.isEmpty) {
      showMessageDialog(
          context, "Add at least one exercise");
      return;
    }

    final payload = {
      "routine_name": name,
      "exercises":
          _exercises.asMap().entries.map((entry) {
        return {
          "exercise_id": entry.value.exerciseId,
          "exercise_order": entry.key,
        };
      }).toList(),
    };

    if (widget.isEdit) {
      await WorkoutDatabaseService.instance.updateRoutine(
        routineId: widget.routineId!,
        data: payload,
      );
    } else {
      await WorkoutDatabaseService.instance
          .addRoutine(payload);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ================= BACK =================

  void goBack(bool didPop, dynamic result) async {
    if (didPop) return;

    final exit = await showConfirmDialog(
      context,
      title:
          "Do you want to stop creating routine?",
      content:
          "if you stop now, you'll lose any progress you've made.",
      trueText: "EXIT",
      falseText: "CONTINUE",
    );

    if (exit == true) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class RoutineEmpty extends StatelessWidget {
  const RoutineEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_outlined,
              size: 42, color: Colors.white24),
          SizedBox(height: 12),
          Text("No exercises added",
              style:
                  TextStyle(color: Colors.white54)),
          SizedBox(height: 6),
          Text(
            "Tap Add to build your routine",
            style:
                TextStyle(color: Colors.white30),
          ),
        ],
      ),
    );
  }
}