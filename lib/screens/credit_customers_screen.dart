import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_customer.dart';
import '../models/credit_transaction.dart';
import '../main.dart';
import '../services/credit_service.dart';
import 'credit_history_timeline_screen.dart';

class CreditCustomersScreen extends StatefulWidget {
  const CreditCustomersScreen({super.key});

  @override
  State<CreditCustomersScreen> createState() => _CreditCustomersScreenState();
}

class _CreditCustomersScreenState extends State<CreditCustomersScreen> with SingleTickerProviderStateMixin {
  final List<CreditCustomer> _creditCustomers = [];
  bool _showOnlyPending = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final CreditService _creditService = CreditService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadCreditCustomers();
  }

  Future<void> _loadCreditCustomers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customers = await _creditService.getAllCreditCustomers();
      setState(() {
        _creditCustomers.clear();
        _creditCustomers.addAll(customers);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final statusColors = Theme.of(context).extension<StatusColors>();
    
    final displayedCustomers = _showOnlyPending
        ? _creditCustomers.where((customer) => !customer.isPaid).toList()
        : _creditCustomers;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Credit Customers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyPending ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showOnlyPending = !_showOnlyPending;
              });
            },
            tooltip: _showOnlyPending ? 'Show All' : 'Show Only Pending',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _showOnlyPending
                                  ? 'Showing pending payments only'
                                  : 'Showing all credit customers',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: displayedCustomers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No credit customers yet',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first credit customer',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = displayedCustomers[index];
                                final daysLeft = customer.dueDate
                                    .difference(DateTime.now())
                                    .inDays;
                                final isOverdue = daysLeft < 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ExpansionTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: customer.isPaid
                                              ? statusColors?.successContainer
                                              : isOverdue
                                                  ? statusColors?.errorContainer
                                                  : statusColors?.pendingContainer,
                                        ),
                                        child: Icon(
                                          customer.isPaid
                                              ? Icons.check_circle
                                              : isOverdue
                                                  ? Icons.warning
                                                  : Icons.access_time,
                                          color: customer.isPaid
                                              ? statusColors?.success
                                              : isOverdue
                                                  ? statusColors?.error
                                                  : statusColors?.pending,
                                        ),
                                      ),
                                      title: Text(
                                        customer.customerName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Due: ${DateFormat('dd MMM yyyy').format(customer.dueDate)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: isOverdue
                                              ? statusColors?.error
                                              : Theme.of(context).colorScheme.secondary,
                                          fontWeight: isOverdue ? FontWeight.bold : null,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${customer.remainingAmount.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: customer.isPaid
                                                  ? statusColors?.success
                                                  : isOverdue
                                                      ? statusColors?.error
                                                      : statusColors?.pending,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: customer.isPaid
                                                  ? statusColors?.successContainer
                                                  : isOverdue
                                                      ? statusColors?.errorContainer
                                                      : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              customer.isPaid
                                                  ? 'PAID'
                                                  : (isOverdue ? 'OVERDUE' : 'PENDING'),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: customer.isPaid
                                                    ? statusColors?.success
                                                    : isOverdue
                                                        ? statusColors?.error
                                                        : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              _buildInfoRow('Product', customer.productName),
                                              _buildInfoRow('Quantity', customer.quantity),
                                              _buildInfoRow(
                                                'Total Amount',
                                                '₹${customer.totalAmount.toStringAsFixed(2)}',
                                              ),
                                              _buildInfoRow(
                                                'Paid Amount',
                                                '₹${customer.paidAmount.toStringAsFixed(2)}',
                                              ),
                                              _buildInfoRow(
                                                'Remaining Amount',
                                                '₹${customer.remainingAmount.toStringAsFixed(2)}',
                                                isHighlighted: customer.remainingAmount > 0,
                                                highlightColor: customer.remainingAmount > 0
                                                    ? Colors.red
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      _showCreditHistoryTimeline(customer);
                                                    },
                                                    icon: const Icon(Icons.history),
                                                    label: const Text('Show History'),
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      _addMoreCreditDialog(customer, index);
                                                    },
                                                    icon: const Icon(Icons.add_circle_outline),
                                                    label: const Text('Add More Credit'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddCreditCustomerDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _showAddCreditCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final customerNameController = TextEditingController();
    final productNameController = TextEditingController();
    final quantityController = TextEditingController();
    final totalAmountController = TextEditingController();
    final paidAmountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add Credit Customer',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: productNameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: totalAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '₹',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: paidAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Paid Amount',
                          prefixIcon: Icon(Icons.payments),
                          prefixText: '₹',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter paid amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          final total = double.tryParse(totalAmountController.text) ?? 0;
                          final paid = double.tryParse(value) ?? 0;
                          if (paid > total) {
                            return 'Paid amount cannot exceed total amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Due Date'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dueDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final double totalAmount = double.parse(totalAmountController.text);
                            final double paidAmount = double.parse(paidAmountController.text);
                            final double remainingAmount = totalAmount - paidAmount;
                            
                            final newCustomer = CreditCustomer(
                              customerName: customerNameController.text,
                              productName: productNameController.text,
                              quantity: quantityController.text,
                              totalAmount: totalAmount,
                              paidAmount: paidAmount,
                              remainingAmount: remainingAmount,
                              purchaseDate: DateTime.now(),
                              dueDate: dueDate,
                              isPaid: remainingAmount <= 0,
                            );
                            
                            // Save to the service
                            await _creditService.saveCreditCustomer(newCustomer);
                            
                            // Refresh the list
                            await _loadCreditCustomers();
                            
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Credit customer added successfully'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                        },
                        child: const Text('Add Customer'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addMoreCreditDialog(CreditCustomer customer, int index) {
    final formKey = GlobalKey<FormState>();
    final additionalAmountController = TextEditingController();
    final quantityController = TextEditingController();
    final productTypeController = TextEditingController();
    DateTime extendedDueDate = customer.dueDate.isAfter(DateTime.now())
        ? customer.dueDate.add(const Duration(days: 30))
        : DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add More Credit',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Customer: ${customer.customerName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Current remaining: ₹${customer.remainingAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: productTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Product Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Additional Quantity',
                          prefixIcon: Icon(Icons.add_shopping_cart),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: additionalAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Additional Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '₹',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter additional amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('New Due Date'),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(extendedDueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: extendedDueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              extendedDueDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final additionalAmount = double.parse(additionalAmountController.text);
                            final additionalQuantity = quantityController.text;
                            final productType = productTypeController.text;
                            
                            // Create a transaction record for this additional credit
                            final customerId = customer.customerName + '_' + customer.purchaseDate.millisecondsSinceEpoch.toString();
                            final additionalCreditTransaction = CreditTransaction(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              customerId: customerId,
                              amount: additionalAmount,
                              date: DateTime.now(),
                              description: 'Additional purchase: $productType ($additionalQuantity)',
                              isPaid: false,
                            );
                            
                            await _creditService.addTransaction(additionalCreditTransaction);
                            
                            // Update the customer with additional credit
                            final updatedProductInfo = customer.productName + 
                                ", " + productType;
                            final updatedQuantity = customer.quantity + 
                                " + " + additionalQuantity;
                                
                            final updatedCustomer = CreditCustomer(
                              customerName: customer.customerName,
                              productName: updatedProductInfo,
                              quantity: updatedQuantity,
                              totalAmount: customer.totalAmount + additionalAmount,
                              paidAmount: customer.paidAmount,
                              remainingAmount: customer.remainingAmount + additionalAmount,
                              purchaseDate: customer.purchaseDate,
                              dueDate: extendedDueDate,
                              isPaid: false,
                            );
                            
                            // Save to the service
                            await _creditService.updateCreditCustomer(updatedCustomer, index);
                            
                            // Refresh the list
                            await _loadCreditCustomers();
                            
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Additional credit added successfully'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                        },
                        child: const Text('Add Credit'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreditHistoryTimeline(CreditCustomer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditHistoryTimelineScreen(
          customer: customer,
          onRefresh: () => _loadCreditCustomers(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted ? highlightColor : null,
            ),
          ),
        ],
      ),
    );
  }
} 