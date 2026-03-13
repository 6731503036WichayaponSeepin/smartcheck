import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  final _courseCtrl = TextEditingController(text: '1305216');
  final _roomCtrl = TextEditingController(text: 'Room-1');
  final _topicCtrl = TextEditingController(text: 'Mobile App Dev');
  DateTime _date = DateTime.now();

  String? _sessionCode;
  bool _saving = false;

  String _buildSessionCode() {
    // simple + readable
    final y = _date.year.toString().padLeft(4, '0');
    final m = _date.month.toString().padLeft(2, '0');
    final d = _date.day.toString().padLeft(2, '0');

    // include minute to reduce collisions
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return '${_courseCtrl.text.trim()}_${y}${m}${d}_${hh}${mm}_${_roomCtrl.text.trim()}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _generate() async {
    final course = _courseCtrl.text.trim();
    final room = _roomCtrl.text.trim();
    if (course.isEmpty || room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course and Room are required')));
      return;
    }

    final code = _buildSessionCode();
    setState(() => _sessionCode = code);

    // optional: save session to Firestore so you can audit later
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('classSessions').doc(code).set({
        'sessionCode': code,
        'courseId': course,
        'room': room,
        'topic': _topicCtrl.text.trim(),
        'date': Timestamp.fromDate(_date),
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created and saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firestore error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Instructor - Show QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Create class session QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _courseCtrl,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Course ID (e.g. 1305216)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomCtrl,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Room (e.g. Lab-401)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Topic (optional)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Date: $dateText')),
              TextButton(onPressed: _pickDate, child: const Text('Pick date')),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saving ? null : _generate,
            icon: const Icon(Icons.qr_code),
            label: Text(_saving ? 'Generating...' : 'Generate QR'),
          ),
          const SizedBox(height: 16),
          if (_sessionCode != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: _sessionCode!,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'SessionCode: $_sessionCode',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Students should scan this QR for Check-in and Finish Class.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}