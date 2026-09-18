import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'camp.dart';

class CreateCampScreen extends StatefulWidget {
  final String? campId;
  final Map<String, dynamic>? initialData;
  final bool isEdit;

  const CreateCampScreen({
    super.key,
    this.campId,
    this.initialData,
    this.isEdit = false,
  });

  @override
  State<CreateCampScreen> createState() => _CreateCampScreenState();
}

class _CreateCampScreenState extends State<CreateCampScreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController locationController = TextEditingController();

  final TextEditingController capacityController = TextEditingController();

  String? selectedDate;
  String? startTime;
  String? endTime;

  List<String> selectedBloodGroups = [];

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.initialData != null) {
      final data = widget.initialData!;

      titleController.text = data['name']?.toString() ?? '';

      locationController.text = data['location']?.toString() ?? '';

      capacityController.text = data['slotCapacity']?.toString() ?? '';

      selectedDate = data['date']?.toString();

      startTime = data['startTime']?.toString();

      endTime = data['endTime']?.toString();

      if (data['bloodGroupsNeeded'] is List) {
        selectedBloodGroups = List<String>.from(data['bloodGroupsNeeded']);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Camp' : 'Create Camp')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CAMP TITLE
            const Text(
              'Camp Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Enter camp title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // DATE
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            InkWell(
              onTap: selectDate,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(selectedDate ?? 'Select Date'),
              ),
            ),

            const SizedBox(height: 20),

            // LOCATION
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: locationController,

              decoration: const InputDecoration(
                hintText: 'Enter location',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // START TIME
            const Text(
              'Start Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: selectStartTime,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(startTime ?? 'Select Start Time'),
              ),
            ),

            const SizedBox(height: 20),

            // ENDING TIME
            const Text(
              'Ending Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: selectEndTime,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(endTime ?? 'Select Ending Time'),
              ),
            ),

            const SizedBox(height: 20),

            // SLOT CAPACITY
            const Text(
              'Slot Capacity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: capacityController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                hintText: 'Enter slot capacity',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // BLOOD GROUPS
            const Text(
              'Blood Groups Needed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: bloodGroups.map((group) {
                final isSelected = selectedBloodGroups.contains(group);

                return FilterChip(
                  label: Text(group),

                  selected: isSelected,

                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedBloodGroups.add(group);
                      } else {
                        selectedBloodGroups.remove(group);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () async {
                  await createCamp();
                },

                child: Text(
                  widget.isEdit ? 'UPDATE CAMP' : 'CREATE CAMP',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CREATE CAMP IN FIRESTORE
Future<void> createCamp() async {
  if (titleController.text.trim().isEmpty ||
      locationController.text.trim().isEmpty ||
      capacityController.text.trim().isEmpty ||
      selectedDate == null ||
      startTime == null ||
      endTime == null ||
      selectedBloodGroups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all fields'),
      ),
    );

    return;
  }

  try {
    final campData = {
      'name': titleController.text.trim(),
      'location': locationController.text.trim(),
      'date': selectedDate,
      'startTime': startTime,
      'endTime': endTime,
      'slotCapacity': int.parse(
        capacityController.text.trim(),
      ),
      'bloodGroupsNeeded': selectedBloodGroups,
    };

    // EDIT EXISTING CAMP
    if (widget.isEdit && widget.campId != null) {
      await FirebaseFirestore.instance
          .collection('camps')
          .doc(widget.campId)
          .update(campData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camp updated successfully!'),
        ),
      );
    }

    // CREATE NEW CAMP
    else {
      await FirebaseFirestore.instance
          .collection('camps')
          .add(campData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camp created successfully!'),
        ),
      );
    }

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
      ),
    );
  }
}

  // SELECT DATE
  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,

      firstDate: DateTime.now(),

      lastDate: DateTime(2030),

      initialDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate =
            '${pickedDate.day}/'
            '${pickedDate.month}/'
            '${pickedDate.year}';
      });
    }
  }

  // SELECT START TIME
  Future<void> selectStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,

      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        startTime = pickedTime.format(context);
      });
    }
  }

  // SELECT END TIME
  Future<void> selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,

      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        endTime = pickedTime.format(context);
      });
    }
  }
}
