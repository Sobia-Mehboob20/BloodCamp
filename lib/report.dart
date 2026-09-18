import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;

  int campsThisMonth = 0;
  int unitsCollected = 0;
  double noShowPercentage = 0;

  Map<String, int> topBloodGroups = {};

  @override
  void initState() {
    super.initState();
    loadMonthlyReport();
  }

  // ============================================================
  // MONTHLY REPORT
  // ============================================================

  Future<void> loadMonthlyReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();

      // First day of current month
      final startOfMonth = DateTime(
        now.year,
        now.month,
        1,
      );

      // First day of next month
      final startOfNextMonth = DateTime(
        now.year,
        now.month + 1,
        1,
      );

      final startTimestamp =
          Timestamp.fromDate(startOfMonth);

      final endTimestamp =
          Timestamp.fromDate(startOfNextMonth);

      // ========================================================
      // 1. CAMPS THIS MONTH
      // ========================================================

      final campSnapshot = await FirebaseFirestore.instance
          .collection('camps')
          .where(
            'date',
            isGreaterThanOrEqualTo: startTimestamp,
          )
          .where(
            'date',
            isLessThan: endTimestamp,
          )
          .get();

      // ========================================================
      // 2. BOOKINGS THIS MONTH
      // ========================================================

      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'date',
            isGreaterThanOrEqualTo: startTimestamp,
          )
          .where(
            'date',
            isLessThan: endTimestamp,
          )
          .get();

      // ========================================================
      // 3. DONATIONS THIS MONTH
      // ========================================================

      final donationSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where(
            'date',
            isGreaterThanOrEqualTo: startTimestamp,
          )
          .where(
            'date',
            isLessThan: endTimestamp,
          )
          .get();

      // ========================================================
      // COUNT BOOKINGS + NO SHOWS
      // ========================================================

      int totalBookings = bookingSnapshot.docs.length;
      int noShows = 0;

      for (var doc in bookingSnapshot.docs) {
        final data = doc.data();

        if (data['status'] == 'noShow') {
          noShows++;
        }
      }

      // ========================================================
      // NO-SHOW PERCENTAGE
      // ========================================================

      double noShowRate = 0;

      if (totalBookings > 0) {
        noShowRate =
            (noShows / totalBookings) * 100;
      }

      // ========================================================
      // COUNT DONATIONS + BLOOD GROUPS
      // ========================================================

      int totalUnits = 0;

      Map<String, int> bloodGroups = {};

      for (var doc in donationSnapshot.docs) {
        final data = doc.data();

        // Every donation record = 1 unit
        totalUnits++;

        final bloodGroup = data['bloodGroup'];

        if (bloodGroup != null &&
            bloodGroup.toString().isNotEmpty) {
          final group = bloodGroup.toString();

          bloodGroups[group] =
              (bloodGroups[group] ?? 0) + 1;
        }
      }

      // ========================================================
      // SORT BLOOD GROUPS
      // ========================================================

      final sortedGroups = bloodGroups.entries.toList()
        ..sort(
          (a, b) => b.value.compareTo(a.value),
        );

      // Only top 3
      final topThreeGroups =
          Map<String, int>.fromEntries(
        sortedGroups.take(3),
      );

      // ========================================================
      // UPDATE SCREEN
      // ========================================================

      if (!mounted) return;

      setState(() {
        campsThisMonth = campSnapshot.docs.length;

        unitsCollected = totalUnits;

        noShowPercentage = noShowRate;

        topBloodGroups = topThreeGroups;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load report: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REPORT CARD
  // ============================================================

  Widget reportCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: Icon(
                icon,
                size: 28,
                  color: const Color(0xFF1565C0),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
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

  // ============================================================
  // TOP BLOOD GROUPS
  // ============================================================

  Widget topBloodGroupsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
               const Icon(
  Icons.bloodtype,
  color: Color.fromARGB(255, 197, 9, 9),
),
                

                SizedBox(width: 10),

                Text(
                  'Top Blood Groups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (topBloodGroups.isEmpty)
              const Text(
                'No donation data this month.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

            ...topBloodGroups.entries.map(
              (entry) {
                return Container(
                  margin:
                      const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '${entry.value} units',
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final currentMonth =
        months[now.month - 1];

    return Scaffold(
    appBar: AppBar(
  title: const Text(
    'Reports',
    style: TextStyle(
      color: Colors.white,
    ),
  ),
  centerTitle: true,
  backgroundColor: const Color(0xFF1565C0),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadMonthlyReport,

              child: ListView(
                padding: const EdgeInsets.all(16),

                children: [
                  // ==================================================
                  // MONTHLY REPORT HEADING
                  // ==================================================

                  const Text(
                    'Monthly Report',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$currentMonth ${now.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // CAMPS
                  // ==================================================

                  reportCard(
                    title: 'Camps This Month',
                    value: campsThisMonth.toString(),
                    icon: Icons.event,
                  ),

                  // ==================================================
                  // UNITS
                  // ==================================================

                  reportCard(
                    title: 'Units Collected',
                    value: unitsCollected.toString(),
                    icon: Icons.bloodtype,
                  ),

                  // ==================================================
                  // NO SHOW
                  // ==================================================

                  reportCard(
                    title: 'No-show Rate',
                    value:
                        '${noShowPercentage.toStringAsFixed(1)}%',
                    icon: Icons.person_off,
                  ),

                  // ==================================================
                  // TOP BLOOD GROUPS
                  // ==================================================

                  topBloodGroupsCard(),
                ],
              ),
            ),
    );
  }
}