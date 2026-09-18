import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_shifts_firestore.dart';

class EndOfShiftScreen extends StatefulWidget {
  const EndOfShiftScreen({super.key});

  @override
  State<EndOfShiftScreen> createState() => _EndOfShiftScreenState();
}

class _EndOfShiftScreenState extends State<EndOfShiftScreen> {
  final TextEditingController notesController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String campId = 'camp001';
  final String staffId = 'staff001';

  bool isLoading = true;
  bool isEndingShift = false;

  int registeredDonors = 0;
  int checkedInDonors = 0;
  int completedDonations = 0;
  int deferredDonors = 0;
  int walkInDonors = 0;
  int pendingScreenings = 0;
  int pendingDonationRecords = 0;

  final Map<String, int> bloodGroupCounts = {
    'A+': 0,
    'A-': 0,
    'B+': 0,
    'B-': 0,
    'O+': 0,
    'O-': 0,
    'AB+': 0,
    'AB-': 0,
  };

  @override
  void initState() {
    super.initState();
    loadShiftSummary();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD REAL SHIFT DATA FROM FIREBASE
  // ============================================================

  Future<void> loadShiftSummary() async {
    setState(() {
      isLoading = true;
    });

    try {
      // BOOKINGS
      final bookingsSnapshot = await firestore
          .collection('bookings')
          .where('campId', isEqualTo: campId)
          .get();

      // WALK-IN DONORS
      final walkInSnapshot = await firestore
          .collection('walk_in_donors')
          .where('campId', isEqualTo: campId)
          .get();

      // SCREENINGS
      final screeningsSnapshot = await firestore
          .collection('screenings')
          .where('campId', isEqualTo: campId)
          .get();

      // DONATIONS
      final donationsSnapshot = await firestore
          .collection('donations')
          .where('campId', isEqualTo: campId)
          .get();

      // ==========================================================
      // REGISTERED DONORS
      // BOOKINGS + WALK-INS
      // ==========================================================

      registeredDonors =
          bookingsSnapshot.docs.length + walkInSnapshot.docs.length;

      walkInDonors = walkInSnapshot.docs.length;

      // ==========================================================
      // CHECKED-IN DONORS
      // ==========================================================

      checkedInDonors = 0;

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';

        if (status.contains('checked in') ||
            status.contains('screening') ||
            status.contains('passed') ||
            status.contains('deferred')) {
          checkedInDonors++;
        }
      }

      for (final doc in walkInSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';

        if (status.contains('checked in') ||
            status.contains('screening') ||
            status.contains('passed') ||
            status.contains('deferred')) {
          checkedInDonors++;
        }
      }

      // ==========================================================
      // SCREENING COUNTS
      // ==========================================================

      deferredDonors = 0;

      final Set<String> screenedDonorIds = {};
      final Set<String> passedDonorIds = {};

      for (final doc in screeningsSnapshot.docs) {
        final data = doc.data();

        final donorId = data['donorId']?.toString();

        if (donorId != null && donorId.isNotEmpty) {
          screenedDonorIds.add(donorId);
        }

        final screeningStatus =
            data['screeningStatus']?.toString().toLowerCase() ?? '';

        if (screeningStatus == 'deferred') {
          deferredDonors++;
        }

        if (screeningStatus == 'passed' &&
            donorId != null &&
            donorId.isNotEmpty) {
          passedDonorIds.add(donorId);
        }
      }

      // ==========================================================
      // COMPLETED DONATIONS + BLOOD GROUP COUNTS
      // ==========================================================

      completedDonations = 0;

      final Set<String> donationDonorIds = {};

      for (final key in bloodGroupCounts.keys) {
        bloodGroupCounts[key] = 0;
      }

      for (final doc in donationsSnapshot.docs) {
        final data = doc.data();

        final donationStatus =
            data['donationStatus']?.toString().toLowerCase() ?? '';

        if (donationStatus == 'completed') {
          completedDonations++;

          final donorId = data['donorId']?.toString();

          if (donorId != null && donorId.isNotEmpty) {
            donationDonorIds.add(donorId);
          }

          final bloodGroup = data['bloodGroup']?.toString();

          if (bloodGroup != null &&
              bloodGroupCounts.containsKey(bloodGroup)) {
            bloodGroupCounts[bloodGroup] =
                bloodGroupCounts[bloodGroup]! + 1;
          }
        }
      }

      // ==========================================================
      // PENDING SCREENINGS
      // ==========================================================

      pendingScreenings = 0;

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDonors = [
        ...bookingsSnapshot.docs,
        ...walkInSnapshot.docs,
      ];

      for (final donor in allDonors) {
        final data = donor.data();

        String? donorId;

        if (data['donorId'] != null) {
          donorId = data['donorId'].toString();
        } else {
          donorId = donor.id;
        }

        final status = data['status']?.toString().toLowerCase() ?? '';

        final isCheckedIn = status.contains('checked in') ||
            status.contains('screening') ||
            status.contains('passed') ||
            status.contains('deferred');

        if (isCheckedIn && !screenedDonorIds.contains(donorId)) {
          pendingScreenings++;
        }
      }

      // ==========================================================
      // PENDING DONATION RECORDS
      // ==========================================================

      pendingDonationRecords = 0;

      for (final donorId in passedDonorIds) {
        if (!donationDonorIds.contains(donorId)) {
          pendingDonationRecords++;
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load shift summary: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // END SHIFT CONFIRMATION
  // ============================================================

  void endShift() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'End Shift',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to end your shift?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isEndingShift
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await saveShift();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E2B),
                foregroundColor: Colors.white,
              ),
              child: const Text('End Shift'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SAVE SHIFT USING FIREBASE HELPER
  // ============================================================

  Future<void> saveShift() async {
    setState(() {
      isEndingShift = true;
    });

    try {
      await StaffShiftsFirestore.addShift(
        staffId: staffId,
        campId: campId,
        registeredDonors: registeredDonors,
        checkedInDonors: checkedInDonors,
        completedDonations: completedDonations,
        deferredDonors: deferredDonors,
        walkInDonors: walkInDonors,
        pendingScreenings: pendingScreenings,
        pendingDonationRecords: pendingDonationRecords,
        staffNotes: notesController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isEndingShift = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (successContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 55,
            ),
            title: const Text(
              'Shift Completed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Your end-of-shift report has been saved successfully.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(successContext);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0867B2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isEndingShift = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save shift: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0867B2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'End of Shift',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadShiftSummary,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0867B2),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadShiftSummary,
              color: const Color(0xFF0867B2),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // =====================================================
                    // TODAY'S CAMP SUMMARY
                    // =====================================================

                    const Text(
                      "Today's Camp Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.people,
                            title: 'Registered',
                            value: registeredDonors.toString(),
                            color: const Color(0xFF0867B2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.how_to_reg,
                            title: 'Checked In',
                            value: checkedInDonors.toString(),
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.bloodtype,
                            title: 'Completed',
                            value: completedDonations.toString(),
                            color: const Color(0xFFE91E2B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.warning_amber_rounded,
                            title: 'Deferred',
                            value: deferredDonors.toString(),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _wideSummaryCard(
                      icon: Icons.person_add_alt_1,
                      title: 'Walk-in Donors',
                      value: walkInDonors.toString(),
                      color: const Color(0xFF064D8C),
                    ),

                    const SizedBox(height: 25),

                    // =====================================================
                    // DONATION SUMMARY
                    // =====================================================

                    const Text(
                      'Donation Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _bloodGroupRow(
                            'A+',
                            bloodGroupCounts['A+'].toString(),
                          ),
                          _bloodGroupRow(
                            'A-',
                            bloodGroupCounts['A-'].toString(),
                          ),
                          _bloodGroupRow(
                            'B+',
                            bloodGroupCounts['B+'].toString(),
                          ),
                          _bloodGroupRow(
                            'B-',
                            bloodGroupCounts['B-'].toString(),
                          ),
                          _bloodGroupRow(
                            'O+',
                            bloodGroupCounts['O+'].toString(),
                          ),
                          _bloodGroupRow(
                            'O-',
                            bloodGroupCounts['O-'].toString(),
                          ),
                          _bloodGroupRow(
                            'AB+',
                            bloodGroupCounts['AB+'].toString(),
                          ),
                          _bloodGroupRow(
                            'AB-',
                            bloodGroupCounts['AB-'].toString(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =====================================================
                    // PENDING TASKS
                    // =====================================================

                    const Text(
                      'Pending Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _pendingTask(
                      Icons.people_outline,
                      'Remaining Donors',
                      '${(registeredDonors - checkedInDonors).clamp(0, registeredDonors)} donors',
                    ),

                    const SizedBox(height: 10),

                    _pendingTask(
                      Icons.assignment_outlined,
                      'Uncompleted Screenings',
                      '$pendingScreenings screening${pendingScreenings == 1 ? '' : 's'}',
                    ),

                    const SizedBox(height: 10),

                    _pendingTask(
                      Icons.bloodtype_outlined,
                      'Pending Donation Records',
                      '$pendingDonationRecords record${pendingDonationRecords == 1 ? '' : 's'}',
                    ),

                    const SizedBox(height: 25),

                    // =====================================================
                    // STAFF NOTES
                    // =====================================================

                    const Text(
                      'Staff Notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17324D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Enter any end-of-shift remarks...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 8,
                            bottom: 70,
                           ),
                          child: Icon(Icons.notes_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =====================================================
                    // END SHIFT BUTTON
                    // =====================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isEndingShift ? null : endShift,
                        icon: isEndingShift
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                              ),
                        label: Text(
                          isEndingShift
                              ? 'Saving Shift...'
                              : 'End Shift',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE91E2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17324D),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDE SUMMARY CARD
  // ============================================================

  Widget _wideSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17324D),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BLOOD GROUP ROW
  // ============================================================

  Widget _bloodGroupRow(String group, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              group,
              style: const TextStyle(
                color: Color(0xFFE91E2B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Donations',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17324D),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING TASK
  // ============================================================

  Widget _pendingTask(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF17324D),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
} 