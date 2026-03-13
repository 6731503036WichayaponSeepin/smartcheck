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

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

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

  Widget _statusChip({required IconData icon, required String label, required bool ok}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: ok ? Colors.green : Colors.grey),
      label: Text(label),
      side: BorderSide(color: ok ? Colors.green : Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasGps = _lat != null && _lng != null && _time != null;
    final hasQr = _sessionCode != null && _sessionCode!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class (After Class)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'โครงสร้างข้อมูลสะท้อนการเรียนรู้ (The Reflection Engine)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('หลังเรียน (After Class)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip(icon: Icons.my_location, label: hasGps ? 'GPS ready' : 'GPS not ready', ok: hasGps),
                          _statusChip(icon: Icons.qr_code, label: hasQr ? 'QR scanned' : 'QR not scanned', ok: hasQr),
                          if (hasGps)
                            Chip(
                              label: Text(
                                'lat ${_lat!.toStringAsFixed(5)}, lng ${_lng!.toStringAsFixed(5)}',
                              ),
                            ),
                          if (_time != null) Chip(label: Text('time ${_time!.toIso8601String()}')),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _getLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Get GPS Location'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _scanQr,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan Class QR Again'),
                            ),
                          ),
                        ],
                      ),

                      if (hasQr) ...[
                        const SizedBox(height: 10),
                        SelectableText(
                          'Session: $_sessionCode',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _learnedCtrl,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'สิ่งที่ได้เรียนรู้วันนี้? (Short text)',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _feedbackCtrl,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'ข้อเสนอแนะ (Feedback) ถึงวิชาหรือผู้สอน?',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _submit,
                                icon: const Icon(Icons.save),
                                label: Text(_saving ? 'Saving...' : 'Submit Finish'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}