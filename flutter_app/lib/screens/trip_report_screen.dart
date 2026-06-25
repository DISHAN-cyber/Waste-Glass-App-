import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class TripReportScreen extends StatefulWidget {
  final List<Supplier> suppliers;

  const TripReportScreen({super.key, required this.suppliers});

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
  List<CollectionRecord> _records = [];
  bool _loading = true;
  bool _syncing = false;
  bool _synced = false;
  String? _syncError;
  DateTime? _tripStart;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = LocalDbService();
    final records = await db.getAllRecords();
    final startTime = await db.getTripStartTime();
    setState(() {
      _records = records;
      _tripStart = startTime;
      _loading = false;
    });
  }

  double get _totalKg {
    return _records.fold(0, (sum, r) => sum + r.clearKg + r.colouredKg);
  }

  double get _totalDistance {
    return widget.suppliers.fold(0, (sum, s) => sum + s.distanceFromPrev);
  }

  Duration get _tripDuration {
    if (_tripStart == null) return Duration.zero;
    return DateTime.now().difference(_tripStart!);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Future<void> _syncToServer() async {
    setState(() { _syncing = true; _syncError = null; });
    try {
      final unsynced = await LocalDbService().getUnsyncedRecords();
      await ApiService.syncAll(unsynced);
      await LocalDbService().markAllSynced();
      setState(() { _synced = true; _syncing = false; });
    } catch (e) {
      setState(() {
        _syncError = 'Sync failed. Data is safe locally.\n${e.toString()}';
        _syncing = false;
      });
    }
  }

  SupplierSummary? _summaryFor(Supplier supplier) {
    final record = _records.where((r) => r.supplierId == supplier.id).firstOrNull;
    if (record == null) return null;
    final collected = record.clearKg + record.colouredKg;
    return SupplierSummary(
      supplierId: supplier.id,
      supplierName: supplier.name,
      expectedKg: supplier.expectedKg,
      collectedKg: collected,
      hasShortfall: collected < supplier.expectedKg,
      condition: record.condition,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Trip Report',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTripStats(),
                  const SizedBox(height: 16),
                  _buildSyncCard(),
                  const SizedBox(height: 16),
                  _buildSupplierList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTripStats() {
    final shortfalls = widget.suppliers
        .map(_summaryFor)
        .whereType<SupplierSummary>()
        .where((s) => s.hasShortfall)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Complete',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            _formatDuration(_tripDuration),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBox('${_totalKg.toStringAsFixed(1)} kg', 'Collected'),
              const SizedBox(width: 10),
              _statBox('${_totalDistance.toStringAsFixed(1)} km', 'Distance'),
              const SizedBox(width: 10),
              _statBox('${widget.suppliers.length}', 'Stops'),
              if (shortfalls > 0) ...[
                const SizedBox(width: 10),
                _statBox('$shortfalls', 'Shortfalls', isWarning: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, {bool isWarning = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isWarning
              ? Colors.orange.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: isWarning ? Colors.orange.shade200 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard() {
    if (_synced) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Synced successfully',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.green)),
                  Text('All records saved to server.',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_upload, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text('Sync to Server',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Push all collected records to the backend to confirm they are saved.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (_syncError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_syncError!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _syncing ? null : _syncToServer,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Syncing...' : 'Sync to Server',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Collection Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...widget.suppliers.map((s) {
          final summary = _summaryFor(s);
          return _buildSupplierCard(s, summary);
        }),
      ],
    );
  }

  Widget _buildSupplierCard(Supplier supplier, SupplierSummary? summary) {
    final hasShortfall = summary?.hasShortfall ?? false;
    final notCollected = summary == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasShortfall
              ? Colors.orange.shade300
              : notCollected
                  ? Colors.red.shade200
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(supplier.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (hasShortfall)
                _warningBadge('Shortfall')
              else if (notCollected)
                _warningBadge('Not collected', color: Colors.red)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Complete',
                      style:
                          TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (summary != null) ...[
            Row(
              children: [
                _detailItem('Clear', '${summary.collectedKg.toStringAsFixed(1)} kg'),
                _detailItem('Expected', '${summary.expectedKg.toStringAsFixed(1)} kg'),
                _detailItem('Condition', summary.condition),
              ],
            ),
            if (hasShortfall) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Short by ${(summary.expectedKg - summary.collectedKg).toStringAsFixed(1)} kg',
                  style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ] else ...[
            const Text('No collection recorded for this stop.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _warningBadge(String text, {Color color = Colors.orange}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
