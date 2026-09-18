import 'package:cloud_firestore/cloud_firestore.dart';

class WalkInDonorsFirestore {
  static final CollectionReference walkInDonors =
      FirebaseFirestore.instance.collection('walk_in_donors');

  static Future<void> addWalkInDonor({
    required String donorName,
    required String email,
    required String phone,
    required int age,
    required String gender,
    required String bloodGroup,
    required String campId,
    required String registeredByStaff,
    required String status,
    required String medicalCondition,
  }) async {
    await walkInDonors.add({
      'donorName': donorName,
      'email': email,
      'phone': phone,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'campId': campId,
      'registrationDateTime':
          FieldValue.serverTimestamp(),
      'registeredByStaff': registeredByStaff,
      'status': status,
      'medicalCondition': medicalCondition,
    });
  }
}