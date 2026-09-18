
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoDataService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SEED DEMO DATA
  // ============================================================

  Future<void> seedDemoData() async {
    // ---------------- CAMPS ----------------

    final camp1 = _firestore.collection('camps').doc();

    await camp1.set({
      'name': 'Alkhidmat Blood Camp',
      'location': 'Rawalpindi',
      'date': '2026-09-25',
      'startTime': '10:00 AM',
      'endTime': '04:00 PM',
      'slotLimit': 50,
      'status': 'Upcoming',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final camp2 = _firestore.collection('camps').doc();

    await camp2.set({
      'name': 'Bano Qabil Blood Drive',
      'location': 'Islamabad',
      'date': '2026-09-28',
      'startTime': '09:00 AM',
      'endTime': '03:00 PM',
      'slotLimit': 40,
      'status': 'Upcoming',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ---------------- BOOKINGS ----------------

    await _firestore.collection('bookings').add({
      'donorName': 'Ali Khan',
      'phone': '03001234567',
      'bloodGroup': 'A+',
      'campName': 'Alkhidmat Blood Camp',
      'slot': '10:00 AM',
      'status': 'Confirmed',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('bookings').add({
      'donorName': 'Sara Ahmed',
      'phone': '03007654321',
      'bloodGroup': 'O+',
      'campName': 'Bano Qabil Blood Drive',
      'slot': '11:00 AM',
      'status': 'Confirmed',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ---------------- DONATIONS ----------------

    await _firestore.collection('donations').add({
      'donorName': 'Ali Khan',
      'bloodGroup': 'A+',
      'units': 1,
      'campName': 'Alkhidmat Blood Camp',
      'date': '2026-09-10',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('donations').add({
      'donorName': 'Sara Ahmed',
      'bloodGroup': 'O+',
      'units': 1,
      'campName': 'Bano Qabil Blood Drive',
      'date': '2026-09-12',
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CLEAR DEMO DATA
  // ============================================================

  Future<void> clearDemoData() async {
    await _deleteDemoCollection('camps');
    await _deleteDemoCollection('bookings');
    await _deleteDemoCollection('donations');
  }

  // Delete only documents where isDemo == true
  Future<void> _deleteDemoCollection(
    String collectionName,
  ) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('isDemo', isEqualTo: true)
        .get();

    for (final document in snapshot.docs) {
      await document.reference.delete();
    }
  }
  }

