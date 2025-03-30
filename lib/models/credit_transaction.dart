import 'package:flutter/material.dart';

class CreditTransaction {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String description;
  bool isPaid;
  DateTime? paidDate;
  String? paymentNote;

  CreditTransaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.description,
    this.isPaid = false,
    this.paidDate,
    this.paymentNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
      'paymentNote': paymentNote,
    };
  }

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'],
      customerId: json['customerId'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      isPaid: json['isPaid'] ?? false,
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      paymentNote: json['paymentNote'],
    );
  }
} 