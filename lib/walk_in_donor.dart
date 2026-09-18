
import 'package:flutter/material.dart';
import 'walk_in_donors_firestore.dart';
import 'donor_roster.dart';

class WalkInDonorScreen extends StatefulWidget {
  final String campId;

  const WalkInDonorScreen({
    super.key,
    required this.campId,
  });

  @override
  State<WalkInDonorScreen> createState() =>
      _WalkInDonorScreenState();
}

class _WalkInDonorScreenState
    extends State<WalkInDonorScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController ageController =
      TextEditingController();

  final TextEditingController weightController =
      TextEditingController();

  String? selectedGender;
  String? selectedBloodGroup;
  String? selectedLastDonation;

  bool feelingWell = true;
  bool isSaving = false;

  String selectedMedicalCondition = 'None';

  final List<String> medicalConditions = [
    'None',
    'Fever / Acute Illness',
    'Active Infection',
    'Heart Condition',
    'Serious Blood Disorder',
    'Cancer',
    'Hepatitis / Liver Infection',
    'Other Medical Condition',
  ];

  final List<String> genders = [
    'Male',
    'Female',
    'Other',
  ];

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

  final List<String> lastDonationOptions = [
    'Never',
    'Less than 56 days',
    '56–90 days',
    'More than 90 days',
  ];

  bool get hasMedicalConcern =>
      selectedMedicalCondition != 'None';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ageController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> registerWalkInDonor() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        selectedGender == null ||
        selectedBloodGroup == null ||
        selectedLastDonation == null) {
      showMessage(
        'Please complete all required fields.',
        isError: true,
      );
      return;
    }

    if (!emailController.text.contains('@')) {
      showMessage(
        'Please enter a valid email address.',
        isError: true,
      );
      return;
    }

    final int? age =
        int.tryParse(ageController.text.trim());

    final double? weight =
        double.tryParse(weightController.text.trim());

    if (age == null || age <= 0) {
      showMessage(
        'Please enter a valid age.',
        isError: true,
      );
      return;
    }

    if (weight == null || weight <= 0) {
      showMessage(
        'Please enter a valid weight.',
        isError: true,
      );
      return;
    }

    if (hasMedicalConcern) {
      showMedicalWarning();
      return;
    }

    if (!feelingWell) {
      showMessage(
        'The donor must be feeling well before registration.',
        isError: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // The value stored in Firestore is exactly "camp 7".
      final String campId = widget.campId;

      const String staffId = 'staff001';

      await WalkInDonorsFirestore.addWalkInDonor(
        donorName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        age: age,
        gender: selectedGender!,
        bloodGroup: selectedBloodGroup!,
        campId: campId,
        registeredByStaff: staffId,
        status: 'Walk-in Registered',
        medicalCondition: selectedMedicalCondition,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const DonorRosterScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(
        'Failed to register walk-in donor.\n$e',
        isError: true,
      );
    }
  }

  void showMedicalWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Medical Review Required',
                ),
              ),
            ],
          ),
          content: Text(
            'The donor selected:\n\n'
            '$selectedMedicalCondition\n\n'
            'Walk-in registration cannot be completed '
            'until the donor is medically reviewed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

  InputDecoration fieldDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk-in Donor'),
        backgroundColor:
            const Color(0xFF064D8C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Donor Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: fieldDecoration(
                'Full Name',
                Icons.person,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: fieldDecoration(
                'Email',
                Icons.email,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration: fieldDecoration(
                'Phone Number',
                Icons.phone,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: ageController,
              keyboardType:
                  TextInputType.number,
              decoration: fieldDecoration(
                'Age',
                Icons.calendar_today,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: fieldDecoration(
                'Weight (kg)',
                Icons.monitor_weight,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: fieldDecoration(
                'Gender',
                Icons.people,
              ),
              items: genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              decoration: fieldDecoration(
                'Blood Group',
                Icons.bloodtype,
              ),
              items: bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBloodGroup = value;
                });
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: selectedLastDonation,
              decoration: fieldDecoration(
                'Last Donation',
                Icons.history,
              ),
              items:
                  lastDonationOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLastDonation = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Medical Screening',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasMedicalConcern
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: hasMedicalConcern
                      ? Colors.red
                      : Colors.grey.shade400,
                  width:
                      hasMedicalConcern ? 2 : 1,
                ),
              ),
              child:
                  DropdownButtonFormField<String>(
                value:
                    selectedMedicalCondition,
                decoration: InputDecoration(
                  labelText:
                      'Medical Condition',
                  prefixIcon: Icon(
                    hasMedicalConcern
                        ? Icons.warning
                        : Icons.health_and_safety,
                    color: hasMedicalConcern
                        ? Colors.red
                        : Colors.green,
                  ),
                  border: InputBorder.none,
                ),
                items: medicalConditions
                    .map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMedicalCondition =
                          value;
                    });
                  }
                },
              ),
            ),

            if (hasMedicalConcern) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Medical review required. '
                        'Registration is blocked until '
                        'eligibility is confirmed.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Feeling Well Today?',
              ),
              subtitle: Text(
                feelingWell ? 'Yes' : 'No',
              ),
              value: feelingWell,
              activeColor:
                  const Color(0xFF064D8C),
              onChanged: (value) {
                setState(() {
                  feelingWell = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Camp Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today’s Camp',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Camp ID: ${widget.campId}',
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Registration Time: Automatic',
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Registered By: staff001',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : registerWalkInDonor,
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
                        Icons.person_add,
                      ),
                label: Text(
                  isSaving
                      ? 'Registering...'
                      : 'Register Walk-in Donor',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC62828),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
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