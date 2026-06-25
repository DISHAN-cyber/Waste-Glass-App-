class Supplier {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double expectedKg;
  final String barcodeRef;
  String status; // Pending, Next, Collected
  final int stopOrder;
  final double distanceFromPrev;

  Supplier({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.expectedKg,
    required this.barcodeRef,
    required this.status,
    required this.stopOrder,
    required this.distanceFromPrev,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      expectedKg: (json['expectedKg'] ?? 0).toDouble(),
      barcodeRef: json['barcodeRef'] ?? json['id'].toString(),
      status: json['status'] ?? 'Pending',
      stopOrder: json['stopOrder'] ?? 0,
      distanceFromPrev: (json['distanceFromPrev'] ?? 0).toDouble(),
    );
  }
}

class CollectionRecord {
  final String supplierId;
  final double clearKg;
  final double colouredKg;
  final String condition;
  final DateTime timestamp;
  bool synced;

  CollectionRecord({
    required this.supplierId,
    required this.clearKg,
    required this.colouredKg,
    required this.condition,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'supplier_id': supplierId,
      'clear_kg': clearKg,
      'coloured_kg': colouredKg,
      'condition': condition,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'clearKg': clearKg,
      'colouredKg': colouredKg,
      'condition': condition,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CollectionRecord.fromMap(Map<String, dynamic> map) {
    return CollectionRecord(
      supplierId: map['supplier_id'],
      clearKg: map['clear_kg'],
      colouredKg: map['coloured_kg'],
      condition: map['condition'],
      timestamp: DateTime.parse(map['timestamp']),
      synced: map['synced'] == 1,
    );
  }
}

class TripSummary {
  final List<SupplierSummary> supplierSummaries;
  final double totalKg;
  final double totalDistance;
  final Duration tripDuration;

  TripSummary({
    required this.supplierSummaries,
    required this.totalKg,
    required this.totalDistance,
    required this.tripDuration,
  });
}

class SupplierSummary {
  final String supplierId;
  final String supplierName;
  final double expectedKg;
  final double collectedKg;
  final bool hasShortfall;
  final String condition;

  SupplierSummary({
    required this.supplierId,
    required this.supplierName,
    required this.expectedKg,
    required this.collectedKg,
    required this.hasShortfall,
    required this.condition,
  });
}
