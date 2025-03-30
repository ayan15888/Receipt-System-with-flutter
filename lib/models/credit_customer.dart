class CreditCustomer {
  final String customerName;
  final String productName;
  final String quantity;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime purchaseDate;
  final DateTime dueDate;
  bool isPaid;

  CreditCustomer({
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.purchaseDate,
    required this.dueDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'productName': productName,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory CreditCustomer.fromJson(Map<String, dynamic> json) {
    return CreditCustomer(
      customerName: json['customerName'],
      productName: json['productName'],
      quantity: json['quantity'],
      totalAmount: json['totalAmount'],
      paidAmount: json['paidAmount'],
      remainingAmount: json['remainingAmount'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      dueDate: DateTime.parse(json['dueDate']),
      isPaid: json['isPaid'],
    );
  }
} 