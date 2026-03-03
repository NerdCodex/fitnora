import 'package:fitnora/components/custom_bottom_sheet.dart';
import 'package:flutter/material.dart';

class RoutineCard extends StatelessWidget {
  final Map<String, dynamic> routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = (routine['exercises'] as List?) ?? [];
    final preview =
        exercises.isEmpty ? "No exercises" : exercises.join(", ");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine['routine_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: "poppins",
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showActions(context),
                icon: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: "poppins",
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text(
                "Start Routine",
                style: TextStyle(fontFamily: "poppins"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CustomBottomSheet(
        items: [
          CustomBottomSheetItem(
            icon: Icons.edit,
            label: "Edit Routine",
            onTap: onEdit,
          ),
          CustomBottomSheetItem(
            icon: Icons.delete,
            label: "Delete Routine",
            isDestructive: true,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}