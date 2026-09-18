import 'package:flutter/material.dart';
import 'screenings_firestore.dart';

class DonorScreeningScreen extends StatefulWidget {
  final Map<String, dynamic> donor;

  const DonorScreeningScreen({
    super.key,
    required this.donor,
  });

  @override
  State<DonorScreeningScreen> createState() => _DonorScreeningScreenState();
}

class _DonorScreeningScreenState extends State<DonorScreeningScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController lastDonationController =
      TextEditingController();
  final TextEditingController bagNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? bloodGroup;
  String? screeningShift;

  bool feelingWell = true;
  bool isSaving = false;

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

  final List<String> screeningShifts = [
    'Morning',
    'Afternoon',
    'Evening',
  ];

  // Firebase IDs
  String get donorId =>
      widget.donor['donorId']?.toString() ??
      widget.donor['id']?.toString() ??
      'demo_donor';

  String get bookingId =>
      widget.donor['bookingId']?.toString() ?? 'demo_booking';

  String get campId =>
      widget.donor['campId']?.toString() ?? 'camp001';

  String get staffId =>
      widget.donor['staffId']?.toString() ?? 'staff001';

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    lastDonationController.dispose();
    bagNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> completeScreening() async {
    if (isSaving) return;

    final int? age = int.tryParse(ageController.text.trim());
    final double? weight = double.tryParse(weightController.text.trim());
    final int? lastDonationDays =
        int.tryParse(lastDonationController.text.trim());

    if (age == null || age <= 0) {
      _showMessage('Please enter a valid age.');
      return;
    }

    if (weight == null || weight <= 0) {
      _showMessage('Please enter a valid weight.');
      return;
    }

    if (lastDonationDays == null || lastDonationDays < 0) {
      _showMessage('Please enter valid days since last donation.');
      return;
    }

    if (bloodGroup == null) {
      _showMessage('Please select the blood group.');
      return;
    }

    if (screeningShift == null) {
      _showMessage('Please select the screening shift.');
      return;
    }

    if (bagNumberController.text.trim().isEmpty) {
      _showMessage('Please enter the bag/unit number.');
      return;
    }

    // Demo eligibility logic.
    // Replace these rules later with your approved medical criteria.
    bool passed = true;
    String reason = 'Eligible for donation';

    if (age < 18) {
      passed = false;
      reason = 'Donor must be at least 18 years old.';
    } else if (lastDonationDays < 56) {
      passed = false;
      reason = 'Not enough days have passed since the last donation.';
    } else if (!feelingWell) {
      passed = false;
      reason = 'Donor is not feeling well today.';
    }

    final String screeningStatus = passed ? 'passed' : 'deferred';

    setState(() {
      isSaving = true;
    });

    try {
      await ScreeningsFirestore.addScreening(
        donorId: donorId,
        bookingId: bookingId,
        campId: campId,
        age: age,
        weight: weight,
        lastDonationDate: DateTime.now().subtract(
          Duration(days: lastDonationDays),
        ),
        feelingWell: feelingWell,
        screeningStatus: screeningStatus,
        reason: reason,
        staffId: staffId,
        screeningShift: screeningShift!,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showScreeningResult(
        passed: passed,
        reason: reason,
        screeningStatus: screeningStatus,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        'Could not save screening.\n\nFirebase error:\n$e',
      );
    }
  }

  void showScreeningResult({
    required bool passed,
    required String reason,
    required String screeningStatus,
  }) {
    final String screeningDateTime = _formatDateTime(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed ? Colors.green : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  passed ? 'Screening Passed' : 'Screening Deferred',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed
                      ? 'The donor has passed the screening and can proceed with blood donation.'
                      : reason,
                ),
                const SizedBox(height: 18),

                _resultRow('Donor ID', donorId),
                _resultRow('Booking ID', bookingId),
                _resultRow('Camp ID', campId),
                _resultRow('Staff ID', staffId),
                _resultRow(
                  'Screening Status',
                  screeningStatus,
                ),
                _resultRow(
                  'Reason',
                  reason,
                ),
                _resultRow(
                  'Screening Date & Time',
                  screeningDateTime,
                ),
                _resultRow(
                  'Screening Shift',
                  screeningShift!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pop(
                  context,
                  passed ? 'Screening Passed' : 'Deferred',
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();

    int hour = dateTime.hour;
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    final String period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$day/$month/$year $hour:$minute $period';
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0867B2),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
            borderSide: BorderSide(
              color: Color(0xFF0867B2),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String donorName =
        widget.donor['name']?.toString() ?? 'Unknown Donor';

    final String donorPhone =
        widget.donor['phone']?.toString() ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donor Screening',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0867B2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // DONOR INFORMATION
            // ---------------------------------------------------------
            _sectionTitle(
              'Donor Information',
              Icons.person_outline,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donorName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Phone: $donorPhone'),
                  const SizedBox(height: 14),

                  // Firebase IDs
                  _infoRow('Donor ID', donorId),
                  _infoRow('Booking ID', bookingId),
                  _infoRow('Camp ID', campId),
                  _infoRow('Staff ID', staffId),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // HEALTH SCREENING
            // ---------------------------------------------------------
            _sectionTitle(
              'Health Screening',
              Icons.health_and_safety_outlined,
            ),

            _textField(
              controller: ageController,
              label: 'Age',
              hint: 'Enter donor age',
              keyboardType: TextInputType.number,
            ),

            _textField(
              controller: weightController,
              label: 'Weight (kg)',
              hint: 'Enter weight in kg',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            _textField(
              controller: lastDonationController,
              label: 'Days Since Last Donation',
              hint: 'Example: 60',
              keyboardType: TextInputType.number,
            ),

            // Feeling well
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feeling Well Today?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Yes'),
                    value: true,
                    groupValue: feelingWell,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        feelingWell = value ?? true;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('No'),
                    value: false,
                    groupValue: feelingWell,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        feelingWell = value ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),

            _dropdownField(
              label: 'Blood Group',
              value: bloodGroup,
              items: bloodGroups,
              onChanged: (value) {
                setState(() {
                  bloodGroup = value;
                });
              },
            ),

            _dropdownField(
              label: 'Screening Shift',
              value: screeningShift,
              items: screeningShifts,
              onChanged: (value) {
                setState(() {
                  screeningShift = value;
                });
              },
            ),

            // ---------------------------------------------------------
            // DONATION DETAILS
            // ---------------------------------------------------------
            _sectionTitle(
              'Donation Details',
              Icons.bloodtype_outlined,
            ),

            _textField(
              controller: bagNumberController,
              label: 'Bag / Unit Number',
              hint: 'Enter bag or unit number',
            ),

            _textField(
              controller: notesController,
              label: 'Screening Notes',
              hint: 'Enter additional screening notes',
            ),

            // ---------------------------------------------------------
            // SYSTEM INFORMATION
            // ---------------------------------------------------------
            _sectionTitle(
              'Screening Record',
              Icons.assignment_outlined,
            ),

            _infoRow(
              'Screening Date & Time',
              'Automatically recorded when screening is completed',
            ),

            _infoRow(
              'Screening Status',
              'Automatically determined after screening',
            ),

            _infoRow(
              'Reason',
              'Automatically recorded after screening',
            ),

            const SizedBox(height: 20),

            // ---------------------------------------------------------
            // COMPLETE SCREENING BUTTON
            // ---------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : completeScreening,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isSaving ? 'Saving Screening...' : 'Complete Screening',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0867B2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
