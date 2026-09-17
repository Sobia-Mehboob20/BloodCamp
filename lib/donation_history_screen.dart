import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  final Color blue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color red = const Color(0xFFE51C2A);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: blue,
        foregroundColor: Colors.white,
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where(
              'donorId',
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: blue,
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final donations = snapshot.data?.docs ?? [];

          // Empty
          if (donations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];

              final data =
                  donation.data() as Map<String, dynamic>;

              return _buildDonationCard(data);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // DONATION CARD
  // ============================================================

  Widget _buildDonationCard(
    Map<String, dynamic> data,
  ) {
    final String campName =
        data['campName']?.toString() ??
            'Blood Camp';

    final String bloodGroup =
        data['bloodGroup']?.toString() ??
            'Not available';

    final String bagNumber =
        data['bagNumber']?.toString() ??
            'Not available';

    final String status =
        data['status']?.toString() ??
            'Completed';

    String donationDate = 'Date not available';

    final dateValue = data['donationDate'];

    if (dateValue is Timestamp) {
      final date = dateValue.toDate();

      donationDate =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } else if (dateValue != null) {
      donationDate = dateValue.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.bloodtype,
                    color: red,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    campName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),

                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // DONATION DATE
            // ----------------------------------------------------

            _buildInfoRow(
              Icons.calendar_today,
              'Donation Date',
              donationDate,
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // BLOOD GROUP
            // ----------------------------------------------------

            _buildInfoRow(
              Icons.bloodtype,
              'Blood Group',
              bloodGroup,
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // BAG NUMBER
            // ----------------------------------------------------

            _buildInfoRow(
              Icons.inventory_2,
              'Bag Number',
              bagNumber,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: blue,
        ),

        const SizedBox(width: 10),

        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;

      case 'confirmed':
        statusColor = Colors.orange;
        break;

      default:
        statusColor = blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            Text(
              'No Donation History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Your completed blood donations '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}