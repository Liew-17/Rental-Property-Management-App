import 'package:flutter/material.dart';
import 'package:flutter_application/models/residence.dart';

class MissingRequirementsSection extends StatefulWidget {
  final Residence residence;
  final void Function(bool allCompleted)? onChanged;

  const MissingRequirementsSection({
    super.key,
    required this.residence,
    this.onChanged,
  });

  @override
  State<MissingRequirementsSection> createState() =>
      _MissingRequirementsSectionState();
}

class _MissingRequirementsSectionState
    extends State<MissingRequirementsSection> {
  late List<RequirementStatus> requirements;

  bool areAllNecessaryCompleted(List<RequirementStatus> requirements) {
  return requirements
      .where((r) => r.necessary) // only check necessary ones
      .every((r) => r.completed); // all must be completed
  }

  @override
  void initState() {
    super.initState();
    requirements = buildRequirements(widget.residence);
    widget.onChanged?.call(areAllNecessaryCompleted(requirements));
  }

  @override
  void didUpdateWidget(covariant MissingRequirementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.residence != widget.residence) {
      requirements = buildRequirements(widget.residence);
      widget.onChanged?.call(areAllNecessaryCompleted(requirements));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Split the list
    final necessary = requirements.where((r) => r.necessary).toList();
    final optional = requirements.where((r) => !r.necessary).toList();
    final allNecessaryCompleted = areAllNecessaryCompleted(requirements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Requirements Checklist",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: allNecessaryCompleted ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: allNecessaryCompleted ? Colors.green.shade300 : Colors.red.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                allNecessaryCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
                color: allNecessaryCompleted ? Colors.green.shade700 : Colors.red.shade700,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  allNecessaryCompleted
                      ? "All required details are completed.\nYou're ready to list your property!"
                      : "Some required details are missing.\nPlease complete them before listing your property.",
                  style: TextStyle(
                    fontSize: 15,
                    color: allNecessaryCompleted ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const SizedBox(height: 8),
                Text(
                  "Required Details",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
              // Necessary items
              ...necessary.map((req) => RequirementItem(
                    key: ValueKey(req.label),
                    item: req,
                  )),

              // Optional items
              if (optional.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  "Optional (Not Required)",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ...optional.map((req) => RequirementItem(
                      key: ValueKey(req.label),
                      item: req,
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<RequirementStatus> buildRequirements(Residence residence) {
    bool titleOk = residence.title?.isNotEmpty ?? false;
    bool descriptionOk = residence.description?.isNotEmpty ?? false;

    bool photosOk = residence.thumbnailUrl != null &&
        residence.thumbnailUrl!.isNotEmpty;

    List<String> missingLocation = [];
    if (residence.state?.isEmpty ?? true) missingLocation.add("State");
    if (residence.district?.isEmpty ?? true) missingLocation.add("District");
    if (residence.city?.isEmpty ?? true) missingLocation.add("City");
    if (residence.address?.isEmpty ?? true) missingLocation.add("Street Address");
    bool locationOk = missingLocation.isEmpty;

    List<String> missing = [];
    if (residence.numBedrooms == null) missing.add("bedrooms");
    if (residence.numBathrooms == null) missing.add("bathrooms");
    if (residence.landSize == null || residence.landSize == 0.0) missing.add("land size");
    if (residence.residenceType == null || residence.residenceType!.isEmpty) missing.add("type");      
    bool detailsOk = missing.isEmpty;

    bool galleryOk = residence.gallery?.isNotEmpty?? false;
    bool rulesOk = residence.rules?.isNotEmpty ?? false;
    bool featuresOk = residence.features?.isNotEmpty ?? false;

    return [
      RequirementStatus(
        label: titleOk ? "Title" : "Title (Missing)",
        completed: titleOk,
        necessary: true,
      ),
      RequirementStatus(
        label: descriptionOk ? "Description" : "Description (Missing)",
        completed: descriptionOk,
        necessary: true,
      ),
      RequirementStatus(
        label: photosOk ? "Property Photos" : "Property Photos (Missing thumbnail)",
        completed: photosOk,
        necessary: true,
      ),
      RequirementStatus(
        label: locationOk
            ? "Location Details"
            : "Location Details (Missing: ${missingLocation.join(', ')})",
        completed: locationOk,
        necessary: true,
      ),
      RequirementStatus(
        label: detailsOk
            ? "Residence Details"
            : "Residence Details (Missing: ${missing.join(', ')})",
        completed: detailsOk,
        necessary: true,
      ),

      // Not necessary
      RequirementStatus(
        label: galleryOk ? "Gallery" : "Gallery (Optional: Add photos)",
        completed: galleryOk,
        necessary: false,
      ),
      RequirementStatus(
        label: rulesOk ? "Rules" : "Rules (Optional: Add rules)",
        completed: rulesOk,
        necessary: false,
      ),
      RequirementStatus(
        label: featuresOk ? "Features" : "Features (Optional: Add features)",
        completed: featuresOk,
        necessary: false,
      ),
    ];
  }
}

class RequirementStatus {
  final String label;
  final bool completed;
  final bool necessary;

  RequirementStatus({required this.label, required this.completed, this.necessary = true});
}

class RequirementItem extends StatelessWidget {
  final RequirementStatus item;

  const RequirementItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            item.completed ? Icons.check_circle : Icons.cancel,
            color: item.completed ? Colors.green : Colors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 16,
                color: item.completed ? Colors.black : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
