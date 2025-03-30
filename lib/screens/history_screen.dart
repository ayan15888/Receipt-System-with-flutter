import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/receipt.dart';
import '../services/receipt_service.dart';
import '../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../main.dart'; // Import to access StatusColors

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late Future<List<Receipt>> _receiptsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _receiptsFuture = ReceiptService.getReceipts();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf(Receipt receipt) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'PDF Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.visibility,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Preview PDF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await PdfService.printReceipt(receipt);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.save_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Save & Share PDF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await PdfService.saveReceipt(receipt);
                    if (context.mounted) {
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: 'Receipt from ${receipt.shopName}',
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Receipt History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          child: FutureBuilder<List<Receipt>>(
            future: _receiptsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading receipts...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: statusColors?.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading receipts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColors?.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: () {
                          setState(() {
                            _receiptsFuture = ReceiptService.getReceipts();
                          });
                        },
                      ),
                    ],
                  ),
                );
              }

              final receipts = snapshot.data ?? [];

              if (receipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No receipts yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your receipt history will appear here',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: receipts.length,
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
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
                            color: receipt.isPaid
                                ? statusColors?.successContainer
                                : statusColors?.pendingContainer,
                          ),
                          child: Icon(
                            receipt.isPaid ? Icons.check_circle : Icons.pending,
                            color: receipt.isPaid
                                ? statusColors?.success
                                : statusColors?.pending,
                          ),
                        ),
                        title: Text(
                          receipt.productName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(receipt.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${receipt.totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: receipt.isPaid
                                    ? statusColors?.successContainer
                                    : statusColors?.pendingContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                receipt.isPaid ? 'PAID' : 'PENDING',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: receipt.isPaid
                                      ? statusColors?.success
                                      : statusColors?.pending,
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
                                Text(
                                  receipt.shopName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                _buildInfoRow('Quantity', '${receipt.quantity} KG'),
                                _buildInfoRow(
                                  'Total Amount',
                                  '₹${receipt.totalAmount.toStringAsFixed(2)}',
                                ),
                                _buildInfoRow(
                                  'Advance Paid',
                                  '₹${receipt.advanceAmount.toStringAsFixed(2)}',
                                ),
                                _buildInfoRow(
                                  'Remaining',
                                  '₹${receipt.remainingAmount.toStringAsFixed(2)}',
                                  isHighlighted: receipt.remainingAmount > 0,
                                  highlightColor: receipt.remainingAmount > 0 ? statusColors?.pending : null,
                                ),
                                _buildInfoRow('Payment Method', receipt.paymentMethod),
                                if (receipt.dueDate != null)
                                  _buildInfoRow(
                                    'Due Date',
                                    DateFormat('dd MMM yyyy').format(receipt.dueDate!),
                                  ),
                                if (receipt.notes.isNotEmpty) ...[
                                  const Divider(height: 24),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notes:',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          receipt.notes,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _generatePdf(receipt),
                                        icon: Icon(
                                          Icons.picture_as_pdf,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        label: Text(
                                          'PDF',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                'Delete Receipt', 
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete this receipt?',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, false),
                                                  child: Text(
                                                    'Cancel',
                                                    style: Theme.of(context).textTheme.labelSmall,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, true),
                                                  child: Text(
                                                    'Delete',
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: statusColors?.error,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            await ReceiptService.deleteReceipt(index);
                                            setState(() {
                                              _receiptsFuture =
                                                  ReceiptService.getReceipts();
                                            });
                                          }
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: statusColors?.error,
                                        ),
                                        label: Text(
                                          'Delete',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: statusColors?.error,
                                          ),
                                        ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, Color? highlightColor}) {
    final primaryColor = Theme.of(context).colorScheme.primary; // Deep red
    final statusColors = Theme.of(context).extension<StatusColors>();
    final color = highlightColor ?? (isHighlighted ? primaryColor : Colors.black87);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 