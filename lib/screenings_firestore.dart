import 'package:cloud_firestore/cloud_firestore.dart';

class ScreeningsFirestore {
  static final CollectionReference screenings =
      FirebaseFirestore.instance.collection('screenings');

  static Future<void> addScreening({
    required String donorId,
    required String bookingId,
    required String campId,
    required int age,
    required double weight,
    required dynamic lastDonationDate,
    required bool feelingWell,
    required String screeningStatus,
    required String reason,
    required String staffId,
    required String screeningShift,
  }) async {
    await screenings.add({
      'donorId': donorId,
      'bookingId': bookingId,
      'campId': campId,
      'age': age,
      'weight': weight,
      'lastDonationDate': lastDonationDate,
      'feelingWell': feelingWell,
      'screeningStatus': screeningStatus,
      'reason': reason,
      'staffId': staffId,
      'screeningDateTime': FieldValue.serverTimestamp(),
      'screeningShift': screeningShift,
    });
  }
}
