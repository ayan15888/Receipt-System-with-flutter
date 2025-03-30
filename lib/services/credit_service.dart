import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credit_customer.dart';
import '../models/credit_transaction.dart';

class CreditService {
  static const String _creditCustomersKey = 'credit_customers';
  static const String _creditTransactionsKey = 'credit_transactions';

  // Credit Customer methods
  Future<List<CreditCustomer>> getAllCreditCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final customersJson = prefs.getStringList(_creditCustomersKey) ?? [];
    
    return customersJson
        .map((json) => CreditCustomer.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveCreditCustomer(CreditCustomer customer) async {
    final prefs = await SharedPreferences.getInstance();
    final customers = await getAllCreditCustomers();
    
    customers.add(customer);
    await _saveAllCreditCustomers(customers);
  }

  Future<void> updateCreditCustomer(CreditCustomer updatedCustomer, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final customers = await getAllCreditCustomers();
    
    if (index >= 0 && index < customers.length) {
      customers[index] = updatedCustomer;
      await _saveAllCreditCustomers(customers);
    }
  }

  Future<void> deleteCreditCustomer(int index) async {
    final customers = await getAllCreditCustomers();
    
    if (index >= 0 && index < customers.length) {
      customers.removeAt(index);
      await _saveAllCreditCustomers(customers);
    }
  }

  Future<void> _saveAllCreditCustomers(List<CreditCustomer> customers) async {
    final prefs = await SharedPreferences.getInstance();
    final customersJson = customers
        .map((customer) => jsonEncode(customer.toJson()))
        .toList();
    
    await prefs.setStringList(_creditCustomersKey, customersJson);
  }

  // Credit Transaction methods
  Future<List<CreditTransaction>> getTransactionsForCustomer(String customerId) async {
    final allTransactions = await getAllTransactions();
    return allTransactions
        .where((transaction) => transaction.customerId == customerId)
        .toList();
  }

  Future<List<CreditTransaction>> getAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getStringList(_creditTransactionsKey) ?? [];
    
    return transactionsJson
        .map((json) => CreditTransaction.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addTransaction(CreditTransaction transaction) async {
    final transactions = await getAllTransactions();
    transactions.add(transaction);
    await _saveAllTransactions(transactions);
  }

  Future<void> updateTransaction(CreditTransaction updatedTransaction) async {
    final transactions = await getAllTransactions();
    final index = transactions.indexWhere((t) => t.id == updatedTransaction.id);
    
    if (index >= 0) {
      transactions[index] = updatedTransaction;
      await _saveAllTransactions(transactions);
    }
  }

  Future<void> _saveAllTransactions(List<CreditTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions
        .map((transaction) => jsonEncode(transaction.toJson()))
        .toList();
    
    await prefs.setStringList(_creditTransactionsKey, transactionsJson);
  }

  Future<double> getTotalUnpaidCredit(String customerId) async {
    final transactions = await getTransactionsForCustomer(customerId);
    
    // Get only transactions that are not paid
    final unpaidTransactions = transactions.where((transaction) => !transaction.isPaid);
    
    // Calculate total unpaid amount
    return unpaidTransactions.fold<double>(
      0.0, 
      (sum, transaction) => sum + transaction.amount
    );
  }
} 