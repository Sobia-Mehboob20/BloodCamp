import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'camp.dart';
import 'staff.dart';
import 'report.dart';
import 'profilescreen.dart';
import 'demo.dart';

class OrganizerHome extends StatefulWidget {
  const OrganizerHome({super.key});

  @override
  State<OrganizerHome> createState() => _OrganizerHomeState();
}

class _OrganizerHomeState extends State<OrganizerHome> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeContent(),
    CampsScreen(),
    StaffScreen(),
    ReportsScreen(),
    OrganizerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xFF1565C0),
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Camps'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ================= HOME CONTENT =================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  Future<void> _seedDemo(BuildContext context) async {
    try {
      await DemoDataService().seedDemoData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo data added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearDemo(BuildContext context) async {
    try {
      await DemoDataService().clearDemoData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo data cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hello Organizer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),



        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TodayCampCard(),

          const SizedBox(height: 20),

          const UpcomingCampCard(),

          const SizedBox(height: 25),

          // ================= DEMO DATA =================
          const Text(
            'Demo Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _seedDemo(context),
              icon: const Icon(Icons.add_circle),
              label: const Text('Seed Demo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _clearDemo(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear Demo Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ================= DATE PARSER =================

// ================= DATE PARSER =================

DateTime? parseCampDate(dynamic value) {
  if (value == null) {
    return null;
  }

  // Firebase Timestamp
  if (value is Timestamp) {
    final date = value.toDate();

    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // String date
  if (value is String) {
    try {
      // dd/MM/yyyy
      if (value.contains('/')) {
        final parts = value.split('/');

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      // yyyy-MM-dd
      if (value.contains('-')) {
        final parts = value.split('-');

        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}
 

// ================= TODAY CAMP =================

class TodayCampCard extends StatelessWidget {
  const TodayCampCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('camps').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading camp: ${snapshot.error}'),
            ),
          );
        }

        QueryDocumentSnapshot<Map<String, dynamic>>? todayCamp;

        for (final document in snapshot.data?.docs ?? []) {
          final data = document.data() as Map<String, dynamic>;

          final date = parseCampDate(data['date']);
       

          if (date != null &&
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day) {
            todayCamp = document as QueryDocumentSnapshot<Map<String, dynamic>>;
            break;
          }
        }

        if (todayCamp == null) {
          return _noCampCard(
            title: 'Today’s Camp',
            message: 'No blood camp scheduled for today.',
          );
        }

        final data = todayCamp.data();

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today’s Camp',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                Text(
                  data['name'] ?? 'Blood Camp',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF1565C0)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(data['location'] ?? 'Location not available'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF1565C0)),
                    const SizedBox(width: 5),
                    Text(
                      '${data['startTime'] ?? 'N/A'} - '
                      '${data['endTime'] ?? 'N/A'}',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Booked',
                        value: '${data['booked'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Checked-in',
                        value: '${data['checkedIn'] ?? 0}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

               Row(
  children: [
    Expanded(
      child: StatCard(
        title: 'Collected',
        value: '${data['collected'] ?? 0}',
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: StatCard(
        title: 'Deferred',
        value: '${data['deferred'] ?? 0}',
      ),
    ),
  ],
),

const SizedBox(height: 8),

Center(
 child: StatCard(
  title: 'Seats Left',
  value:
      '${((data['slotCapacity'] ?? 0) as num) - ((data['booked'] ?? 0) as num)}',
),
)
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= STAT CARD =================

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ================= UPCOMING CAMP =================

// ================= UPCOMING CAMP =================

class UpcomingCampCard extends StatelessWidget {
  const UpcomingCampCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('camps').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading upcoming camp: ${snapshot.error}',
              ),
            ),
          );
        }

        QueryDocumentSnapshot<Map<String, dynamic>>? upcomingCamp;
        DateTime? nearestDate;

        for (final document in snapshot.data?.docs ?? []) {
          final data = document.data() as Map<String, dynamic>;

          // Firebase Timestamp / String date
          final date = parseCampDate(data['date']);

          if (date == null) {
            continue;
          }

          final campDate = DateTime(
            date.year,
            date.month,
            date.day,
          );

          final today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          // Only future camps
          if (campDate.isAfter(today)) {
            if (nearestDate == null ||
                campDate.isBefore(nearestDate!)) {
              nearestDate = campDate;

              upcomingCamp =
                  document as QueryDocumentSnapshot<Map<String, dynamic>>;
            }
          }
        }

        // No upcoming camp
        if (upcomingCamp == null) {
          return _noCampCard(
            title: 'Upcoming Camp',
            message: 'No upcoming camp available.',
          );
        }

        final data = upcomingCamp.data();

        // Format date for display
        final campDate = parseCampDate(data['date']);

        String formattedDate = 'Date not available';

        if (campDate != null) {
          formattedDate =
              '${campDate.day}/${campDate.month}/${campDate.year}';
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Camp',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  data['name']?.toString() ?? 'Blood Camp',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data['location']?.toString() ??
                            'Location not available',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 5),
                    Text(formattedDate),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      data['startTime']?.toString() ??
                          'Time not available',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Slot Limit: ${data['slotCapacity'] ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= NO CAMP CARD =================

Widget _noCampCard({required String title, required String message}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.event_busy, size: 45, color: Color(0xFF1565C0)),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
