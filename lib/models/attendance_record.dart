import 'dart:convert';

class AttendanceRecord {
  final String id; // uuid
  final String studentId;
  final String sessionCode;

  // Check-in
  final DateTime? checkInAt;
  final double? checkInLat;
  final double? checkInLng;
  final String? previousTopic;
  final String? expectedTopic;
  final int? moodBefore; // 1..5

  // Finish
  final DateTime? finishAt;
  final double? finishLat;
  final double? finishLng;
  final String? learnedToday;
  final String? feedback;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sessionCode,
    required this.checkInAt,
    required this.checkInLat,
    required this.checkInLng,
    required this.previousTopic,
    required this.expectedTopic,
    required this.moodBefore,
    required this.finishAt,
    required this.finishLat,
    required this.finishLng,
    required this.learnedToday,
    required this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? sessionCode,
    DateTime? checkInAt,
    double? checkInLat,
    double? checkInLng,
    String? previousTopic,
    String? expectedTopic,
    int? moodBefore,
    DateTime? finishAt,
    double? finishLat,
    double? finishLng,
    String? learnedToday,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionCode: sessionCode ?? this.sessionCode,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      previousTopic: previousTopic ?? this.previousTopic,
      expectedTopic: expectedTopic ?? this.expectedTopic,
      moodBefore: moodBefore ?? this.moodBefore,
      finishAt: finishAt ?? this.finishAt,
      finishLat: finishLat ?? this.finishLat,
      finishLng: finishLng ?? this.finishLng,
      learnedToday: learnedToday ?? this.learnedToday,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'sessionCode': sessionCode,
      'checkInAt': checkInAt?.toIso8601String(),
      'checkInLat': checkInLat,
      'checkInLng': checkInLng,
      'previousTopic': previousTopic,
      'expectedTopic': expectedTopic,
      'moodBefore': moodBefore,
      'finishAt': finishAt?.toIso8601String(),
      'finishLat': finishLat,
      'finishLng': finishLng,
      'learnedToday': learnedToday,
      'feedback': feedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static AttendanceRecord fromMap(Map<String, dynamic> map) {
    DateTime? parseDt(dynamic v) => v == null ? null : DateTime.parse(v as String);

    return AttendanceRecord(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      sessionCode: map['sessionCode'] as String,
      checkInAt: parseDt(map['checkInAt']),
      checkInLat: (map['checkInLat'] as num?)?.toDouble(),
      checkInLng: (map['checkInLng'] as num?)?.toDouble(),
      previousTopic: map['previousTopic'] as String?,
      expectedTopic: map['expectedTopic'] as String?,
      moodBefore: map['moodBefore'] as int?,
      finishAt: parseDt(map['finishAt']),
      finishLat: (map['finishLat'] as num?)?.toDouble(),
      finishLng: (map['finishLng'] as num?)?.toDouble(),
      learnedToday: map['learnedToday'] as String?,
      feedback: map['feedback'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());
  static AttendanceRecord fromJson(String s) => fromMap(jsonDecode(s) as Map<String, dynamic>);
}