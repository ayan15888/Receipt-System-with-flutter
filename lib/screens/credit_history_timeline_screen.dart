import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_customer.dart';
import '../models/credit_transaction.dart';
import '../services/credit_service.dart';
import '../main.dart';

class CreditHistoryTimelineScreen extends StatefulWidget {
  final CreditCustomer customer;
  final VoidCallback onRefresh;

  const CreditHistoryTimelineScreen({
    Key? key,
    required this.customer,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CreditHistoryTimelineScreen> createState() => _CreditHistoryTimelineScreenState();
}

class _CreditHistoryTimelineScreenState extends State<CreditHistoryTimelineScreen> {
  final CreditService _creditService = CreditService();
  List<CreditTransaction> _transactions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }
  
  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create a unique ID for the customer if not already saved in transaction
      final customerId = widget.customer.customerName + '_' + widget.customer.purchaseDate.millisecondsSinceEpoch.toString();
      final transactions = await _creditService.getTransactionsForCustomer(customerId);
      
      // If no transactions, create the initial one from customer data
      if (transactions.isEmpty) {
        final initialTransaction = CreditTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customerId,
          amount: widget.customer.totalAmount,
          date: widget.customer.purchaseDate,
          description: 'Initial purchase: ${widget.customer.productName} (${widget.customer.quantity})',
          isPaid: widget.customer.isPaid,
          paidDate: widget.customer.isPaid ? DateTime.now() : null,
          paymentNote: widget.customer.isPaid ? 'Paid at purchase' : null,
        );
        
        await _creditService.addTransaction(initialTransaction);
        transactions.add(initialTransaction);
      }
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transaction history: $e')),
      );
    }
  }
  
  Future<void> _markTransactionAsPaid(CreditTransaction transaction) async {
    final TextEditingController noteController = TextEditingController();
    
    final shouldMarkAsPaid = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${transaction.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Payment Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
    
    if (shouldMarkAsPaid == true) {
      // Update the transaction
      transaction.isPaid = true;
      transaction.paidDate = DateTime.now();
      transaction.paymentNote = noteController.text.isEmpty ? 'Marked as paid' : noteController.text;
      
      await _creditService.updateTransaction(transaction);
      
      // Check if all transactions are paid and update customer if needed
      await _updateCustomerPaymentStatus();
      
      // Refresh transactions
      await _loadTransactionHistory();
      
      // Refresh parent screen
      widget.onRefresh();
    }
  }
  
  Future<void> _updateCustomerPaymentStatus() async {
    final allPaid = _transactions.every((tx) => tx.isPaid);
    if (allPaid && !widget.customer.isPaid) {
      // All transactions are now paid, update customer status
      final updatedCustomer = CreditCustomer(
        customerName: widget.customer.customerName,
        productName: widget.customer.productName,
        quantity: widget.customer.quantity,
        totalAmount: widget.customer.totalAmount,
        paidAmount: widget.customer.totalAmount, // Set paid amount to total amount
        remainingAmount: 0, // Set remaining to 0
        purchaseDate: widget.customer.purchaseDate,
        dueDate: widget.customer.dueDate,
        isPaid: true,
      );
      
      // Find customer index and update
      final customers = await _creditService.getAllCreditCustomers();
      final index = customers.indexWhere((c) => 
          c.customerName == widget.customer.customerName && 
          c.purchaseDate.millisecondsSinceEpoch == widget.customer.purchaseDate.millisecondsSinceEpoch);
      
      if (index >= 0) {
        await _creditService.updateCreditCustomer(updatedCustomer, index);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    
    // Calculate total credit taken
    final totalCreditTaken = _transactions.fold<double>(
      0.0, (sum, transaction) => sum + transaction.amount
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Credit History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.customer.customerName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.customer.isPaid 
                                ? statusColors?.successContainer 
                                : statusColors?.pendingContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.customer.isPaid ? 'PAID' : 'PENDING',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.customer.isPaid
                                  ? statusColors?.success
                                  : statusColors?.pending,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.customer.productName} (${widget.customer.quantity})',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${DateFormat('dd MMM yyyy').format(widget.customer.dueDate)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Credit Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCreditSummaryCard(
                          context,
                          'Total Credit Taken',
                          '₹${totalCreditTaken.toStringAsFixed(2)}',
                          Icons.account_balance_wallet,
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildCreditSummaryCard(
                          context,
                          'Remaining',
                          '₹${widget.customer.remainingAmount.toStringAsFixed(2)}',
                          Icons.pending_actions,
                          widget.customer.remainingAmount > 0
                              ? statusColors?.pending
                              : statusColors?.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildCreditSummaryCard(
                          context,
                          'Paid Amount',
                          '₹${widget.customer.paidAmount.toStringAsFixed(2)}',
                          Icons.payments,
                          statusColors?.success,
                        ),
                        const SizedBox(width: 12),
                        _buildCreditSummaryCard(
                          context,
                          'Credit Entries',
                          '${_transactions.length}',
                          Icons.receipt_long,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction Timeline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _transactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transaction history found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          final bool isLastItem = index == _transactions.length - 1;
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: transaction.isPaid
                                          ? statusColors?.success
                                          : statusColors?.pending,
                                    ),
                                  ),
                                  if (!isLastItem)
                                    Container(
                                      width: 2,
                                      height: 140, // Increased height for more content
                                      color: Colors.grey.withOpacity(0.5),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(transaction.date),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: transaction.isPaid
                                                ? statusColors?.successContainer
                                                : statusColors?.pendingContainer,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            transaction.isPaid ? 'PAID' : 'PENDING',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: transaction.isPaid
                                                  ? statusColors?.success
                                                  : statusColors?.pending,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction.description,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildTransactionDetail(
                                              context, 
                                              'Amount',
                                              '₹${transaction.amount.toStringAsFixed(2)}',
                                              Icons.attach_money,
                                            ),
                                            
                                            // Extract and display product details if available
                                            _buildProductDetails(context, transaction.description),
                                            
                                            if (transaction.isPaid && transaction.paidDate != null) ...[
                                              const SizedBox(height: 8),
                                              Divider(),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Paid on:',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    DateFormat('dd MMM yyyy').format(transaction.paidDate!),
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              if (transaction.paymentNote != null && transaction.paymentNote!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Note: ${transaction.paymentNote}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                            if (!transaction.isPaid) ...[
                                              const SizedBox(height: 12),
                                              Center(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _markTransactionAsPaid(transaction),
                                                  icon: const Icon(Icons.check_circle_outline),
                                                  label: const Text('Mark as Paid'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: statusColors?.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }
  
  Widget _buildCreditSummaryCard(
    BuildContext context, 
    String title, 
    String value, 
    IconData icon, 
    Color? color
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionDetail(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductDetails(BuildContext context, String description) {
    // For initial purchase
    if (description.startsWith('Initial purchase:')) {
      final productInfo = description.replaceFirst('Initial purchase:', '').trim();
      final productName = productInfo.split('(').first.trim();
      final quantity = productInfo.contains('(') && productInfo.contains(')') 
          ? productInfo.split('(')[1].replaceAll(')', '').trim()
          : '';
          
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransactionDetail(
            context, 
            'Product', 
            productName, 
            Icons.category,
          ),
          if (quantity.isNotEmpty)
            _buildTransactionDetail(
              context, 
              'Quantity', 
              quantity, 
              Icons.shopping_cart,
            ),
        ],
      );
    }
    
    // For additional purchase
    if (description.startsWith('Additional purchase:')) {
      final productInfo = description.replaceFirst('Additional purchase:', '').trim();
      final productType = productInfo.split('(').first.trim();
      final quantity = productInfo.contains('(') && productInfo.contains(')') 
          ? productInfo.split('(')[1].replaceAll(')', '').trim()
          : '';
          
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransactionDetail(
            context, 
            'Product Type', 
            productType, 
            Icons.category,
          ),
          if (quantity.isNotEmpty)
            _buildTransactionDetail(
              context, 
              'Quantity', 
              quantity, 
              Icons.shopping_cart,
            ),
        ],
      );
    }
    
    // Default empty widget if format doesn't match
    return const SizedBox.shrink();
  }
} 