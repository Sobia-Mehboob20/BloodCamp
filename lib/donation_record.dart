import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_records_firestore.dart';

class DonationRecordScreen extends StatefulWidget {
  const DonationRecordScreen({super.key});

  @override
  State<DonationRecordScreen> createState() => _DonationRecordScreenState();
}

class _DonationRecordScreenState extends State<DonationRecordScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const String campId = 'camp 7';

  List<Map<String, dynamic>> donors = [];

  Map<String, dynamic>? selectedDonor;

  final TextEditingController bagNumberController = TextEditingController();

  final TextEditingController notesController = TextEditingController();

  String donationType = 'Whole Blood';

  String donationStatus = 'Completed';

  bool isSaving = false;
  bool isLoadingDonors = true;

  @override
  void initState() {
    super.initState();
    loadDonors();
  }

  @override
  void dispose() {
    bagNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD REAL DONORS
  // ==========================================================

  Future<void> loadDonors() async {
    setState(() {
      isLoadingDonors = true;
    });

    try {
      final List<Map<String, dynamic>> loadedDonors = [];

      // ========================================================
      // 1. LOAD SCREENING RECORDS FOR CAMP 7
      // ========================================================

      final screeningSnapshot = await firestore
          .collection('screenings')
          .where('campId', isEqualTo: campId)
          .get();

      // ========================================================
      // 2. LOAD BOOKINGS FOR CAMP 7
      // ========================================================

      final bookingSnapshot = await firestore
          .collection('bookings')
          .where('campId', isEqualTo: campId)
          .get();

      // Make a quick map of booking documents.
      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
      bookingMap = {};

      for (final doc in bookingSnapshot.docs) {
        bookingMap[doc.id] = doc;
      }

      // ========================================================
      // 3. PROCESS SCREENED DONORS
      // ========================================================

      for (final screeningDoc in screeningSnapshot.docs) {
        final screeningData = screeningDoc.data();

        final String screeningStatus =
            screeningData['screeningStatus']?.toString().trim().toLowerCase() ??
            '';

        // Only donors who passed screening can donate.
        final bool passed =
            screeningStatus == 'passed' ||
            screeningStatus == 'screening passed';

        if (!passed) {
          continue;
        }

        // ------------------------------------------------------
        // Find booking ID from screening record
        // ------------------------------------------------------

        final String bookingId = screeningData['bookingId']?.toString() ?? '';

        QueryDocumentSnapshot<Map<String, dynamic>>? bookingDoc;

        if (bookingId.isNotEmpty) {
          bookingDoc = bookingMap[bookingId];
        }

        // ------------------------------------------------------
        // Get donor ID
        // ------------------------------------------------------

        String donorId = screeningData['donorId']?.toString() ?? '';

        if (donorId.isEmpty && bookingDoc != null) {
          donorId = bookingDoc.data()['donorId']?.toString() ?? '';
        }

        // ------------------------------------------------------
        // Get donor information
        // ------------------------------------------------------

        String donorName = screeningData['donorName']?.toString() ?? '';

        String phone = screeningData['donorPhone']?.toString() ?? '';

        String bloodGroup = screeningData['bloodGroup']?.toString() ?? '';

        String slot = '';

        // If information is missing from screening,
        // get it from booking.
        if (bookingDoc != null) {
          final bookingData = bookingDoc.data();

          if (donorName.isEmpty) {
            donorName = bookingData['donorName']?.toString() ?? 'Unknown Donor';
          }

          if (phone.isEmpty) {
            phone = bookingData['donorPhone']?.toString() ?? '';
          }

          if (bloodGroup.isEmpty) {
            bloodGroup = bookingData['bloodGroup']?.toString() ?? '';
          }

          slot = bookingData['slot']?.toString() ?? '';
        }

        if (donorName.isEmpty) {
          donorName = 'Unknown Donor';
        }

        // ------------------------------------------------------
        // Add donor to donation list
        // ------------------------------------------------------

        loadedDonors.add({
          'name': donorName,
          'phone': phone,
          'bloodGroup': bloodGroup,

          'screeningStatus':
              screeningData['screeningStatus']?.toString() ??
              'Screening Passed',

          'slot': slot,

          'donorId': donorId,

          'bookingId': bookingId,

          'campId': campId,

          'staffId': screeningData['staffId']?.toString() ?? 'staff001',

          'type': 'booking',

          'screeningId': screeningDoc.id,
        });
      }

      // ========================================================
      // 4. LOAD WALK-IN DONORS
      // ========================================================

      final walkInSnapshot = await firestore
          .collection('walk_in_donors')
          .where('campId', isEqualTo: campId)
          .get();

      for (final doc in walkInSnapshot.docs) {
        final data = doc.data();

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        final bool eligible =
            status == 'confirmed' ||
            status == 'checked in' ||
            status == 'checked_in' ||
            status == 'screening' ||
            status == 'screening passed' ||
            status == 'passed';

        if (!eligible) {
          continue;
        }

        loadedDonors.add({
          'name': data['donorName']?.toString() ?? 'Walk-in Donor',

          'phone': data['phone']?.toString() ?? '',

          'bloodGroup': data['bloodGroup']?.toString() ?? '',

          'screeningStatus': data['screeningStatus']?.toString() ?? status,

          'slot': 'Walk-in',

          'donorId': data['donorId']?.toString() ?? '',

          'bookingId': data['bookingId']?.toString() ?? '',

          'campId': campId,

          'staffId': data['registeredByStaff']?.toString() ?? 'staff001',

          'type': 'walkin',

          'walkInDocumentId': doc.id,
        });
      }

      // ========================================================
      // 5. UPDATE SCREEN
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        donors = loadedDonors;
        isLoadingDonors = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingDonors = false;
      });

      showMessage('Unable to load donors.\n$e', isError: true);
    }
  }
  // ==========================================================
  // SAVE DONATION
  // ==========================================================

  Future<void> saveDonation() async {
    if (selectedDonor == null) {
      showMessage('Please select a donor.', isError: true);
      return;
    }

    if (bagNumberController.text.trim().isEmpty) {
      showMessage('Please enter the bag / unit number.', isError: true);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String donorId = selectedDonor!['donorId']?.toString() ?? '';

      final String bookingId = selectedDonor!['bookingId']?.toString() ?? '';

      // Firestore Camp 7 document ID
      const String currentCampId = 'camp7';

      final String staffId =
          selectedDonor!['staffId']?.toString() ?? 'staff001';

      // --------------------------------------------------------
      // 1. SAVE DONATION RECORD
      // --------------------------------------------------------

      await DonationRecordsFirestore.addDonation(
        donorId: donorId,
        bookingId: bookingId,
        campId: currentCampId,
        bloodGroup: selectedDonor!['bloodGroup']?.toString() ?? '',
        bagNumber: bagNumberController.text.trim(),
        donationStatus: donationStatus,
        staffId: staffId,
        notes: notesController.text.trim(),
      );

      // --------------------------------------------------------
      // 2. BOOKED DONOR
      // --------------------------------------------------------

      if (bookingId.isNotEmpty && selectedDonor!['type'] == 'booking') {
        if (donationStatus == 'Completed') {
          // Mark booking as completed and save completion time
          await firestore.collection('bookings').doc(bookingId).update({
            'status': 'Completed',
            'donationStatus': 'Completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

          // ----------------------------------------------------
          // 3. CREATE DONATION NOTIFICATION
          // ----------------------------------------------------

          if (donorId.isNotEmpty) {
            await firestore.collection('notifications').add({
              'userId': donorId,
              'title': 'Donation Completed',
              'message':
                  'Thank you for donating blood. Your donation has been successfully completed.',
              'type': 'donation',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
              'bookingId': bookingId,
              'campId': currentCampId,
            });
          }
        } else {
          // Donation was not completed
          await firestore.collection('bookings').doc(bookingId).update({
            'status': 'Screening Passed',
            'donationStatus': 'Not Completed',
          });
        }
      }

      // --------------------------------------------------------
      // 4. WALK-IN DONOR
      // --------------------------------------------------------

      if (selectedDonor!['type'] == 'walkin' &&
          selectedDonor!['walkInDocumentId'] != null) {
        await firestore
            .collection('walk_in_donors')
            .doc(selectedDonor!['walkInDocumentId'])
            .update({
              'status': donationStatus == 'Completed'
                  ? 'Completed'
                  : 'Screening Passed',
              if (donationStatus == 'Completed')
                'completedAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      // --------------------------------------------------------
      // 5. SHOW SUCCESS DIALOG
      // --------------------------------------------------------

      showSuccessDialog(
        donorId: donorId,
        bookingId: bookingId,
        campId: currentCampId,
        staffId: staffId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Failed to save donation record.\n$e', isError: true);
    }
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void showSuccessDialog({
    required String donorId,
    required String bookingId,
    required String campId,
    required String staffId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Donation Recorded'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donation record has been successfully saved to Firebase.',
                ),

                const SizedBox(height: 16),

                Text('Donor ID: $donorId'),

                Text('Booking ID: $bookingId'),

                Text('Camp ID: $campId'),

                Text(
                  'Blood Group: '
                  '${selectedDonor!['bloodGroup']}',
                ),

                Text(
                  'Bag / Unit Number: '
                  '${bagNumberController.text.trim()}',
                ),

                Text(
                  'Donation Status: '
                  '$donationStatus',
                ),

                Text('Staff ID: $staffId'),

                Text(
                  'Donation Type: '
                  '$donationType',
                ),

                if (notesController.text.trim().isNotEmpty)
                  Text(
                    'Notes: '
                    '${notesController.text.trim()}',
                  ),

                const SizedBox(height: 12),

                const Text(
                  'Donation Date & Time: Saved automatically',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, 'Donation Recorded');
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Record'),
        backgroundColor: const Color(0xFF064D8C),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Select Donor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (isLoadingDonors)
              const Center(child: CircularProgressIndicator())
            else if (donors.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No screened donors are available for Camp 7.',
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedDonor,

                decoration: InputDecoration(
                  labelText: 'Donor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),

                items: donors.map((donor) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: donor,
                    child: Text(
                      '${donor['name']} '
                      '(${donor['bloodGroup']})',
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedDonor = value;
                  });
                },
              ),

            const SizedBox(height: 20),

            if (selectedDonor != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donor Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Name: '
                      '${selectedDonor!['name']}',
                    ),

                    Text(
                      'Phone: '
                      '${selectedDonor!['phone']}',
                    ),

                    Text(
                      'Blood Group: '
                      '${selectedDonor!['bloodGroup']}',
                    ),

                    Text(
                      'Donor ID: '
                      '${selectedDonor!['donorId']}',
                    ),

                    Text(
                      'Booking ID: '
                      '${selectedDonor!['bookingId']}',
                    ),

                    Text(
                      'Camp ID: '
                      '${selectedDonor!['campId']}',
                    ),

                    Text(
                      'Staff ID: '
                      '${selectedDonor!['staffId']}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],

            const Text(
              'Donation Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: bagNumberController,
              decoration: InputDecoration(
                labelText: 'Bag / Unit Number',
                hintText: 'e.g. BAG-001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.bloodtype),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedDonor?['bloodGroup']?.toString(),
              decoration: InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.water_drop),
              ),
              items: const [
                DropdownMenuItem(value: 'A+', child: Text('A+')),
                DropdownMenuItem(value: 'A-', child: Text('A-')),
                DropdownMenuItem(value: 'B+', child: Text('B+')),
                DropdownMenuItem(value: 'B-', child: Text('B-')),
                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                DropdownMenuItem(value: 'O+', child: Text('O+')),
                DropdownMenuItem(value: 'O-', child: Text('O-')),
              ],
              onChanged: (value) {
                if (selectedDonor != null && value != null) {
                  setState(() {
                    selectedDonor!['bloodGroup'] = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: donationType,
              decoration: InputDecoration(
                labelText: 'Donation Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Whole Blood',
                  child: Text('Whole Blood'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    donationType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: donationStatus,
              decoration: InputDecoration(
                labelText: 'Donation Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                DropdownMenuItem(
                  value: 'Not Completed',
                  child: Text('Not Completed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    donationStatus = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter donation notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving || donors.isEmpty ? null : saveDonation,

                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),

                label: Text(isSaving ? 'Saving...' : 'Save Donation Record'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
