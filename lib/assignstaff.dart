import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignStaffScreen extends StatefulWidget {
  const AssignStaffScreen({super.key});

  @override
  State<AssignStaffScreen> createState() =>
      _AssignStaffScreenState();
}

class _AssignStaffScreenState
    extends State<AssignStaffScreen> {

  String? selectedCampId;
  final Set<String> selectedStaff = {};
  final Set<String> selectedStaffIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text(
          'Assign Staff',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF183769),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Select Camp',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183769),
              ),
            ),

            const SizedBox(height: 10),

            // Camps
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('camps')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final camps =
                    snapshot.data?.docs ?? [];

                if (camps.isEmpty) {
                  return const Text(
                    'No camps available.',
                  );
                }

                return DropdownButtonFormField<String>(
                  value: selectedCampId,
                  decoration: InputDecoration(
                    hintText: 'Choose a camp',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  items: camps.map((camp) {
                    final data =
                        camp.data()
                            as Map<String, dynamic>;

                    return DropdownMenuItem<String>(
                      value: camp.id,
                      child: Text(
                        data['name']?.toString() ??
                            'Unnamed Camp',
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedCampId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Select Staff',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183769),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(
                      'role',
                      isEqualTo: 'staff',
                    )
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final staff =
                      snapshot.data?.docs ?? [];

                  if (staff.isEmpty) {
                    return const Center(
                      child: Text(
                        'No staff available.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: staff.length,
                    itemBuilder: (context, index) {
                      final doc = staff[index];

                      final data =
                          doc.data()
                              as Map<String, dynamic>;

                      final name =
                          data['name']?.toString() ??
                              'Staff';

                      final role =
                          data['staffRole']
                                  ?.toString() ??
                              'Staff';

                      final isSelected =
                          selectedStaff
                              .contains(doc.id);

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: CheckboxListTile(
                          value: isSelected,

                          activeColor:
                              const Color(0xFF183769),

                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedStaff
                                    .add(doc.id);
                              } else {
                                selectedStaff
                                    .remove(doc.id);
                              }
                            });
                          },

                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(role),

                          secondary: const CircleAvatar(
                            backgroundColor:
                                Color(0xFFE8EDF5),
                            child: Icon(
                              Icons.person,
                              color:
                                  Color(0xFF183769),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _assignStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF183769),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Assign Selected Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _assignStaff() async {
  if (selectedCampId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a camp first.'),
      ),
    );
    return;
  }

  if ( selectedStaff.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select at least one staff member.'),
      ),
    );
    return;
  }

  try {
    // Get selected camp details
    final campDoc = await FirebaseFirestore.instance
        .collection('camps')
        .doc(selectedCampId)
        .get();

    if (!campDoc.exists) {
      throw Exception('Camp not found.');
    }

    final campData =
        campDoc.data() as Map<String, dynamic>;

    final String campName =
        campData['name']?.toString() ?? 'Blood Camp';

    final String location =
        campData['location']?.toString() ??
        'Location not available';

    final String date =
        campData['date']?.toString() ??
        'Date not available';

    final String time =
        campData['time']?.toString() ??
        'Time not available';

    // Assign staff + create notification
    //for (final staffId in selectedStaffIds) {
      for (final staffId in selectedStaff) {
      // Assign staff to camp
      await FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .update({
        'assignedCampId': selectedCampId,
      });

      // Create notification for staff
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'userId': staffId,
        'title': 'Camp Assignment',
        'message': 'You are assigned to this camp.',
        'campName': campName,
        'location': location,
        'date': date,
        'time': time,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Staff assigned successfully.',
        ),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to assign staff: $e',
        ),
      ),
    );
  }
}
}