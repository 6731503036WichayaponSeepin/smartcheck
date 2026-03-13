import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';
import 'qr_scan_page.dart';

class FinishClassPage extends StatefulWidget {
  final String studentId;
  const FinishClassPage({super.key, required this.studentId});

  @override
  State<FinishClassPage> createState() => _FinishClassPageState();
}

class _FinishClassPageState extends State<FinishClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _learnedCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

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
      final sessionCode = _sessionCode!;
      final existing = await _local.findOpenRecordBySession(
        studentId: widget.studentId,
        sessionCode: sessionCode,
      );

      if (existing == null) {
        // MVP behavior: allow creating a finish record even if no check-in found
        // but still store it
        final now = DateTime.now();
        final record = AttendanceRecord(
          id: '${widget.studentId}_$sessionCode',
          studentId: widget.studentId,
          sessionCode: sessionCode,
          checkInAt: null,
          checkInLat: null,
          checkInLng: null,
          previousTopic: null,
          expectedTopic: null,
          moodBefore: null,
          finishAt: _time,
          finishLat: _lat,
          finishLng: _lng,
          learnedToday: _learnedCtrl.text.trim(),
          feedback: _feedbackCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        );

        await _local.upsertRecord(record);
        await _fs.upsertAttendance(record);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Finish saved, but no matching check-in found (created new record).')),
        );
        Navigator.of(context).pop();
        return;
      }

      final updated = existing.copyWith(
        finishAt: _time,
        finishLat: _lat,
        finishLng: _lng,
        learnedToday: _learnedCtrl.text.trim(),
        feedback: _feedbackCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _local.upsertRecord(updated);
      await _fs.upsertAttendance(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish saved (Local + Firebase).')));
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
      appBar: AppBar(title: const Text('Finish Class (After Class)')),
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
            label: const Text('Scan Class QR Again'),
          ),
          const SizedBox(height: 8),
          Text('sessionCode: ${_sessionCode ?? "-"}'),
          const Divider(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _learnedCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'What you learned today (short text)',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _feedbackCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Feedback about the class or instructor',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Saving...' : 'Submit Finish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}