import 'package:flutter/material.dart';
import 'package:flutter_application/theme.dart';

class FeatureEditor extends StatefulWidget {

  final String initialFeatureString;
  final void Function(String updatedFeatureString)? onChanged;

  const FeatureEditor({
    super.key,
    required this.initialFeatureString,
    this.onChanged,
  });

  @override
  State<FeatureEditor> createState() => _FeatureEditorState();
}

class _FeatureEditorState extends State<FeatureEditor> {
  late List<String> _features;

  static const separator = "|";

  @override
  void initState() {
    super.initState();
    _features = widget.initialFeatureString.isEmpty
        ? []
        : widget.initialFeatureString.split(separator);
  }

  void _addFeature() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Add Feature"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter feature"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    if (text.contains(separator)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Feature cannot contain '$separator'")),
                      );
                      return;
                    }

                    setState(() {
                      _features.add(text);
                    });

                    widget.onChanged?.call(_features.join(separator));
                  }
                  Navigator.pop(context);
                },
                child: const Text("Add")),
          ],
        );
      },
    );
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
    widget.onChanged?.call(_features.join(separator));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            return Chip(
              label: Text(
                feature,
                style: const TextStyle(color: Colors.black87),
              ),
              backgroundColor: Colors.grey[200],
              deleteIcon: const Icon(Icons.close, color: Colors.black54),
              onDeleted: () => _removeFeature(index),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _addFeature,
            icon: const Icon(Icons.add),
            label: const Text("Add Feature"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
