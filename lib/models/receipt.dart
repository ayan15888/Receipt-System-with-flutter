class Receipt {
  final String productName;
  final String quantity;
  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final String paymentMethod;
  final bool isPaid;
  final String notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String shopName;

  Receipt({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.notes,
    this.dueDate,
    DateTime? createdAt,
    this.shopName = "Qurashi Meat",
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'remainingAmount': remainingAmount,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'shopName': shopName,
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      productName: json['productName'],
      quantity: json['quantity'],
      totalAmount: json['totalAmount'],
      advanceAmount: json['advanceAmount'],
      remainingAmount: json['remainingAmount'],
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'],
      notes: json['notes'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      shopName: json['shopName'] ?? "Qurashi Meat Shop",
    );
  }
} 