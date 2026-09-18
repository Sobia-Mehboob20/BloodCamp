import 'package:bloodcamp/createcamp.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'createcamp.dart';

class CampsScreen extends StatefulWidget {
  const CampsScreen({super.key});

  @override
  State<CampsScreen> createState() => _CampsScreenState();
}

class _CampsScreenState extends State<CampsScreen> {
  int selectedTab = 0;

  Future<void> _editCamp(String campId, Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateCampScreen(campId: campId, initialData: data, isEdit: true),
      ),
    );
  }

  Future<void> _cancelCamp(String campId, Map<String, dynamic> data) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Camp'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter cancellation reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(context, reasonController.text.trim());
                }
              },
              child: const Text('CANCEL CAMP'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      await FirebaseFirestore.instance.collection('camps').doc(campId).update({
        'isCancelled': true,
        'cancellationReason': reason,
      });

// Send notification to booked donors
final bookingsSnapshot = await FirebaseFirestore.instance
    .collection('bookings')
    .where('campId', isEqualTo: campId)
    .get();

for (final booking in bookingsSnapshot.docs) {
  final bookingData = booking.data();

  final donorId = bookingData['donorId'];

  if (donorId == null || donorId.toString().isEmpty) {
    continue;
  }

  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': donorId,
    'title': 'Camp Cancelled',
    'message':
        '${data['name']} has been cancelled. Reason: $reason',
    'type': 'camp_cancelled',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
// Send notification to assigned staff
final staffSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('role', isEqualTo: 'staff')
    .where('assignedCampId', isEqualTo: campId)
    .get();

for (final staff in staffSnapshot.docs) {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': staff.id,
    'title': 'Camp Cancelled',
    'message':
        '${data['name']} has been cancelled. Reason: $reason',
    'type': 'camp_cancelled',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camp cancelled successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  final List<String> tabs = ['Upcoming', 'Today', 'Past'];

  // Convert Firestore date into DateTime
  // Supports:
  // 12/12/2025
  // 12 Dec 2025
  // 12 dec 2025
  DateTime? parseCampDate(String dateString) {
    try {
      final cleanDate = dateString.trim();

      // Format: 12/12/2025
      if (cleanDate.contains('/')) {
        final parts = cleanDate.split('/');

        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          return DateTime(year, month, day);
        }
      }

      // Format: 12 Dec 2025
      final parts = cleanDate.split(' ');

      if (parts.length == 3) {
        final day = int.parse(parts[0]);

        final monthNames = {
          'jan': 1,
          'feb': 2,
          'mar': 3,
          'apr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'aug': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dec': 12,
        };

        final month = monthNames[parts[1].toLowerCase()];

        if (month == null) {
          return null;
        }

        final year = int.parse(parts[2]);

        return DateTime(year, month, day);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Automatically decide camp status from date
  String getCampStatus(String dateString) {
    final campDate = parseCampDate(dateString);

    if (campDate == null) {
      return 'unknown';
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final campDay = DateTime(campDate.year, campDate.month, campDate.day);

    if (campDay.isBefore(today)) {
      return 'past';
    }

    if (campDay.isAtSameMomentAs(today)) {
      return 'today';
    }

    return 'upcoming';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camps', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          // TOP TABS
          Row(
            children: [
              Expanded(child: _buildTab(0, 'Upcoming')),
              Expanded(child: _buildTab(1, 'Today')),
              Expanded(child: _buildTab(2, 'Past')),
            ],
          ),

          // CAMPS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('camps')
                  .snapshots(),

              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // No data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No camps found',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                // Get ALL camps
                final allCamps = snapshot.data!.docs;

                // Filter camps according to selected tab
                final filteredCamps = allCamps.where((camp) {
                  final data = camp.data() as Map<String, dynamic>;

                  final date = data['date'];
                  if (data['isCancelled'] == true) {
                    return false;
                  }

                  if (date == null) {
                    return false;
                  }

                  // Calculate status from DATE
                  final campStatus = getCampStatus(date.toString());

                  // Upcoming
                  if (selectedTab == 0) {
                    return campStatus == 'upcoming';
                  }

                  // Today
                  if (selectedTab == 1) {
                    return campStatus == 'today';
                  }

                  // Past
                  return campStatus == 'past';
                }).toList();

                // No camps in selected category
                if (filteredCamps.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${tabs[selectedTab].toLowerCase()} camps',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                // Display camps
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCamps.length,

                  itemBuilder: (context, index) {
                    final camp = filteredCamps[index];

                    final data = camp.data() as Map<String, dynamic>;

                    return _buildCampCard(camp.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ADD CAMP BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCampScreen()),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }

  // TAB DESIGN
  Widget _buildTab(int index, String title) {
    final bool isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 3,

              color: isSelected ? Colors.blue : Colors.transparent,
            ),
          ),
        ),

        child: Center(
          child: Text(
            title,

            style: TextStyle(
              fontSize: 16,

              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,

              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // CAMP CARD
  Widget _buildCampCard(String campId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),

      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // CAMP NAME
            Text(
              data['name'] ?? 'No Name',

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // LOCATION
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),

                const SizedBox(width: 8),

                Expanded(child: Text(data['location'] ?? 'No Location')),
              ],
            ),

            const SizedBox(height: 8),

            // DATE
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),

                const SizedBox(width: 8),

                Text(data['date'] ?? 'No Date'),
              ],
            ),

            const SizedBox(height: 8),

            // START TIME
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),

                const SizedBox(width: 8),

                Text(data['startTime'] ?? 'No Start Time'),
              ],
            ),

            const SizedBox(height: 8),

            // END TIME
            if (data['endTime'] != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),

                  const SizedBox(width: 8),

                  Text('Ends: ${data['endTime']}'),
                ],
              ),

            const SizedBox(height: 12),

            // SLOT CAPACITY
            if (data['slotCapacity'] != null)
              Text(
                'Slot Capacity: ${data['slotCapacity']}',

                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

            const SizedBox(height: 8),

            // BLOOD GROUPS
            if (data['bloodGroupsNeeded'] != null)
              Text(
                'Blood Groups: ${_formatBloodGroups(data['bloodGroupsNeeded'])}',

                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

            const SizedBox(height: 12),

            Visibility(
              visible: getCampStatus(data['date']) != 'past',

              child: Column(
                children: [
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _editCamp(campId, data);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Camp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _cancelCamp(campId, data);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Camp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FORMAT BLOOD GROUP LIST
  String _formatBloodGroups(dynamic bloodGroups) {
    if (bloodGroups is List) {
      return bloodGroups.join(', ');
    }

    return bloodGroups.toString();
  }
}
