import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donor_screening.dart';

class DonorRosterScreen extends StatefulWidget {
  const DonorRosterScreen({super.key});

  @override
  State<DonorRosterScreen> createState() => _DonorRosterScreenState();
}

class _DonorRosterScreenState extends State<DonorRosterScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController searchController = TextEditingController();

  int selectedIndex = 1;

  // Your actual camp document IDs
  final List<String> campIds = [
    'camp 3',
    'camp 4',
    'camp 5',
    'camp 6',
    'camp 7',
  ];

  final String staffId = 'staff001';

  bool isLoading = true;

  List<Map<String, dynamic>> donors = [];

  @override
  void initState() {
    super.initState();
    loadDonors();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD DONORS FROM BOOKINGS + USERS + WALK-IN DONORS
  // =========================================================

  Future<void> loadDonors() async {
    try {
      setState(() {
        isLoading = true;
      });

      // -------------------------------------------------------
      // USERS
      // -------------------------------------------------------

      final Map<String, Map<String, dynamic>> usersMap = {};

      final usersSnapshot =
          await firestore.collection('users').get();

      for (final doc in usersSnapshot.docs) {
        usersMap[doc.id] = {
          ...doc.data(),
          'id': doc.id,
        };
      }

      // -------------------------------------------------------
      // ALL DONORS
      // -------------------------------------------------------

      final List<Map<String, dynamic>> allDonors = [];

      // -------------------------------------------------------
      // BOOKED DONORS
      // -------------------------------------------------------

      for (final currentCampId in campIds) {
        final bookingsSnapshot = await firestore
            .collection('bookings')
            .where(
              'campId',
              isEqualTo: currentCampId,
            )
            .get();

        for (final doc in bookingsSnapshot.docs) {
          final booking = doc.data();

          final String donorId =
              booking['donorId']?.toString() ?? '';

          final Map<String, dynamic> userData =
              usersMap[donorId] ?? {};

          allDonors.add({
            'id': doc.id,
            'documentId': doc.id,
            'donorId': donorId,
            'bookingId': doc.id,

            'campId':
                booking['campId'] ?? currentCampId,

            'name':
                booking['donorName'] ??
                userData['name'] ??
                'Unknown Donor',

            'phone':
                booking['donorPhone'] ??
                userData['phone'] ??
                '',

            'email':
                booking['donorEmail'] ??
                userData['email'] ??
                '',

            'bloodGroup':
                booking['bloodGroup'] ??
                userData['bloodGroup'] ??
                'N/A',

            'city':
                booking['city'] ??
                userData['city'] ??
                '',

            'slot':
                booking['slot'] ?? '',

            'date':
                booking['date'] ?? '',

            'location':
                booking['location'] ?? '',

            'campName':
                booking['campName'] ??
                'Blood Camp',

            'status':
                booking['status'] ??
                'Booked',

            'type': 'booking',

            'lastDonation':
                userData['lastDonation'],
          });
        }
      }

      // -------------------------------------------------------
      // WALK-IN DONORS
      // -------------------------------------------------------

      for (final currentCampId in campIds) {
        final walkInSnapshot = await firestore
            .collection('walk_in_donors')
            .where(
              'campId',
              isEqualTo: currentCampId,
            )
            .get();

        for (final doc in walkInSnapshot.docs) {
          final data = doc.data();

          allDonors.add({
            'id': doc.id,
            'documentId': doc.id,
            'donorId': doc.id,
            'bookingId': '',

            'campId':
                data['campId'] ?? currentCampId,

            'name':
                data['donorName'] ??
                'Walk-in Donor',

            'phone':
                data['phone'] ?? '',

            'email':
                data['email'] ?? '',

            'bloodGroup':
                data['bloodGroup'] ??
                'N/A',

            'city': '',

            'slot': '',

            'date': '',

            'location': '',

            'campName':
                data['campName'] ??
                'Blood Camp',

            'status':
                data['status'] ??
                'Walk-in Registered',

            'type': 'walkin',

            'age': data['age'],

            'weight': data['weight'],

            'gender': data['gender'],

            'medicalCondition':
                data['medicalCondition'],
          });
        }
      }

      // -------------------------------------------------------
      // UPDATE SCREEN
      // -------------------------------------------------------

      if (mounted) {
        setState(() {
          donors = allDonors;
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
              'Error loading donors: $e',
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  List<Map<String, dynamic>> get filteredDonors {
    final query =
        searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return donors;
    }

    return donors.where((donor) {
      final name =
          donor['name']?.toString().toLowerCase() ?? '';

      final phone =
          donor['phone']?.toString().toLowerCase() ?? '';

      final bloodGroup =
          donor['bloodGroup']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          phone.contains(query) ||
          bloodGroup.contains(query);
    }).toList();
  }

  // =========================================================
  // CHANGE BOTTOM NAVIGATION
  // =========================================================

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pop(context);
    }

    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Donation Record from the Staff Dashboard.',
          ),
        ),
      );
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const StaffProfileScreen(),
        ),
      );
    }
  }

  // =========================================================
  // CHECK IN DONOR
  // =========================================================

  Future<void> checkInDonor(
    Map<String, dynamic> donor,
  ) async {
    try {
      final String documentId =
          donor['documentId']?.toString() ?? '';

      final String type =
          donor['type']?.toString() ?? 'booking';

      if (documentId.isEmpty) {
        return;
      }

      if (type == 'walkin') {
        await firestore
            .collection('walk_in_donors')
            .doc(documentId)
            .update({
          'status': 'Checked In',
        });
      } else {
        await firestore
            .collection('bookings')
            .doc(documentId)
            .update({
          'status': 'Checked In',
        });
      }

      setState(() {
        donor['status'] = 'Checked In';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${donor['name']} checked in successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in failed: $e',
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // OPEN SCREENING
  // =========================================================

  Future<void> openScreening(
    Map<String, dynamic> donor,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DonorScreeningScreen(
          donor: donor,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    String newStatus = 'Screening Passed';

    if (result is Map<String, dynamic>) {
      newStatus =
          result['status']?.toString() ??
          'Screening Passed';
    } else if (result is String) {
      newStatus = result;
    }

    setState(() {
      donor['status'] = newStatus;
    });

    try {
      final String documentId =
          donor['documentId']?.toString() ?? '';

      final String type =
          donor['type']?.toString() ?? 'booking';

      if (documentId.isNotEmpty) {
        if (type == 'walkin') {
          await firestore
              .collection('walk_in_donors')
              .doc(documentId)
              .update({
            'status': newStatus,
          });
        } else {
          await firestore
              .collection('bookings')
              .doc(documentId)
              .update({
            'status': newStatus,
          });
        }
      }
    } catch (_) {
      // Screening itself has already been saved.
    }
  }

  // =========================================================
  // DONOR CARD
  // =========================================================

  Widget buildDonorCard(
    Map<String, dynamic> donor,
  ) {
    final String name =
        donor['name']?.toString() ??
        'Unknown Donor';

    final String phone =
        donor['phone']?.toString() ?? '';

    final String bloodGroup =
        donor['bloodGroup']?.toString() ?? 'N/A';

    final String status =
        donor['status']?.toString() ?? 'Booked';

    final String type =
        donor['type']?.toString() ?? 'booking';

    final bool checkedIn =
        status.toLowerCase().contains('checked');

    final bool screeningPassed =
        status.toLowerCase().contains('passed');

    final bool deferred =
        status.toLowerCase().contains('deferred');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      const Color(0xFFE8F1FA),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF0867B2),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        phone.isEmpty
                            ? 'Phone not available'
                            : phone,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Text(
                    bloodGroup,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  type == 'walkin'
                      ? Icons.person_add
                      : Icons.event_available,
                  size: 18,
                  color: Colors.grey.shade600,
                ),

                const SizedBox(width: 6),

                Text(
                  type == 'walkin'
                      ? 'Walk-in Donor'
                      : 'Booked Donor',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: deferred
                        ? Colors.orange.shade50
                        : screeningPassed
                            ? Colors.green.shade50
                            : checkedIn
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: deferred
                          ? Colors.orange.shade800
                          : screeningPassed
                              ? Colors.green.shade800
                              : checkedIn
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                if (!checkedIn &&
                    !screeningPassed &&
                    !deferred)
                  Expanded(
                    child:
                        ElevatedButton.icon(
                      onPressed: () =>
                          checkInDonor(donor),
                      icon: const Icon(
                        Icons.login,
                        size: 18,
                      ),
                      label:
                          const Text('Check In'),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF0867B2,
                        ),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 11,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!checkedIn &&
                    !screeningPassed &&
                    !deferred)
                  const SizedBox(width: 8),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: () =>
                        openScreening(donor),
                    icon: const Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                    ),
                    label: Text(
                      screeningPassed ||
                              deferred
                          ? 'View Screening'
                          : 'Screen Donor',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF0867B2,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 11,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final displayedDonors = filteredDonors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donor Roster',
          style: TextStyle(
            color: Color(0xFF0867B2),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF0867B2),
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

          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Color(0xFF0867B2),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const StaffProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadDonors,
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : Column(
                children: [
                  // ---------------- HEADER ----------------

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFEAF3FA),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today’s Donor Roster',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF0867B2),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Alkhidmat Blood Donation Camp',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${donors.length} donor(s) registered',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- SEARCH ----------------

                  Padding(
                    padding:
                        const EdgeInsets.all(15),
                    child: TextField(
                      controller:
                          searchController,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Search donor by name, phone or blood group',
                        prefixIcon:
                            const Icon(
                          Icons.search,
                        ),
                        suffixIcon:
                            searchController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    icon:
                                        const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      searchController
                                          .clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---------------- DONOR LIST ----------------

                  Expanded(
                    child: displayedDonors.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Icon(
                                  Icons.people_outline,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'No donors found',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                            itemCount:
                                displayedDonors.length,
                            itemBuilder:
                                (context, index) {
                              return buildDonorCard(
                                displayedDonors[
                                    index],
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: selectedIndex,
        type:
            BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color(0xFF0867B2),
        unselectedItemColor:
            Colors.grey,
        onTap: changePage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
            ),
            activeIcon: Icon(Icons.people),
            label: 'Roster',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.bloodtype_outlined,
            ),
            activeIcon:
                Icon(Icons.bloodtype),
            label: 'Donation',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STAFF NOTIFICATIONS SCREEN
// =============================================================

class StaffNotificationsScreen
    extends StatelessWidget {
  const StaffNotificationsScreen({
    super.key,
  });

  final String staffId = 'staff001';

  @override
  Widget build(BuildContext context) {
    final firestore =
        FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notifications'),
        backgroundColor:
            const Color(0xFF0867B2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('notifications')
            .where(
              'userId',
              isEqualTo: staffId,
            )
            .snapshots(),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Unable to load notifications.\n\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder:
                (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return _NotificationCard(
                documentId: doc.id,
                title:
                    data['title']
                            ?.toString() ??
                        'Notification',
                message:
                    data['message']
                            ?.toString() ??
                        '',
                type:
                    data['type']
                            ?.toString() ??
                        'general',
                isRead:
                    data['isRead'] == true,
                createdAt:
                    data['createdAt'],
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================
// NOTIFICATION CARD
// =============================================================

class _NotificationCard
    extends StatelessWidget {
  final String documentId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final dynamic createdAt;

  const _NotificationCard({
    required this.documentId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return '';
  }

  IconData getNotificationIcon() {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'reminder':
        return Icons.alarm;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),

        leading: CircleAvatar(
          backgroundColor:
              const Color(0xFFEAF3FA),
          child: Icon(
            getNotificationIcon(),
            color:
                const Color(0xFF0867B2),
          ),
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead
                      ? FontWeight.w500
                      : FontWeight.bold,
                ),
              ),
            ),

            if (!isRead)
              Container(
                width: 9,
                height: 9,
                decoration:
                    const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(message),

              const SizedBox(height: 5),

              Text(
                formatDate(createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        onTap: () async {
          if (!isRead) {
            await FirebaseFirestore
                .instance
                .collection('notifications')
                .doc(documentId)
                .update({
              'isRead': true,
            });
          }
        },
      ),
    );
  }
}

// =============================================================
// STAFF PROFILE SCREEN
// =============================================================

class StaffProfileScreen
    extends StatelessWidget {
  const StaffProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Staff Profile'),
        backgroundColor:
            const Color(0xFF0867B2),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor:
                  Color(0xFFEAF3FA),
              child: Icon(
                Icons.person,
                size: 55,
                color:
                    Color(0xFF0867B2),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Camp Staff',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'staff001',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            profileTile(
              icon:
                  Icons.badge_outlined,
              title: 'Staff ID',
              value: 'staff001',
            ),

            profileTile(
              icon:
                  Icons.work_outline,
              title: 'Role',
              value: 'Camp Staff',
            ),

            profileTile(
              icon:
                  Icons.location_on_outlined,
              title: 'Assigned Camp',
              value:
                  'Lahore Campus',
            ),

            profileTile(
              icon:
                  Icons.business_outlined,
              title: 'Department',
              value:
                  'Blood Donation Camp',
            ),

            const SizedBox(height: 20),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                ),
                label: const Text(
                  'Back to Roster',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF0867B2,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              const Color(0xFF0867B2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}