import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color blue = Color(0xFF1565C0);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color red = Color(0xFFE51C2A);

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login first.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // NOTIFICATIONS
      // ============================================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),

        builder: (context, snapshot) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load notifications.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            );
          }

          // ========================================================
          // NO NOTIFICATIONS
          // ========================================================

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 70, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'You are all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ========================================================
          // GET NOTIFICATIONS
          // ========================================================

          final notifications = [...snapshot.data!.docs];

          // Sort newest first inside Flutter.
          notifications.sort((a, b) {
            final Timestamp? aTime = a.data()['createdAt'] as Timestamp?;

            final Timestamp? bTime = b.data()['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(aTime);
          });

          // ========================================================
          // LIST
          // ========================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final document = notifications[index];

              final data = document.data();

              final String title = data['title']?.toString() ?? 'Notification';

              final String message = data['message']?.toString() ?? '';

              final String type = data['type']?.toString() ?? 'general';

              final bool isRead = data['isRead'] == true;

              DateTime? createdAt;

              if (data['createdAt'] is Timestamp) {
                createdAt = (data['createdAt'] as Timestamp).toDate();
              }

              return _buildNotificationCard(
                context: context,
                documentId: document.id,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: createdAt,
                blue: blue,
                darkBlue: darkBlue,
                red: red,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard({
    required BuildContext context,
    required String documentId,
    required String title,
    required String message,
    required String type,
    required bool isRead,
    required DateTime? createdAt,
    required Color blue,
    required Color darkBlue,
    required Color red,
  }) {
    IconData icon;
    Color iconColor;

    if (type == 'booking') {
      icon = Icons.check_circle;
      iconColor = blue;
    } else if (type == 'reminder') {
      icon = Icons.access_time;
      iconColor = Colors.orange;
    } else if (type == 'cancellation') {
      icon = Icons.cancel;
      iconColor = red;
    } else if (type == 'donation') {
      icon = Icons.favorite;
      iconColor = red;
    } else if (type == 'health') {
      icon = Icons.health_and_safety;
      iconColor = Colors.green;
    } else {
      icon = Icons.notifications;
      iconColor = blue;
    }

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          try {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(documentId)
                .update({'isRead': true});
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unable to mark notification as read: $e'),
                ),
              );
            }
          }
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEAF3FF),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: isRead ? const Color(0xFFE0E0E0) : blue,
            width: isRead ? 1 : 1.2,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              height: 48,
              width: 48,

              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: iconColor, size: 26),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // TEXT
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: darkBlue,
                            fontSize: 16,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),
                      ),

                      // UNREAD DOT
                      if (!isRead)
                        Container(
                          height: 9,
                          width: 9,

                          decoration: BoxDecoration(
                            color: blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (createdAt != null)
                    Text(
                      _formatDateTime(createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE AND TIME
  // ============================================================

  static String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    final String hour = date.hour.toString().padLeft(2, '0');

    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }
}
