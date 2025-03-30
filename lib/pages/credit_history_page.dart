import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/credit_transaction.dart';
import '../models/credit_customer.dart';
import '../services/credit_service.dart';

class CreditHistoryPage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CreditHistoryPage({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<CreditHistoryPage> createState() => _CreditHistoryPageState();
}

class _CreditHistoryPageState extends State<CreditHistoryPage> with WidgetsBindingObserver {
  final CreditService _creditService = CreditService();
  List<CreditTransaction> _transactions = [];
  double _totalCredit = 0;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTransactions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    final transactions = await _creditService.getTransactionsForCustomer(widget.customerId);
    final total = await _creditService.getTotalUnpaidCredit(widget.customerId);
    
    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _transactions = transactions;
      _totalCredit = total;
    });
  }

  void _addNewCredit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Credit',
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitCredit,
                child: const Text('Add Credit'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCredit() async {
    if (_formKey.currentState!.validate()) {
      final newTransaction = CreditTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: widget.customerId,
        amount: double.parse(_amountController.text),
        date: DateTime.now(),
        description: _descriptionController.text,
      );

      await _creditService.addTransaction(newTransaction);
      await _loadTransactions();

      _amountController.clear();
      _descriptionController.clear();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _markAsPaid(CreditTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark as Paid',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to mark this credit as paid?',
              style: GoogleFonts.urbanist(),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹${transaction.amount.toStringAsFixed(2)}',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show progress indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating payment status...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Mark as paid
      transaction.isPaid = true;
      transaction.paidDate = DateTime.now();
      
      // Update the transaction in the database
      await _creditService.updateTransaction(transaction);
      
      // Update the customer record and local state
      await _updateCustomerPaymentStatus();
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment marked as paid successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  // Add a method to update customer payment status based on transactions
  Future<void> _updateCustomerPaymentStatus() async {
    // Get all transactions for this customer
    final transactions = await _creditService.getTransactionsForCustomer(widget.customerId);
    
    // Calculate the total paid amount
    final totalAmount = transactions.fold<double>(
      0.0, (sum, tx) => sum + tx.amount
    );
    
    final totalPaidAmount = transactions
      .where((tx) => tx.isPaid)
      .fold<double>(0.0, (sum, tx) => sum + tx.amount);
    
    final remainingAmount = totalAmount - totalPaidAmount;
    
    // Update local state for UI immediately
    setState(() {
      _totalCredit = remainingAmount;
      _transactions = List.from(transactions); // Force update of transaction list
    });
    
    // Check if all transactions are paid
    final allPaid = transactions.every((tx) => tx.isPaid);
    
    // Get all customers
    final customers = await _creditService.getAllCreditCustomers();
    
    // Find the customer by ID (this assumes customer ID format matches that used in the app)
    final customerIdParts = widget.customerId.split('_');
    final customerName = customerIdParts[0];
    
    // Find customer with matching name and purchase timestamp
    final index = customers.indexWhere((c) {
      if (customerIdParts.length > 1) {
        final timestamp = int.tryParse(customerIdParts[1]);
        return c.customerName == customerName && 
            c.purchaseDate.millisecondsSinceEpoch.toString() == customerIdParts[1];
      }
      return c.customerName == customerName;
    });
    
    if (index >= 0) {
      // Update customer payment status
      final customer = customers[index];
      final updatedCustomer = CreditCustomer(
        customerName: customer.customerName,
        productName: customer.productName,
        quantity: customer.quantity,
        totalAmount: customer.totalAmount,
        paidAmount: totalPaidAmount,
        remainingAmount: remainingAmount,
        purchaseDate: customer.purchaseDate,
        dueDate: customer.dueDate,
        isPaid: allPaid,
      );
      
      // Update customer data
      await _creditService.updateCreditCustomer(updatedCustomer, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName,
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  'Pending Credit: ',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _totalCredit > 0 ? Colors.red.withOpacity(0.8) : null,
                  ),
                ),
                Text(
                  '₹${_totalCredit.toStringAsFixed(2)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _totalCredit > 0 ? Colors.red : Colors.green,
                  ),
                ),
                if (_totalCredit <= 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? Center(
              child: Text(
                'No credit history',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : RefreshIndicator(
              key: _refreshKey,
              onRefresh: _loadTransactions,
              child: ListView.builder(
                itemCount: _transactions.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final bool isUnpaid = !transaction.isPaid;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(transaction.date),
                                style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${transaction.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.urbanist(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            transaction.description,
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: transaction.isPaid
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  transaction.isPaid ? 'Paid' : 'Pending',
                                  style: GoogleFonts.urbanist(
                                    color: transaction.isPaid
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isUnpaid)
                                TextButton.icon(
                                  onPressed: () => _markAsPaid(transaction),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark as Paid'),
                                ),
                            ],
                          ),
                          if (transaction.isPaid && transaction.paidDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Paid on: ${DateFormat('MMM dd, yyyy').format(transaction.paidDate!)}',
                                style: GoogleFonts.urbanist(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCredit,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Credit',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 