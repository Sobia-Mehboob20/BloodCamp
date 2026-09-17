import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_bookings_screen.dart';
import 'camp_list_screen.dart';
import 'donation_history_screen.dart';
import 'health_tips_screen.dart';
import 'thank_you_card_screen.dart';
import 'donor_profile_screen.dart';
import 'notification_screen.dart';

class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key});

  final Color blue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color red = const Color(0xFFE51C2A);

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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('User profile not found.'),
            ),
          );
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>;

        final String name =
            userData['name']?.toString() ?? 'Donor';

        final String bloodGroup =
            userData['bloodGroup']?.toString() ?? 'Not added';

        // ============================================================
        // LOAD PROFILE IMAGE FROM FIRESTORE
        // ============================================================

        Uint8List? profileImageBytes;

        final String? base64Image =
            userData['profileImage']?.toString();

        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            profileImageBytes = base64Decode(base64Image);
          } catch (e) {
            profileImageBytes = null;
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,

          body: SafeArea(
            child: Column(
              children: [
                // ======================================================
                // HEADER
                // ======================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ==================================================
                      // PROFILE IMAGE
                      // ==================================================

                      CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImageBytes != null
                            ? MemoryImage(profileImageBytes)
                            : null,
                        child: profileImageBytes == null
                            ? const Icon(
                                Icons.person,
                                size: 35,
                                color: Colors.grey,
                              )
                            : null,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            const Text(
                              'Donor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where(
                              'userId',
                              isEqualTo: FirebaseAuth
                                  .instance
                                  .currentUser
                                  ?.uid,
                            )
                            .where(
                              'isRead',
                              isEqualTo: false,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          final int unreadCount =
                              snapshot.data?.docs.length ?? 0;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),

                              if (unreadCount > 0)
                                Positioned(
                                  right: 5,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      unreadCount > 9
                                          ? '9+'
                                          : unreadCount.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ======================================================
                // CONTENT
                // ======================================================

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // NEXT CAMP
                        _buildNextCampCard(context),

                        const SizedBox(height: 15),

                        // ELIGIBILITY
                        _buildEligibilityCard(userData),

                        const SizedBox(height: 15),

                        // ==================================================
                        // QUICK ACTIONS ROW 1
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.calendar_month,
                                title: 'Book a Slot',
                                color: red,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CampListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.assignment,
                                title: 'My Bookings',
                                color: blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyBookingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // QUICK ACTIONS ROW 2
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.history,
                                title: 'Donation History',
                                color: red,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DonationHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.lightbulb_outline,
                                title: 'Health Tips',
                                color: blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HealthTipsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // BLOOD GROUP
                        // ==================================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bloodtype,
                                color: red,
                                size: 30,
                              ),

                              const SizedBox(width: 12),

                              const Text(
                                'Your Blood Group',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const Spacer(),

                              Text(
                                bloodGroup,
                                style: TextStyle(
                                  color: red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // BOTTOM NAVIGATION
          // ============================================================

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            selectedItemColor: blue,
            unselectedItemColor: Colors.grey,

            onTap: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CampListScreen(),
                  ),
                );
              }

              if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyBookingsScreen(),
                  ),
                );
              }

              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DonorProfileScreen(),
                  ),
                );
              }
            },

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.location_on),
                label: 'Camps',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Bookings',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // NEXT CAMP CARD
  // ============================================================

  Widget _buildNextCampCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('camps').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        String campName = 'No upcoming camp';
        String dateText = 'Check camps for more information';
        String timeText = '';
        String locationText = '';
        String? campId;

        if (snapshot.hasData) {
          final List<QueryDocumentSnapshot> validCamps = [];

          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            final dateValue = data['date'];

            if (dateValue is Timestamp) {
              validCamps.add(doc);
            }
          }

          validCamps.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aDate =
                (aData['date'] as Timestamp).toDate();

            final bDate =
                (bData['date'] as Timestamp).toDate();

            return aDate.compareTo(bDate);
          });

          final DateTime today = DateTime.now();

          final DateTime todayOnly = DateTime(
            today.year,
            today.month,
            today.day,
          );

          for (final doc in validCamps) {
            final data = doc.data() as Map<String, dynamic>;

            final campDate =
                (data['date'] as Timestamp).toDate();

            final campDateOnly = DateTime(
              campDate.year,
              campDate.month,
              campDate.day,
            );

            if (!campDateOnly.isBefore(todayOnly)) {
              campId = doc.id;

              campName =
                  data['name'] ?? 'Blood Camp';

              dateText = _formatDate(campDate);

              final startTime =
                  data['startTime']?.toString() ?? '';

              final endTime =
                  data['endTime']?.toString() ?? '';

              if (startTime.isNotEmpty &&
                  endTime.isNotEmpty) {
                timeText = '$startTime - $endTime';
              } else {
                timeText = startTime;
              }

              locationText =
                  data['location']?.toString() ?? '';

              break;
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: red,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Text(
                    'Next Camp',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                campName,
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                dateText,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              if (timeText.isNotEmpty) ...[
                const SizedBox(height: 4),

                Text(
                  timeText,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],

              if (locationText.isNotEmpty) ...[
                const SizedBox(height: 4),

                Text(
                  locationText,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: campId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CampListScreen(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ELIGIBILITY CARD
  // ============================================================

  Widget _buildEligibilityCard(
      Map<String, dynamic> userData) {
    DateTime? lastDonation;

    if (userData['lastDonationAt'] != null) {
      final value = userData['lastDonationAt'];

      if (value is Timestamp) {
        lastDonation = value.toDate();
      }
    }

    DateTime? nextDonationDate;

    if (lastDonation != null) {
      nextDonationDate =
          lastDonation.add(const Duration(days: 56));
    }

    final DateTime today = DateTime.now();

    final bool canDonate =
        nextDonationDate == null ||
        !today.isBefore(nextDonationDate);

    String message;

    if (canDonate) {
      message = 'You can donate!';
    } else {
      final int days =
          nextDonationDate!.difference(today).inDays + 1;

      message = 'Wait $days more days';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: canDonate
            ? const Color(0xFFE8F8EF)
            : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                canDonate ? Colors.green : red,
            child: Icon(
              canDonate
                  ? Icons.check
                  : Icons.access_time,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Eligibility',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: TextStyle(
                    color:
                        canDonate ? Colors.green : red,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  nextDonationDate == null
                      ? 'You have no previous donation recorded.'
                      : 'Next donation allowed on '
                          '${_formatDate(nextDonationDate)}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF0D47A1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  static String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} '
        '${date.year}';
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