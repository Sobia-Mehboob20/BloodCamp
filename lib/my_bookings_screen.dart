import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_detail_screen.dart';

class MyBookingsScreen
    extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() =>
      _MyBookingsScreenState();
}

class _MyBookingsScreenState
    extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color blue =
      const Color(0xFF1565C0);

  final Color darkBlue =
      const Color(0xFF0D47A1);

  final Color red =
      const Color(0xFFE51C2A);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style:
                TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,

        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor:
              Colors.white,
          indicatorWeight: 3,
          labelColor:
              Colors.white,
          unselectedLabelColor:
              Colors.white70,

          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Check-in'),
            Tab(text: 'Completed'),
          ],
        ),
      ),

      body:
          StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore
            .instance
            .collection('bookings')
            .where(
              'donorId',
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child:
                  CircularProgressIndicator(
                color: blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          return TabBarView(
            controller:
                _tabController,

            children: [
              _buildBookingList(
                documents,
                ['Upcoming'],
              ),

              _buildBookingList(
                documents,
                [
                  'Confirmed',
                  'Checked in',
                  'Screening Passed',
                  'Passed',
                ],
              ),

              _buildBookingList(
                documents,
                ['Completed'],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(
    List<QueryDocumentSnapshot>
        documents,
    List<String> allowedStatuses,
  ) {
    final filteredBookings =
        documents.where((document) {
      final data =
          document.data()
              as Map<String, dynamic>;

      final status =
          data['status']
                  ?.toString()
                  .trim() ??
              'Upcoming';

      return allowedStatuses
          .map(
            (e) => e.toLowerCase(),
          )
          .contains(
            status.toLowerCase(),
          );
    }).toList();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(
        allowedStatuses,
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.all(16),
      itemCount:
          filteredBookings.length,
      itemBuilder: (
        context,
        index,
      ) {
        final booking =
            filteredBookings[index];

        final data =
            booking.data()
                as Map<String, dynamic>;

        return _buildBookingCard(
          context,
          booking.id,
          data,
        );
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final String campName =
        data['campName']?.toString() ??
            'Blood Camp';

    final String date =
        data['date']?.toString() ??
            'Date not available';

    final String slot =
        data['slot']?.toString() ??
            'Time not available';

    final String location =
        data['location']?.toString() ??
            'Location not available';

    final String bloodGroup =
        data['bloodGroup']?.toString() ??
            '';

    final String status =
        data['status']?.toString() ??
            'Upcoming';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    campName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _buildStatusBadge(
                  status,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              date,
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.access_time,
              'Time',
              slot,
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.location_on,
              'Location',
              location,
            ),

            if (bloodGroup.isNotEmpty) ...[
              const SizedBox(height: 10),

              _buildInfoRow(
                Icons.bloodtype,
                'Blood Group',
                bloodGroup,
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 45,
              child:
                  ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingDetailScreen(
                        bookingId:
                            bookingId,
                      ),
                    ),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      blue,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            10),
                  ),
                ),
                child:
                    const Text(
                  'View Booking Details',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: blue,
        ),

        const SizedBox(width: 10),

        Text(
          '$title: ',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String status,
  ) {
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'checked in':
      case 'screening passed':
      case 'passed':
        statusColor =
            Colors.green;
        break;

      case 'completed':
        statusColor =
            Colors.teal;
        break;

      case 'cancelled':
        statusColor = red;
        break;

      case 'no-show':
        statusColor =
            Colors.grey;
        break;

      default:
        statusColor = blue;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            statusColor.withOpacity(
                0.1),
        borderRadius:
            BorderRadius.circular(
                20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    List<String> statuses,
  ) {
    String title;
    String message;

    if (statuses.contains(
        'Upcoming')) {
      title =
          'No Upcoming Bookings';
      message =
          'You have no upcoming blood camp bookings.';
    } else if (statuses.contains(
        'Confirmed')) {
      title =
          'No Check-in Yet';
      message =
          'Your confirmed check-ins will appear here.';
    } else {
      title =
          'No Completed Donations';
      message =
          'Your completed donations will appear here.';
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 75,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}