import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class ScanCollectScreen extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onCollected;

  const ScanCollectScreen({
    super.key,
    required this.supplier,
    required this.onCollected,
  });

  @override
  State<ScanCollectScreen> createState() => _ScanCollectScreenState();
}

class _ScanCollectScreenState extends State<ScanCollectScreen> {
  bool _scanned = false;
  bool _formUnlocked = false;
  bool _submitting = false;
  bool _cameraReady = false;
  String? _scanError;

  final _clearKgController = TextEditingController();
  final _colouredKgController = TextEditingController();
  String _condition = 'Good';
  final _formKey = GlobalKey<FormState>();

  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    
    if (status != PermissionStatus.granted) {
      setState(() {
        _scanError = 'Camera permission denied. Please enable it in Settings.';
      });
      return;
    }

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    setState(() {
      _cameraReady = true;
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _clearKgController.dispose();
    _colouredKgController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final scannedId = barcode.rawValue!.trim();
    final expectedId = widget.supplier.id.trim();

    setState(() { _scanned = true; });
    _scannerController?.stop();

    if (scannedId == expectedId) {
      setState(() {
        _formUnlocked = true;
        _scanError = null;
      });
    } else {
      setState(() {
        _scanError = 'Wrong supplier!\nScanned: $scannedId\nExpected: $expectedId';
        _scanned = false;
      });
      _scannerController?.start();
    }
  }

  Future<void> _submitCollection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; });

    final record = CollectionRecord(
      supplierId: widget.supplier.id,
      clearKg: double.parse(_clearKgController.text),
      colouredKg: double.parse(_colouredKgController.text),
      condition: _condition,
      timestamp: DateTime.now(),
    );

    await LocalDbService().saveCollection(record);

    try {
      await ApiService.submitCollection(record);
    } catch (e) {
      debugPrint('Backend post failed, saved locally: $e');
    }

    setState(() { _submitting = false; });
    widget.onCollected();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.supplier.name} collected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.supplier.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDestinationCard(),
            const SizedBox(height: 16),
            _formUnlocked ? _buildCollectionForm() : _buildScannerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('Current stop',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.supplier.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.supplier.address,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip('${widget.supplier.expectedKg} kg expected', Icons.scale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Text('Scan Supplier Barcode',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 260,
                  child: _cameraReady
                      ? Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerController!,
                              onDetect: _onBarcodeDetected,
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  margin: const EdgeInsets.all(60),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Point camera at barcode for Supplier ID: ${widget.supplier.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (_scanError != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_scanError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Barcode verified! Enter collection details for ${widget.supplier.name}.',
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          _buildFormCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : _submitCollection,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(
                _submitting ? 'Saving...' : 'Confirm Collection',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
          const Text('Collection Details',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          _buildKgField(_clearKgController, 'Clear Glass (kg)', Icons.lens_outlined),
          const SizedBox(height: 12),
          _buildKgField(_colouredKgController, 'Coloured Glass (kg)', Icons.lens),
          const SizedBox(height: 16),
          const Text('Glass Condition',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _condition,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: ['Good', 'Fair', 'Poor', 'Contaminated']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _condition = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildKgField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixText: 'kg',
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (double.tryParse(v) == null) return 'Enter a valid number';
        if (double.parse(v) < 0) return 'Must be 0 or more';
        return null;
      },
    );
  }
}