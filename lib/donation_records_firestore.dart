import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRecordsFirestore {
  static final CollectionReference donations =
      FirebaseFirestore.instance.collection('donations');

  static Future<void> addDonation({
    required String donorId,
    required String bookingId,
    required String campId,
    required String bloodGroup,
    required String bagNumber,
    required String donationStatus,
    required String staffId,
    required String notes,
  }) async {
    await donations.add({
      'donorId': donorId,
      'bookingId': bookingId,
      'campId': campId,
      'bloodGroup': bloodGroup,
      'bagNumber': bagNumber,
      'donationDateTime': FieldValue.serverTimestamp(),
      'donationStatus': donationStatus,
      'staffId': staffId,
      'notes': notes,
    });
  }
}