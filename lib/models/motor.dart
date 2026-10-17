import 'package:cloud_firestore/cloud_firestore.dart';

class Motor {
  String id;
  String name;
  double price;
  double downPayment;
  int months;
  double paidAmount;
  DateTime? createdAt;

  Motor({
    required this.id,
    required this.name,
    required this.price,
    required this.downPayment,
    required this.months,
    this.paidAmount = 0,
    this.createdAt,
  });

  // 💵 Amount financed (price minus down payment)
  double get financedAmount {
    final value = price - downPayment;
    return value < 0 ? 0.0 : value;
  }

  // 💰 Remaining balance (never negative, even if overpaid)
  double get balance {
    final value = price - downPayment - paidAmount;
    return value < 0 ? 0.0 : value;
  }

  // ✅ Fully paid?
  bool get isFullyPaid => balance <= 0;

  // 📅 Monthly due
  double get monthlyDue => months <= 0 ? 0.0 : balance / months;

  // 📈 Payment progress from 0.0 to 1.0
  double get progress {
    final total = financedAmount;
    if (total <= 0) return 1.0;
    final value = paidAmount / total;
    return value.clamp(0.0, 1.0);
  }

  Motor copyWith({
    String? id,
    String? name,
    double? price,
    double? downPayment,
    int? months,
    double? paidAmount,
    DateTime? createdAt,
  }) {
    return Motor(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      downPayment: downPayment ?? this.downPayment,
      months: months ?? this.months,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 🔄 Convert to Firebase Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'downPayment': downPayment,
      'months': months,
      'paidAmount': paidAmount,
    };
  }

  // 🔄 Convert from Firebase Map
  factory Motor.fromMap(String id, Map<String, dynamic> data) {
    return Motor(
      id: id,
      name: (data['name'] ?? '').toString(),
      price: _toDouble(data['price']),
      downPayment: _toDouble(data['downPayment']),
      months: _toInt(data['months'], fallback: 1),
      paidAmount: _toDouble(data['paidAmount']),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  // 🔄 Convert from a Firestore document
  factory Motor.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Motor.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  // ---------- Safe parsers ----------
  // Firestore can return int, double, or even String depending on how the
  // value was saved. Casting blindly (e.g. `data['months'] ?? 1` as int)
  // throws and kills the whole stream, which shows the dashboard error.

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
    }
    return fallback;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final text = value.replaceAll(',', '').trim();
      return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}