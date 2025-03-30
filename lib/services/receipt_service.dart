import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt.dart';

class ReceiptService {
  static const String _key = 'receipts';

  static Future<List<Receipt>> getReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsJson = prefs.getStringList(_key) ?? [];
    
    return receiptsJson
        .map((json) => Receipt.fromJson(jsonDecode(json)))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
  }

  static Future<void> saveReceipt(Receipt receipt) async {
    final prefs = await SharedPreferences.getInstance();
    final receipts = await getReceipts();
    
    receipts.add(receipt);
    
    final receiptsJson = receipts
        .map((receipt) => jsonEncode(receipt.toJson()))
        .toList();
    
    await prefs.setStringList(_key, receiptsJson);
  }

  static Future<void> deleteReceipt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final receipts = await getReceipts();
    
    receipts.removeAt(index);
    
    final receiptsJson = receipts
        .map((receipt) => jsonEncode(receipt.toJson()))
        .toList();
    
    await prefs.setStringList(_key, receiptsJson);
  }
} 