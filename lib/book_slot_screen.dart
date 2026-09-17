import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookSlotScreen extends StatefulWidget {
  final String campId;
  final String campName;
  final String date;
  final String location;
  final String startTime;
  final String endTime;
  final String slotCapacity;

  const BookSlotScreen({
    super.key,
    required this.campId,
    required this.campName,
    required this.date,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.slotCapacity,
  });

  @override
  State<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String? selectedSlot;

  bool isBooking = false;

  // Available time slots
  final List<String> timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
  ];

  // ============================================================
  // BOOK SLOT
  // ============================================================

  Future<void> bookSlot() async {
    // ----------------------------------------------------------
    // CHECK SLOT
    // ----------------------------------------------------------

    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a time slot.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CHECK LOGIN
    // ----------------------------------------------------------

    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login first.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      // --------------------------------------------------------
      // CHECK DUPLICATE BOOKING
      // --------------------------------------------------------

     final existingBooking = await _firestore
    .collection('bookings')
    .where(
      'campId',
      isEqualTo: widget.campId,
    )
    .where(
      'donorId',
      isEqualTo: user.uid,
    )
    .where(
      'status',
      isEqualTo: 'Upcoming',
    )
    .get();

      if (existingBooking.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          isBooking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already booked this camp.',
            ),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // GET DONOR PROFILE
      // --------------------------------------------------------

      final userDocument = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final Map<String, dynamic> userData =
          userDocument.data() ?? {};

      // --------------------------------------------------------
      // FIRESTORE REFERENCES
      // --------------------------------------------------------

      final DocumentReference campReference =
          _firestore
              .collection('camps')
              .doc(widget.campId);

      final DocumentReference bookingReference =
          _firestore
              .collection('bookings')
              .doc();

      // --------------------------------------------------------
      // ATOMIC TRANSACTION
      // --------------------------------------------------------

      await _firestore.runTransaction(
        (transaction) async {
          final DocumentSnapshot campSnapshot =
              await transaction.get(campReference);

          if (!campSnapshot.exists) {
            throw Exception(
              'Camp does not exist.',
            );
          }

          final Map<String, dynamic> campData =
              campSnapshot.data()
                  as Map<String, dynamic>;

          // ----------------------------------------------------
          // READ CAPACITY
          // ----------------------------------------------------

          final int totalCapacity =
              int.tryParse(
                    campData['slotCapacity']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          final int bookedSlots =
              int.tryParse(
                    campData['bookedSlots']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;

          // ----------------------------------------------------
          // CHECK CAPACITY
          // ----------------------------------------------------

          if (bookedSlots >= totalCapacity) {
            throw Exception(
              'No slots are available.',
            );
          }

          // ----------------------------------------------------
          // INCREASE BOOKED SLOTS
          // ----------------------------------------------------

          final int newBookedSlots =
              bookedSlots + 1;

          transaction.update(
            campReference,
            {
              'bookedSlots': newBookedSlots,
            },
          );

          // ----------------------------------------------------
          // CREATE BOOKING
          // ----------------------------------------------------

          transaction.set(
            bookingReference,
            {
              'campId': widget.campId,

              'campName': widget.campName,

              'donorId': user.uid,

              'donorName':
                  userData['name'] ?? '',

              'donorEmail':
                  userData['email'] ??
                      user.email ??
                      '',

              'donorPhone':
                  userData['phone'] ?? '',

              'bloodGroup':
                  userData['bloodGroup'] ?? '',

              'slot': selectedSlot,

              'date': widget.date,

              'location':
                  widget.location,

              'status': 'Upcoming',

              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );
         // --------------------------------------------------------
      // CREATE BOOKING NOTIFICATION
      // --------------------------------------------------------

      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': 'Booking Confirmed',
        'message':
            'Your booking for ${widget.campName} has been confirmed.',
        'type': 'booking',
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),

            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Booking Confirmed',
                  ),
                ),
              ],
            ),

            content: Text(
              'Your slot for ${widget.campName} has been booked successfully.',
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      // Return to Camp Details
      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      String message =
          'Booking failed. Please try again.';

      if (e.toString().contains(
        'No slots are available',
      )) {
        message =
            'No slots are available for this camp.';
      }

      if (e.toString().contains(
        'Camp does not exist',
      )) {
        message =
            'This camp no longer exists.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1565C0),

        foregroundColor: Colors.white,

        title: const Text(
          'Book a Slot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // CAMP INFORMATION
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.bloodtype,
                    color: Color(0xFFE51C2A),
                    size: 42,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.campName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // DATE
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 19,
                        color: Color(0xFF1565C0),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          widget.date,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 19,
                        color: Color(0xFF1565C0),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          widget.location,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // TIME
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 19,
                        color: Color(0xFF1565C0),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          '${widget.startTime} - ${widget.endTime}',
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SELECT SLOT
            // ==================================================

            const Text(
              'Select Your Time Slot',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Choose a convenient time for your blood donation.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // TIME SLOT LIST
            // ==================================================

            ...timeSlots.map(
              (slot) {
                final bool isSelected =
                    selectedSlot == slot;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSlot = slot;
                    });
                  },

                  child: Container(
                    width: double.infinity,

                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEAF5FF)
                          : Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      border: Border.all(
                        color: isSelected
                            ? const Color(
                                0xFF1565C0,
                              )
                            : Colors
                                .grey
                                .shade300,

                        width:
                            isSelected ? 2 : 1,
                      ),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons
                                  .radio_button_checked
                              : Icons
                                  .radio_button_off,

                          color: isSelected
                              ? const Color(
                                  0xFF1565C0,
                                )
                              : Colors.grey,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: 15,

                            fontWeight:
                                FontWeight.bold,

                            color: isSelected
                                ? const Color(
                                    0xFF1565C0,
                                  )
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CONFIRM BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed:
                    isBooking ? null : bookSlot,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1565C0),

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),

                child: isBooking
                    ? const SizedBox(
                        width: 23,
                        height: 23,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
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