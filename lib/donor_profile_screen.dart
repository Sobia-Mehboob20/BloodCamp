import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final Color blue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color red = const Color(0xFFE51C2A);

  Uint8List? profileImage;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile information not found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final String name =
              data['name']?.toString() ?? 'Donor';

          final String phone =
              data['phone']?.toString() ?? 'Not added';

          final String city =
              data['city']?.toString() ?? 'Not added';

          final String bloodGroup =
              data['bloodGroup']?.toString() ?? 'Not added';

          // Read Base64 image from Firestore
          Uint8List? firestoreProfileImage;

          final String? base64Image =
              data['profileImage']?.toString();

          if (base64Image != null && base64Image.isNotEmpty) {
            try {
              firestoreProfileImage =
                  base64Decode(base64Image);
            } catch (e) {
              firestoreProfileImage = null;
            }
          }

          DateTime? lastDonation;

          if (data['lastDonationAt'] is Timestamp) {
            lastDonation =
                (data['lastDonationAt'] as Timestamp).toDate();
          }

          final String lastDonationText =
              lastDonation == null
                  ? 'No donation recorded'
                  : _formatDate(lastDonation);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            const Color(0xFFEAF3FF),
                        backgroundImage:
                            firestoreProfileImage != null
                                ? MemoryImage(
                                    firestoreProfileImage,
                                  )
                                : null,
                        child: firestoreProfileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Blood Donor',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bloodGroup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen(),
                              ),
                            );

                            // Firestore StreamBuilder automatically
                            // refreshes the profile image after save.
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: name,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  value: currentUser.email ?? 'Not available',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: phone,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.location_city_outlined,
                  title: 'City',
                  value: city,
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Donation Information',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.bloodtype,
                  title: 'Blood Group',
                  value: bloodGroup,
                  iconColor: red,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Last Donation',
                  value: lastDonationText,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: BorderSide(
                        color: red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Powered by Alkhidmat & Bano Qabil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 23, 23, 24)
                .withOpacity(0.04),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? blue,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }
}