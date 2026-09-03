import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { inStock, low, outOfStock }

extension StockStatusX on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.low:
        return 'Low';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  static StockStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'low':
        return StockStatus.low;
      case 'outofstock':
      case 'out_of_stock':
      case 'out':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock;
    }
  }
}

class MedicineStockModel {
  final String id;
  final String name;
  final String category;
  final StockStatus status;
  final int currentQuantity;
  final int minimumQuantity;
  final String unit; // e.g. "tablets", "vials", "bottles"
  final DateTime? expiryDate;
  final DateTime lastUpdated;

  const MedicineStockModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.currentQuantity,
    required this.minimumQuantity,
    required this.unit,
    this.expiryDate,
    required this.lastUpdated,
  });

  factory MedicineStockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicineStockModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      status: StockStatusX.fromString(data['status'] as String? ?? 'inStock'),
      currentQuantity: (data['currentQuantity'] as num?)?.toInt() ?? 0,
      minimumQuantity: (data['minimumQuantity'] as num?)?.toInt() ?? 0,
      unit: data['unit'] as String? ?? 'units',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'status': status.name,
        'currentQuantity': currentQuantity,
        'minimumQuantity': minimumQuantity,
        'unit': unit,
        'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}
