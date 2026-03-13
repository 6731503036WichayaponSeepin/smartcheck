import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'checkin_page.dart';
import 'finish_class_page.dart';
import 'instructor_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // กัน null 100% (กรณี auth state ยังไม่พร้อม/หลุด session)
    if (user == null) {
      return const LoginPage();
    }

    final uid = user.uid;
    final email = user.email ?? '';
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCheck - Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Logged in as: $email', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CheckInPage(studentId: uid)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Check-in'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FinishClassPage(studentId: uid)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Finish Class'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InstructorPage()),
                ),
                icon: const Icon(Icons.school),
                label: const Text('Instructor QR'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('My Attendance Records', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.myRecordsStream(uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Text('No records yet.');

              String fmtTs(dynamic ts) {
                if (ts == null) return '-';
                if (ts is Timestamp) return ts.toDate().toString();
                return ts.toString();
              }

              return Column(
                children: docs.map((d) {
                  final m = d.data();
                  final sessionCode = (m['sessionCode'] ?? '-') as String;
                  final checkInAt = m['checkInAt'];
                  final finishAt = m['finishAt'];
                  final status = (finishAt == null) ? 'IN PROGRESS' : 'DONE';

                  return Card(
                    child: ListTile(
                      title: Text('$sessionCode [$status]'),
                      subtitle: Text('checkInAt: ${fmtTs(checkInAt)}\nfinishAt: ${fmtTs(finishAt)}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}