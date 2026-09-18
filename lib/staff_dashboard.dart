import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'donor_roster.dart';
import 'donation_record.dart';
import 'walk_in_donor.dart';
import 'end_of_shift.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState
    extends State<StaffDashboardScreen> {
  int selectedIndex = 0;

  Widget _getCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return const StaffHomePage();

      case 1:
        return const StaffRosterPage();

      case 2:
        return const DonationRecordScreen();

      case 3:
        return const StaffProfilePageInside();

      default:
        return const StaffHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        selectedItemColor:
            const Color(0xFF0867B2),

        unselectedItemColor:
            Colors.grey,

        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Roster',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bloodtype_outlined),
            activeIcon: Icon(Icons.bloodtype),
            label: 'Donation',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAFF HOME PAGE
// ============================================================

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() =>
      _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static const String campId = 'camp001';
  

  int bookedDonors = 0;
  int checkedInDonors = 0;
  int collectedDonations = 0;
  int deferredDonors = 0;

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // ==========================================================
  // LOAD DASHBOARD DATA FROM FIREBASE
  // ==========================================================

  Future<void> loadDashboardData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final bookingQuery = firestore
          .collection('bookings')
          .where(
            'campId',
            isEqualTo: campId,
          )
          .get();

      final walkInQuery = firestore
          .collection('walk_in_donors')
          .where(
            'campId',
            isEqualTo: campId,
          )
          .get();

      final screeningQuery = firestore
          .collection('screenings')
          .where(
            'campId',
            isEqualTo: campId,
          )
          .get();

      final donationQuery = firestore
          .collection('donations')
          .where(
            'campId',
            isEqualTo: campId,
          )
          .get();

      final results = await Future.wait([
        bookingQuery,
        walkInQuery,
        screeningQuery,
        donationQuery,
      ]);

      final bookingSnapshot = results[0];
      final walkInSnapshot = results[1];
      final screeningSnapshot = results[2];
      final donationSnapshot = results[3];

      // --------------------------------------------------------
      // BOOKED DONORS
      // --------------------------------------------------------

      int booked = 0;

      booked =
          bookingSnapshot.docs.length +
          walkInSnapshot.docs.length;

      // --------------------------------------------------------
      // CHECKED-IN DONORS
      // --------------------------------------------------------

      int checkedIn = 0;

      // Normal bookings
      for (final doc in bookingSnapshot.docs) {
        final data = doc.data();

        final status =
            data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (_isCheckedInStatus(status)) {
          checkedIn++;
        }
      }

      // Walk-in donors
      for (final doc in walkInSnapshot.docs) {
        final data = doc.data();

        final status =
            data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (_isCheckedInStatus(status)) {
          checkedIn++;
        }
      }

      // --------------------------------------------------------
      // DEFERRED DONORS
      // --------------------------------------------------------

      int deferred = 0;

      for (final doc in screeningSnapshot.docs) {
        final data = doc.data();

        final status =
            data['screeningStatus']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (status == 'deferred') {
          deferred++;
        }
      }

      // --------------------------------------------------------
      // COMPLETED DONATIONS
      // --------------------------------------------------------

      int collected = 0;

      for (final doc in donationSnapshot.docs) {
        final data = doc.data();

        final status =
            data['donationStatus']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        if (status == 'completed') {
          collected++;
        }
      }

      if (!mounted) return;

      setState(() {
        bookedDonors = booked;
        checkedInDonors = checkedIn;
        deferredDonors = deferred;
        collectedDonations = collected;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load dashboard data.';
      });
    }
  }

  // ==========================================================
  // CHECK-IN STATUS HELPER
  // ==========================================================

  bool _isCheckedInStatus(String status) {
    return status == 'checked in' ||
        status == 'checked_in' ||
        status == 'screening' ||
        status == 'screening passed' ||
        status == 'passed' ||
        status == 'deferred';
  }

  // ==========================================================
  // HOME PAGE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Camp Staff Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
            ),

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const StaffNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadDashboardData,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          children: [
            // ==================================================
            // WELCOME SECTION
            // ==================================================

            const Text(
              'Welcome, Camp Staff 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Manage today’s blood donation camp activities.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TODAY'S CAMP CARD
            // ==================================================

            _todayCampCard(),

            const SizedBox(height: 20),

            // ==================================================
            // OVERVIEW TITLE
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: loadDashboardData,
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF0867B2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // ERROR MESSAGE
            // ==================================================

            if (errorMessage.isNotEmpty)
              Container(
                margin:
                    const EdgeInsets.only(bottom: 15),

                padding:
                    const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color:
                              Colors.red.shade700,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed:
                          loadDashboardData,
                      child: const Text(
                        'Try Again',
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // OVERVIEW CARDS
            // ==================================================

            if (isLoading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(30),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else
              _overviewCards(),

            const SizedBox(height: 25),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _actionButton(
              icon: Icons.people,
              title: "Today's Donor Roster",
              subtitle:
                  'View and manage today\'s donors',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DonorRosterScreen(),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.person_add,
              title: 'Walk-in Donor',
              subtitle:
                  'Register a walk-in donor',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WalkInDonorScreen(),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.health_and_safety,
              title: 'Screen Donor',
              subtitle:
                  'Screen a checked-in donor',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DonorRosterScreen(),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.bloodtype,
              title: 'Donation Record',
              subtitle:
                  'Record completed donations',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DonationRecordScreen(),
                  ),
                );
              },
            ),

            _actionButton(
              icon: Icons.assignment_turned_in,
              title: 'End-of-Shift List',
              subtitle:
                  'Review and complete your shift',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const EndOfShiftScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARDS
  // ============================================================

  Widget _overviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.people,
                'Booked',
                bookedDonors.toString(),
                const Color(0xFF0867B2),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                Icons.how_to_reg,
                'Checked In',
                checkedInDonors.toString(),
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.bloodtype,
                'Collected',
                collectedDonations.toString(),
                const Color(0xFFE91E2B),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _statCard(
                Icons.warning_amber_rounded,
                'Deferred',
                deferredDonors.toString(),
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // TODAY'S CAMP CARD
  // ============================================================

  Widget _todayCampCard() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0867B2),
            Color(0xFF0B82D8),
          ],
        ),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            "Today's Camp",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Alkhidmat Blood Donation Camp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),

              SizedBox(width: 6),

              Text(
                'Lahore Campus',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          const Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white,
                size: 18,
              ),

              SizedBox(width: 6),

              Text(
                '09:00 AM - 05:00 PM',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      child: Material(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(14),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(14),

          onTap: onTap,

          child: Container(
            padding:
                const EdgeInsets.all(16),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),

              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE8F2FA),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Icon(
                    icon,
                    color:
                        const Color(0xFF0867B2),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STAFF ROSTER PAGE
// ============================================================

class StaffRosterPage extends StatelessWidget {
  const StaffRosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Donor Roster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Today’s Donor Roster',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'View, check in and screen registered donors.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const DonorRosterScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.people,
                ),

                label: const Text(
                  'Open Donor Roster',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0867B2),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAFF DONATION PAGE
// ============================================================

class StaffDonationPage extends StatelessWidget {
  const StaffDonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Donation Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Donation Records',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Record completed blood donations.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const DonationRecordScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.bloodtype,
                ),

                label: const Text(
                  'Open Donation Records',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFE91E2B),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAFF PROFILE PAGE
// ============================================================

class StaffProfilePageInside
    extends StatelessWidget {
  const StaffProfilePageInside({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Staff Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [
          const SizedBox(height: 10),

          const Center(
            child: CircleAvatar(
              radius: 45,

              backgroundColor:
                  Color(0xFFE8F2FA),

              child: Icon(
                Icons.person,
                size: 50,
                color:
                    Color(0xFF0867B2),
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'Camp Staff',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Text(
              'staff001',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 30),

          _profileItem(
            Icons.badge,
            'Role',
            'Camp Staff',
          ),

          _profileItem(
            Icons.location_on,
            'Assigned Camp',
            'Lahore Campus',
          ),

          _profileItem(
            Icons.bloodtype,
            'Department',
            'Blood Donation Camp',
          ),
        ],
      ),
    );
  }

  Widget _profileItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F9FC),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF0867B2),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAFF NOTIFICATIONS SCREEN
// ============================================================

class StaffNotificationsScreen
    extends StatelessWidget {
  const StaffNotificationsScreen({
    super.key,
  });

  

  @override
  Widget build(BuildContext context) {
    final firestore =
        FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('notifications')
            .where(
              'userId',
              isEqualTo: 'staff001',
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load notifications.',
              ),
            );
          }

          final notifications =
              snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 60,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'You are all caught up.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),

            itemCount:
                notifications.length,

            itemBuilder: (
              context,
              index,
            ) {
              final data =
                  notifications[index].data();

              return _NotificationCard(
                title:
                    data['title']
                            ?.toString() ??
                        'Notification',

                message:
                    data['message']
                            ?.toString() ??
                        '',

                isRead:
                    data['isRead'] == true,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// NOTIFICATION CARD
// ============================================================

class _NotificationCard
    extends StatelessWidget {
  final String title;
  final String message;
  final bool isRead;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color(0xFFE8F2FA),

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const CircleAvatar(
            backgroundColor:
                Color(0xFFE8F2FA),

            child: Icon(
              Icons.notifications,
              color:
                  Color(0xFF0867B2),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style:
                      const TextStyle(
                    color: Colors.grey,
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
}
