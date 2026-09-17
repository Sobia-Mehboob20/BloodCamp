import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'thank_you_card_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),

        foregroundColor: Colors.white,

        title: const Text(
          'Booking Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),

        builder: (context, snapshot) {
          // ----------------------------------------------------
          // LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load booking.'));
          }

          // ----------------------------------------------------
          // BOOKING NOT FOUND
          // ----------------------------------------------------

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Booking not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String campName = data['campName']?.toString() ?? 'Blood Camp';

          final String date = data['date']?.toString() ?? '';

          final String slot = data['slot']?.toString() ?? '';

          final String location = data['location']?.toString() ?? '';

          final String donorName = data['donorName']?.toString() ?? '';

          final String bloodGroup =
              data['bloodGroup']?.toString() ?? 'Not added';

          final String phone = data['donorPhone']?.toString() ?? '';

          final String status = data['status']?.toString() ?? 'Upcoming';

          // ----------------------------------------------------
          // SCREEN
          // ----------------------------------------------------

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // STATUS CARD
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FF),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.bloodtype,
                        color: Color(0xFFE51C2A),
                        size: 55,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        campName,
                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _statusBadge(context, status, bookingId),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // CAMP INFORMATION
                // =================================================
                _detailCard(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: date,
                ),

                _detailCard(
                  icon: Icons.access_time,
                  title: 'Time Slot',
                  value: slot,
                ),

                _detailCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  value: location,
                ),

                const SizedBox(height: 8),

                // =================================================
                // DONOR INFORMATION
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Donor Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _donorRow(Icons.person, 'Name', donorName),

                      _donorRow(Icons.bloodtype, 'Blood Group', bloodGroup),

                      _donorRow(Icons.phone, 'Phone', phone),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // BOOKING ID
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Booking ID',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),

                      const SizedBox(height: 5),

                      SelectableText(
                        bookingId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // CANCEL BOOKING
                // =================================================
                if (status == 'Upcoming')
                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: OutlinedButton(
                      onPressed: () {
                        _showCancelDialog(context);
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE51C2A),

                        side: const BorderSide(color: Color(0xFFE51C2A)),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Cancel Booking',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(BuildContext context, String status, String bookingId) {
    Color color;

    if (status == 'Completed') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ThankYouCardScreen(bookingId: bookingId),
              ),
            );
          },
          icon: const Icon(Icons.favorite),
          label: const Text(
            'View Thank You Card',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE51C2A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    } else if (status == 'Checked in') {
      color = Colors.orange;
    } else if (status == 'Cancelled') {
      color = Colors.red;
    } else if (status == 'No-show') {
      color = Colors.grey;
    } else {
      color = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL CARD
  // ============================================================

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 25),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
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

  // ============================================================
  // DONOR ROW
  // ============================================================

  Widget _donorRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 22),

          const SizedBox(width: 12),

          Text(
            '$title: ',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          Expanded(
            child: Text(
              value.isEmpty ? 'Not added' : value,

              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCEL DIALOG
  // ============================================================

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Booking?'),

          content: const Text('Are you sure you want to cancel this booking?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('No'),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _cancelBooking(context);
              },

              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Color(0xFFE51C2A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CANCEL BOOKING
  // ============================================================
  Future<void> _cancelBooking(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final bookingReference = firestore.collection('bookings').doc(bookingId);

      final bookingSnapshot = await bookingReference.get();

      if (!bookingSnapshot.exists) {
        return;
      }

      final bookingData = bookingSnapshot.data();

      final String campId = bookingData?['campId']?.toString() ?? '';

      final String donorId = bookingData?['donorId']?.toString() ?? '';

      final String campName =
          bookingData?['campName']?.toString() ?? 'Blood Camp';

      final campReference = firestore.collection('camps').doc(campId);

      await firestore.runTransaction((transaction) async {
        final bookingSnapshot = await transaction.get(bookingReference);

        if (!bookingSnapshot.exists) {
          return;
        }

        final data = bookingSnapshot.data() as Map<String, dynamic>;

        if (data['status'] != 'Upcoming') {
          return;
        }

        final campSnapshot = await transaction.get(campReference);

        int bookedSlots = 0;

        if (campSnapshot.exists) {
          final campData = campSnapshot.data() as Map<String, dynamic>;

          bookedSlots =
              int.tryParse(campData['bookedSlots']?.toString() ?? '0') ?? 0;
        }

        if (bookedSlots > 0) {
          bookedSlots--;
        }

        transaction.update(bookingReference, {'status': 'Cancelled'});

        if (campSnapshot.exists) {
          transaction.update(campReference, {'bookedSlots': bookedSlots});
        }
      });

      // --------------------------------------------------------
      // CREATE CANCELLATION NOTIFICATION
      // --------------------------------------------------------

      await firestore.collection('notifications').add({
        'userId': donorId,
        'title': 'Booking Cancelled',
        'message': 'Your booking for $campName has been cancelled.',
        'type': 'cancellation',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel booking.')),
      );
    }
  }
}
