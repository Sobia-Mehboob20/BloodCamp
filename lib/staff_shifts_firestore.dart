import 'package:cloud_firestore/cloud_firestore.dart';

class StaffShiftsFirestore {
  static final CollectionReference staffShifts =
      FirebaseFirestore.instance.collection('staff_shifts');

  static Future<void> addShift({
    required String staffId,
    required String campId,
    required int registeredDonors,
    required int checkedInDonors,
    required int completedDonations,
    required int deferredDonors,
    required int walkInDonors,
    required int pendingScreenings,
    required int pendingDonationRecords,
    required String staffNotes,
  }) async {
    await staffShifts.add({
      'staffId': staffId,
      'campId': campId,
      'registeredDonors': registeredDonors,
      'checkedInDonors': checkedInDonors,
      'completedDonations': completedDonations,
      'deferredDonors': deferredDonors,
      'walkInDonors': walkInDonors,
      'pendingScreenings': pendingScreenings,
      'pendingDonationRecords': pendingDonationRecords,
      'staffNotes': staffNotes,
      'endShiftTime': FieldValue.serverTimestamp(),
    });
  }
}