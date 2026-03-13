import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _docId(String uid, String sessionCode) => '${uid}_$sessionCode';

  Future<void> createUserProfile({
  required String uid,
  required String email,
  required String displayName,
}) async {
  await _db.collection('users').doc(uid).set({
    'email': email,
    'displayName': displayName,
    'createdAt': Timestamp.now(),
  });
}

  Future<void> upsertAttendance(AttendanceRecord r) async {
    await _db.collection('attendanceRecords').doc(_docId(r.studentId, r.sessionCode)).set({
      'id': r.id,
      'studentId': r.studentId,
      'sessionCode': r.sessionCode,

      'checkInAt': r.checkInAt == null ? null : Timestamp.fromDate(r.checkInAt!),
      'checkInLat': r.checkInLat,
      'checkInLng': r.checkInLng,
      'previousTopic': r.previousTopic,
      'expectedTopic': r.expectedTopic,
      'moodBefore': r.moodBefore,

      'finishAt': r.finishAt == null ? null : Timestamp.fromDate(r.finishAt!),
      'finishLat': r.finishLat,
      'finishLng': r.finishLng,
      'learnedToday': r.learnedToday,
      'feedback': r.feedback,

      'createdAt': Timestamp.fromDate(r.createdAt),
      'updatedAt': Timestamp.fromDate(r.updatedAt),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myRecordsStream(String uid) {
    return _db
        .collection('attendanceRecords')
        .where('studentId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}