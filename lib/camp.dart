import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'createcamp.dart';
import 'organizerHome.dart';

class CampsScreen extends StatefulWidget {
  const CampsScreen({super.key});

  @override
  State<CampsScreen> createState() => _CampsScreenState();
}

class _CampsScreenState extends State<CampsScreen> {
  int selectedTab = 0;

  final List<String> tabs = [
    'Upcoming',
    'Today',
    'Past',
  ];

  // --------------------------------------------------
  // EDIT CAMP
  // --------------------------------------------------
  Future<void> _editCamp(
    String campId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCampScreen(
          campId: campId,
          initialData: data,
          isEdit: true,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CANCEL CAMP
  // --------------------------------------------------
  Future<void> _cancelCamp(
    String campId,
    Map<String, dynamic> data,
  ) async {
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
                  Navigator.pop(
                    context,
                    reasonController.text.trim(),
                  );
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
      // --------------------------------------------------
      // MARK CAMP AS CANCELLED
      // --------------------------------------------------
      await FirebaseFirestore.instance
          .collection('camps')
          .doc(campId)
          .update({
        'isCancelled': true,
        'cancellationReason': reason,
      });

      // --------------------------------------------------
      // NOTIFICATION TO BOOKED DONORS
      // --------------------------------------------------
      final bookingsSnapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where(
                'campId',
                isEqualTo: campId,
              )
              .get();

      for (final booking in bookingsSnapshot.docs) {
        final bookingData = booking.data();

        final donorId = bookingData['donorId'];

        if (donorId == null ||
            donorId.toString().isEmpty) {
          continue;
        }

        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'userId': donorId,
          'title': 'Camp Cancelled',
          'message':
              '${data['name']} has been cancelled. Reason: $reason',
          'type': 'camp_cancelled',
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      // --------------------------------------------------
      // NOTIFICATION TO ASSIGNED STAFF
      // --------------------------------------------------
      final staffSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'role',
                isEqualTo: 'staff',
              )
              .where(
                'assignedCampId',
                isEqualTo: campId,
              )
              .get();

      for (final staff in staffSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'userId': staff.id,
          'title': 'Camp Cancelled',
          'message':
              '${data['name']} has been cancelled. Reason: $reason',
          'type': 'camp_cancelled',
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camp cancelled successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // --------------------------------------------------
  // CONVERT FIRESTORE DATE TO DATETIME
  // --------------------------------------------------
  DateTime? parseCampDate(dynamic date) {
    try {
      // Firestore Timestamp
      if (date is Timestamp) {
        return date.toDate();
      }

      // DateTime
      if (date is DateTime) {
        return date;
      }

      // Old String dates
      if (date is String) {
        // Format: 25/9/2026
        final parts = date.split('/');

        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }

        return DateTime.tryParse(date);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // --------------------------------------------------
  // GET CAMP STATUS
  // --------------------------------------------------
  String getCampStatus(dynamic date) {
    final campDate = parseCampDate(date);

    if (campDate == null) {
      return 'unknown';
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final campDay = DateTime(
      campDate.year,
      campDate.month,
      campDate.day,
    );

    if (campDay.isBefore(today)) {
      return 'past';
    }

    if (campDay.isAtSameMomentAs(today)) {
      return 'today';
    }

    return 'upcoming';
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --------------------------------------------------
      // APP BAR
      // --------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'Camps',
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        centerTitle: true,

        backgroundColor:
            const Color(0xFF1565C0),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const OrganizerHome(),
              ),
            );
          },
        ),
      ),

      // --------------------------------------------------
      // BODY
      // --------------------------------------------------
      body: Column(
        children: [
          // --------------------------------------------------
          // TABS
          // --------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _buildTab(
                  0,
                  'Upcoming',
                ),
              ),

              Expanded(
                child: _buildTab(
                  1,
                  'Today',
                ),
              ),

              Expanded(
                child: _buildTab(
                  2,
                  'Past',
                ),
              ),
            ],
          ),

          // --------------------------------------------------
          // CAMPS LIST
          // --------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('camps')
                  .snapshots(),

              builder: (context, snapshot) {
                // LOADING
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                // ERROR
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                    ),
                  );
                }

                // NO DATA
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No camps found',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                // ALL CAMPS
                final allCamps =
                    snapshot.data!.docs;

                // FILTER CAMPS
                final filteredCamps =
                    allCamps.where((camp) {
                  final data =
                      camp.data()
                          as Map<String, dynamic>;

                  final date = data['date'];

                  // Hide cancelled camps
                  if (data['isCancelled'] ==
                      true) {
                    return false;
                  }

                  // Skip camp without date
                  if (date == null) {
                    return false;
                  }

                  final campStatus =
                      getCampStatus(date);

                  // UPCOMING
                  if (selectedTab == 0) {
                    return campStatus ==
                        'upcoming';
                  }

                  // TODAY
                  if (selectedTab == 1) {
                    return campStatus ==
                        'today';
                  }

                  // PAST
                  return campStatus == 'past';
                }).toList();

                // NO CAMPS IN TAB
                if (filteredCamps.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${tabs[selectedTab].toLowerCase()} camps',
                      style:
                          const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                // DISPLAY CAMPS
                return ListView.builder(
                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      filteredCamps.length,

                  itemBuilder:
                      (context, index) {
                    final camp =
                        filteredCamps[index];

                    final data =
                        camp.data()
                            as Map<String, dynamic>;

                    return _buildCampCard(
                      camp.id,
                      data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // --------------------------------------------------
      // ADD CAMP BUTTON
      // --------------------------------------------------
      floatingActionButton:
          FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const CreateCampScreen(),
            ),
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }

  // --------------------------------------------------
  // TAB DESIGN
  // --------------------------------------------------
  Widget _buildTab(
    int index,
    String title,
  ) {
    final bool isSelected =
        selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 16,
        ),

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 3,

              color: isSelected
                  ? Colors.blue
                  : Colors.transparent,
            ),
          ),
        ),

        child: Center(
          child: Text(
            title,

            style: TextStyle(
              fontSize: 16,

              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,

              color: isSelected
                  ? Colors.blue
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CAMP CARD
  // --------------------------------------------------
  Widget _buildCampCard(
    String campId,
    Map<String, dynamic> data,
  ) {
    // Convert date
    final campDate =
        parseCampDate(data['date']);

    String displayDate = 'No Date';

    if (campDate != null) {
      displayDate =
          '${campDate.day}/'
          '${campDate.month}/'
          '${campDate.year}';
    }

    // Support both field names
    final bloodGroups =
        data['bloodGroupNeeded'] ??
        data['bloodGroupsNeeded'];

    return Card(
      margin:
          const EdgeInsets.only(bottom: 14),

      elevation: 2,

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // CAMP NAME
            // --------------------------------------------------
            Text(
              data['name']?.toString() ??
                  'No Name',

              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // LOCATION
            // --------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    data['location']
                            ?.toString() ??
                        'No Location',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(displayDate),
              ],
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // START TIME
            // --------------------------------------------------
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  data['startTime']
                          ?.toString() ??
                      'No Start Time',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // END TIME
            // --------------------------------------------------
            if (data['endTime'] != null)
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Ends: ${data['endTime']}',
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // SLOT CAPACITY
            // --------------------------------------------------
            if (data['slotCapacity'] !=
                null)
              Text(
                'Slot Capacity: ${data['slotCapacity']}',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // BLOOD GROUPS
            // --------------------------------------------------
            if (bloodGroups != null)
              Text(
                'Blood Groups: ${_formatBloodGroups(bloodGroups)}',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // EDIT + CANCEL
            // --------------------------------------------------
            Visibility(
              visible:
                  getCampStatus(
                    data['date'],
                  ) !=
                      'past',

              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),

                  // EDIT BUTTON
                  SizedBox(
                    width: double.infinity,

                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        _editCamp(
                          campId,
                          data,
                        );
                      },

                      icon: const Icon(
                        Icons.edit,
                      ),

                      label: const Text(
                        'Edit Camp',
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xFF1565C0,
                        ),

                        side:
                            const BorderSide(
                          color: Color(
                            0xFF1565C0,
                          ),
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // CANCEL BUTTON
                  SizedBox(
                    width: double.infinity,

                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        _cancelCamp(
                          campId,
                          data,
                        );
                      },

                      icon: const Icon(
                        Icons.cancel,
                      ),

                      label: const Text(
                        'Cancel Camp',
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.red,

                        side:
                            const BorderSide(
                          color: Colors.red,
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 12,
                        ),
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

  // --------------------------------------------------
  // FORMAT BLOOD GROUPS
  // --------------------------------------------------
  String _formatBloodGroups(
    dynamic bloodGroups,
  ) {
    if (bloodGroups is List) {
      return bloodGroups.join(', ');
    }

    return bloodGroups.toString();
  }
}