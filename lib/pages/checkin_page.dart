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

  @override
  void dispose() {
    _prevCtrl.dispose();
    _expectCtrl.dispose();
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

  String _moodText(int v) {
    switch (v) {
      case 1:
        return '1 = แย่มาก (Very negative)';
      case 2:
        return '2 = แย่ (Negative)';
      case 3:
        return '3 = เฉยๆ (Neutral)';
      case 4:
        return '4 = ดี (Positive)';
      case 5:
        return '5 = ดีมาก (Very positive)';
      default:
        return '$v';
    }
  }

  Color _moodColor(int v, ColorScheme cs) {
    switch (v) {
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.deepOrange;
      default:
        return cs.primary;
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
      appBar: AppBar(
        title: const Text('Check-in (Before Class)'),
      ),
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
                      Text('ก่อนเรียน (Before Class)',
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
                              label: const Text('Scan Class QR'),
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
                              controller: _prevCtrl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'หัวข้อที่เรียนในคาบที่แล้ว?',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _expectCtrl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'หัวข้อที่คาดหวังว่าจะได้เรียนในวันนี้?',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),

                            Text('อารมณ์ของคุณก่อนเรียนเป็นอย่างไร?', style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _moodColor(_mood, cs),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_moodText(_mood), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Slider(
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    value: _mood.toDouble(),
                                    onChanged: _saving ? null : (v) => setState(() => _mood = v.round()),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('1'),
                                      Text('2'),
                                      Text('3'),
                                      Text('4'),
                                      Text('5'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _submit,
                                icon: const Icon(Icons.save),
                                label: Text(_saving ? 'Saving...' : 'Submit Check-in'),
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