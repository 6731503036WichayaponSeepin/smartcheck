import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class LocalStorageService {
  static const _recordsKey = 'attendance_records_v1';
  static const _studentIdKey = 'student_id_v1';

  Future<void> saveStudentId(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentIdKey, studentId.trim());
  }

  Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_studentIdKey);
  }

  Future<List<AttendanceRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final records = list.map(AttendanceRecord.fromMap).toList();

    // sort latest first by updatedAt
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  Future<void> upsertRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();

    final idx = records.indexWhere((r) => r.studentId == record.studentId && r.sessionCode == record.sessionCode);
    if (idx >= 0) {
      records[idx] = record;
    } else {
      records.add(record);
    }

    // keep sorted
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final encoded = jsonEncode(records.map((e) => e.toMap()).toList());
    await prefs.setString(_recordsKey, encoded);
  }

  Future<AttendanceRecord?> findOpenRecordBySession({
    required String studentId,
    required String sessionCode,
  }) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere(
        (r) => r.studentId == studentId && r.sessionCode == sessionCode && r.finishAt == null,
      );
    } catch (_) {
      return null;
    }
  }
}