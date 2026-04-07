import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndSharePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final workouts = data['workouts'] as List<dynamic>;
    final meals = data['meals'] as List<dynamic>;

    // Group by Date string
    final mapByDate = <String, Map<String, dynamic>>{};

    String formatDate(DateTime dt) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }

    DateTime parseDate(String dStr) {
      final parts = dStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }

    // Group Workouts by date
    for (var w in workouts) {
      final session = w['session'];
      final dt = DateTime.fromMillisecondsSinceEpoch(session['started_at'] as int);
      final dateStr = formatDate(dt);

      mapByDate.putIfAbsent(dateStr, () => {'workouts': [], 'meals': []});
      mapByDate[dateStr]!['workouts'].add(w);
    }

    // Group Meals by date
    for (var m in meals) {
      final dt = DateTime.fromMillisecondsSinceEpoch(m['logged_at'] as int);
      final dateStr = formatDate(dt);

      mapByDate.putIfAbsent(dateStr, () => {'workouts': [], 'meals': []});
      mapByDate[dateStr]!['meals'].add(m);
    }

    final sortedDates = mapByDate.keys.toList()
      ..sort((a, b) => parseDate(a).compareTo(parseDate(b)));

    String _formatDuration(int startMs, int endMs) {
      final dur = Duration(milliseconds: endMs - startMs);
      final h = dur.inHours;
      final m = dur.inMinutes.remainder(60);
      final s = dur.inSeconds.remainder(60);
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m ${s}s';
      return '${s}s';
    }

    String _valueLabel(String? exerciseType, int value) {
      if (exerciseType == null) return value.toString();
      switch (exerciseType.toLowerCase()) {
        case 'cardio':
          return '${value}s';
        case 'duration':
          return '${value}s';
        default:
          return '$value reps';
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              "Fitnora - Activity Report",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
            ),
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> content = [];

          if (sortedDates.isEmpty) {
            content.add(pw.Text("No data available for this date range.",
                style: const pw.TextStyle(fontSize: 14)));
            return content;
          }

          for (var date in sortedDates) {
            final dayData = mapByDate[date]!;
            final dayWorkouts = dayData['workouts'] as List<dynamic>;
            final dayMeals = dayData['meals'] as List<dynamic>;

            // Date header
            content.add(
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(date,
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
            );

            // --- Workout Section ---
            if (dayWorkouts.isNotEmpty) {
              content.add(pw.SizedBox(height: 6));
              content.add(pw.Text("Workout Sessions",
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey700)));
              content.add(pw.SizedBox(height: 8));

              for (var w in dayWorkouts) {
                final session = w['session'];
                final exercises = w['exercises'] as List<dynamic>;

                String routineName = (session['routine_name'] as String?) ?? "Quick Workout";
                String duration = '';
                final startedAt = session['started_at'] as int;
                final completedAt = session['completed_at'] as int;
                if (completedAt > 0) {
                  duration = _formatDuration(startedAt, completedAt);
                }

                content.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(routineName,
                            style: pw.TextStyle(
                                fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        if (duration.isNotEmpty)
                          pw.Text("Duration: $duration",
                              style: const pw.TextStyle(
                                  fontSize: 11, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                );

                if (exercises.isNotEmpty) {
                  // Build table rows from exercises and their sets
                  final List<List<String>> tableData = [];
                  for (var ex in exercises) {
                    final exerciseName = ex['exercise_name'] as String;
                    final exerciseType = ex['exercise_type'] as String?;
                    final sets = ex['sets'] as List<dynamic>;

                    if (sets.isEmpty) {
                      tableData.add([exerciseName, '-', '-', '-']);
                    } else {
                      for (var s in sets) {
                        final setOrder = s['set_order']?.toString() ?? '-';
                        final weight = (s['weight'] as num?)?.toDouble() ?? 0;
                        final value = (s['value'] as int?) ?? 0;

                        tableData.add([
                          exerciseName,
                          'Set $setOrder',
                          weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '-',
                          _valueLabel(exerciseType, value),
                        ]);
                      }
                    }
                  }

                  content.add(
                    pw.TableHelper.fromTextArray(
                      context: context,
                      headers: ['Exercise', 'Set', 'Weight', 'Reps/Duration'],
                      data: tableData,
                      headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10),
                      headerDecoration:
                          const pw.BoxDecoration(color: PdfColors.blueGrey600),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                    ),
                  );
                } else {
                  content.add(pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8),
                    child: pw.Text("  (No exercises recorded)",
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600)),
                  ));
                }
                content.add(pw.SizedBox(height: 10));
              }
            }

            // --- Meals Section ---
            if (dayMeals.isNotEmpty) {
              content.add(pw.SizedBox(height: 6));
              content.add(pw.Text("Food Log",
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey700)));
              content.add(pw.SizedBox(height: 8));

              // Group meals by meal_type
              final groupedMeals = <String, List<dynamic>>{};
              for (var m in dayMeals) {
                final type = m['meal_type'] as String;
                groupedMeals.putIfAbsent(type, () => []);
                groupedMeals[type]!.add(m);
              }

              for (var mealType in groupedMeals.keys) {
                content.add(pw.Text(
                    mealType[0].toUpperCase() + mealType.substring(1),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey800)));
                content.add(pw.SizedBox(height: 4));

                final items = groupedMeals[mealType]!;
                content.add(
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: [
                      'Food',
                      'Quantity',
                      'Calories',
                      'Protein (g)',
                      'Carbs (g)',
                      'Fat (g)'
                    ],
                    data: items.map((m) {
                      double servings = (m['servings'] as num).toDouble();
                      // Parse serving_size (e.g. "100g", "250g", "1 serving")
                      String servingSizeStr = (m['serving_size'] as String?) ?? '100g';
                      double gramsPerServing = 100; // default
                      // Only extract grams if the string contains 'g' (like "100g", "250g")
                      if (servingSizeStr.toLowerCase().contains('g')) {
                        final match = RegExp(r'(\d+\.?\d*)\s*g').firstMatch(servingSizeStr.toLowerCase());
                        if (match != null) {
                          gramsPerServing = double.tryParse(match.group(1)!) ?? 100;
                        }
                      }
                      // For "1 serving", "1 cup", etc. — treat as 100g per serving
                      double totalGrams = servings * gramsPerServing;
                      return [
                        (m['food_name'] as String?) ?? '-',
                        '${totalGrams.toStringAsFixed(0)}g',
                        ((m['calories'] as num) * servings).toStringAsFixed(0),
                        ((m['protein'] as num) * servings).toStringAsFixed(1),
                        ((m['carbs'] as num) * servings).toStringAsFixed(1),
                        ((m['fat'] as num) * servings).toStringAsFixed(1),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.white),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.teal),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                  ),
                );
                content.add(pw.SizedBox(height: 8));
              }
            }
          }

          return content;
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'Fitnora_Export.pdf');
  }
}
