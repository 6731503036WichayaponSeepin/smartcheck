import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_record.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';
import 'qr_scan_page.dart';

class CheckInPage extends StatefulWidget {
  final String studentId;
  const CheckInPage({super.key, required this.studentId});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final _formKey = GlobalKey<FormState>();

  final _prevCtrl = TextEditingController();
  final _expectCtrl = TextEditingController();

  int _mood = 3;
  String? _sessionCode;

  double? _lat;
  double? _lng;
  DateTime? _time;

  bool _saving = false;

  final _loc = LocationService();
  final _local = LocalStorageService();
  final _fs = FirestoreService();

  Future<void> _getLocation() async {
    try {
      final pos = await _loc.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _time = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _sessionCode = result.trim());
    }
  }

  Future<void> _submit() async {
    if (_lat == null || _lng == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please get GPS location first.')));
      return;
    }
    if (_sessionCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please scan QR code first.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: const Uuid().v4(),
        studentId: widget.studentId,
        sessionCode: _sessionCode!,
        checkInAt: _time,
        checkInLat: _lat,
        checkInLng: _lng,
        previousTopic: _prevCtrl.text.trim(),
        expectedTopic: _expectCtrl.text.trim(),
        moodBefore: _mood,
        finishAt: null,
        finishLat: null,
        finishLng: null,
        learnedToday: null,
        feedback: null,
        createdAt: now,
        updatedAt: now,
      );

      // Save local
      await _local.upsertRecord(record);

      // Save firestore
      await _fs.upsertAttendance(record);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in saved (Local + Firebase).')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in (Before Class)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: _getLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Get GPS Location'),
          ),
          const SizedBox(height: 8),
          Text('lat: ${_lat?.toStringAsFixed(6) ?? "-"}'),
          Text('lng: ${_lng?.toStringAsFixed(6) ?? "-"}'),
          Text('time: ${_time?.toIso8601String() ?? "-"}'),
          const Divider(height: 24),
          ElevatedButton.icon(
            onPressed: _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Class QR'),
          ),
          const SizedBox(height: 8),
          Text('sessionCode: ${_sessionCode ?? "-"}'),
          const Divider(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _prevCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'What topic was covered in the previous class?',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _expectCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'What topic do you expect to learn today?',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _mood,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mood before class (1-5)',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Very negative')),
                    DropdownMenuItem(value: 2, child: Text('2 - Negative')),
                    DropdownMenuItem(value: 3, child: Text('3 - Neutral')),
                    DropdownMenuItem(value: 4, child: Text('4 - Positive')),
                    DropdownMenuItem(value: 5, child: Text('5 - Very positive')),
                  ],
                  onChanged: (v) => setState(() => _mood = v ?? 3),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Saving...' : 'Submit Check-in'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}