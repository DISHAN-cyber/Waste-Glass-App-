import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'scan_collect_screen.dart';

class TripSequenceScreen extends StatefulWidget {
  const TripSequenceScreen({super.key});

  @override
  State<TripSequenceScreen> createState() => _TripSequenceScreenState();
}

class _TripSequenceScreenState extends State<TripSequenceScreen> {
  List<Supplier> _suppliers = [];
  bool _loading = true;
  String? _error;
  double _totalDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suppliers = await ApiService.getRoute();
      await LocalDbService().saveTripStart(DateTime.now());
      double total = 0;
      for (final s in suppliers) {
        total += s.distanceFromPrev;
      }
      setState(() {
        _suppliers = suppliers;
        _totalDistance = total;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _remainingStops =>
      _suppliers.where((s) => s.status != 'Collected').length;

  int get _currentStopIndex => _suppliers.indexWhere((s) => s.status == 'Next');

  Color _statusColor(String status) {
    switch (status) {
      case 'Collected':
        return Colors.green;
      case 'Next':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Collected':
        return Icons.check_circle;
      case 'Next':
        return Icons.navigation;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Today\'s Route',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoute,
            tooltip: 'Refresh route',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _suppliers.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Could not load route',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRoute,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildStatsRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRoute,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _suppliers.length,
              itemBuilder: (context, index) =>
                  _buildStopCard(_suppliers[index], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          _statChip(Icons.route, '${_totalDistance.toStringAsFixed(1)} km',
              'Total distance'),
          const SizedBox(width: 16),
          _statChip(Icons.location_on, '$_remainingStops', 'Stops remaining'),
          const SizedBox(width: 16),
          _statChip(Icons.inventory_2, '${_suppliers.length}', 'Total stops'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1565C0)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(Supplier supplier, int index) {
  final isNext = supplier.status == 'Next';
  final isCollected = supplier.status == 'Collected';

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isNext ? const Color(0xFF1565C0) : Colors.grey.shade200,
        width: isNext ? 2 : 1,
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isCollected
            ? Colors.green.shade50
            : isNext
                ? const Color(0xFFE3F2FD)
                : Colors.grey.shade100,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _statusColor(supplier.status),
          ),
        ),
      ),
      title: Text(
        supplier.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: isCollected ? TextDecoration.lineThrough : null,
          color: isCollected ? Colors.grey : Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(supplier.address,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              _pill('${supplier.expectedKg} kg expected',
                  Colors.orange.shade100, Colors.orange.shade800),
              const SizedBox(width: 6),
              if (supplier.distanceFromPrev > 0)
                _pill('${supplier.distanceFromPrev.toStringAsFixed(1)} km',
                    Colors.grey.shade100, Colors.grey.shade700),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_statusIcon(supplier.status),
              color: _statusColor(supplier.status)),
          const SizedBox(height: 2),
          Text(
            supplier.status,
            style: TextStyle(
              fontSize: 10,
              color: _statusColor(supplier.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onTap: () => _goToScan(supplier),  // ✅ CHANGED: Now any supplier can be tapped!
    ),
  );
}

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBottomBar() {
    final nextIndex = _currentStopIndex;
    if (nextIndex == -1 && _remainingStops == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushNamed(context, '/report'),
          icon: const Icon(Icons.summarize),
          label: const Text('View Trip Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }
    if (nextIndex == -1) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _goToScan(_suppliers[nextIndex]),
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(
          'Scan Next: ${_suppliers[nextIndex].name}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _goToScan(Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanCollectScreen(
          supplier: supplier,
          onCollected: () {
            _loadRoute();
          },
        ),
      ),
    );
  }
}
