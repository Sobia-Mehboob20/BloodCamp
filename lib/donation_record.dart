import 'package:flutter/material.dart';
import 'donation_records_firestore.dart';

class DonationRecordScreen extends StatefulWidget {
  const DonationRecordScreen({super.key});

  @override
  State<DonationRecordScreen> createState() => _DonationRecordScreenState();
}

class _DonationRecordScreenState extends State<DonationRecordScreen> {
  // Demo screened-passed donors
  final List<Map<String, dynamic>> donors = [
    {
      'name': 'Fatima Ahmed',
      'phone': '03221234567',
      'bloodGroup': 'O+',
      'screeningStatus': 'Screening Passed',
      'slot': '10:00 AM',
      'donorId': 'demo_donor_001',
      'bookingId': 'demo_booking_001',
      'campId': 'camp001',
      'staffId': 'staff001',
    },
    {
      'name': 'Ayesha Khan',
      'phone': '03001234567',
      'bloodGroup': 'A+',
      'screeningStatus': 'Screening Passed',
      'slot': '09:00 AM',
      'donorId': 'demo_donor_002',
      'bookingId': 'demo_booking_002',
      'campId': 'camp001',
      'staffId': 'staff001',
    },
  ];

  Map<String, dynamic>? selectedDonor;

  final TextEditingController bagNumberController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  String donationType = 'Whole Blood';
  String donationStatus = 'Completed';

  bool isSaving = false;

  @override
  void dispose() {
    bagNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> saveDonation() async {
    if (selectedDonor == null) {
      showMessage(
        'Please select a donor.',
        isError: true,
      );
      return;
    }

    if (bagNumberController.text.trim().isEmpty) {
      showMessage(
        'Please enter the bag / unit number.',
        isError: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // Get IDs from the selected donor
      final String donorId =
          selectedDonor!['donorId']?.toString() ??
              selectedDonor!['id']?.toString() ??
              'demo_donor';

      final String bookingId =
          selectedDonor!['bookingId']?.toString() ??
              'demo_booking';

      final String campId =
          selectedDonor!['campId']?.toString() ??
              'camp001';

      final String staffId =
          selectedDonor!['staffId']?.toString() ??
              'staff001';

      await DonationRecordsFirestore.addDonation(
        donorId: donorId,
        bookingId: bookingId,
        campId: campId,
        bloodGroup:
            selectedDonor!['bloodGroup']?.toString() ?? '',
        bagNumber: bagNumberController.text.trim(),
        donationStatus: donationStatus,
        staffId: staffId,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSuccessDialog(
        donorId: donorId,
        bookingId: bookingId,
        campId: campId,
        staffId: staffId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(
        'Failed to save donation record.\n$e',
        isError: true,
      );
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
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
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
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
                  'Donation Status: $donationStatus',
                ),
                Text('Staff ID: $staffId'),
                Text(
                  'Donation Type: $donationType',
                ),

                if (notesController.text.trim().isNotEmpty)
                  Text(
                    'Notes: ${notesController.text.trim()}',
                  ),

                const SizedBox(height: 12),

                const Text(
                  'Donation Date & Time: Saved automatically',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
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

            // --------------------------------------------------
            // SELECT DONOR
            // --------------------------------------------------

            const Text(
              'Select Donor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedDonor,
              decoration: InputDecoration(
                labelText: 'Donor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.person,
                ),
              ),
              items: donors.map((donor) {
                return DropdownMenuItem<
                    Map<String, dynamic>>(
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

            // --------------------------------------------------
            // DONOR INFORMATION
            // --------------------------------------------------

            if (selectedDonor != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                      'Name: ${selectedDonor!['name']}',
                    ),
                    Text(
                      'Phone: ${selectedDonor!['phone']}',
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

            // --------------------------------------------------
            // BAG / UNIT NUMBER
            // --------------------------------------------------

            const Text(
              'Donation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                prefixIcon: const Icon(
                  Icons.bloodtype,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // BLOOD GROUP
            // --------------------------------------------------

            DropdownButtonFormField<String>(
              value: selectedDonor?['bloodGroup']
                  ?.toString(),
              decoration: InputDecoration(
                labelText: 'Blood Group',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.water_drop,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'A+',
                  child: Text('A+'),
                ),
                DropdownMenuItem(
                  value: 'A-',
                  child: Text('A-'),
                ),
                DropdownMenuItem(
                  value: 'B+',
                  child: Text('B+'),
                ),
                DropdownMenuItem(
                  value: 'B-',
                  child: Text('B-'),
                ),
                DropdownMenuItem(
                  value: 'AB+',
                  child: Text('AB+'),
                ),
                DropdownMenuItem(
                  value: 'AB-',
                  child: Text('AB-'),
                ),
                DropdownMenuItem(
                  value: 'O+',
                  child: Text('O+'),
                ),
                DropdownMenuItem(
                  value: 'O-',
                  child: Text('O-'),
                ),
              ],
              onChanged: (value) {
                if (selectedDonor != null &&
                    value != null) {
                  setState(() {
                    selectedDonor!['bloodGroup'] =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // DONATION TYPE
            // --------------------------------------------------

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
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
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

            // --------------------------------------------------
            // DONATION STATUS
            // --------------------------------------------------

            DropdownButtonFormField<String>(
              value: donationStatus,
              decoration: InputDecoration(
                labelText: 'Donation Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
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

            // --------------------------------------------------
            // NOTES
            // --------------------------------------------------

            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText:
                    'Enter donation notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.notes,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // SAVE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isSaving ? null : saveDonation,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Save Donation Record',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
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