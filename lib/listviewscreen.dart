import 'dart:math';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/pdf_service.dart';
import 'models/receipt.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ListViewScreen extends StatelessWidget {
  final String name;
  final String kg;
  final String total;
  final String advance;
  final String remaining;
  final String dueDate;
  final String paymentMethod;
  final bool isPaid;
  final String notes;
  final String shopName;

  const ListViewScreen({
    Key? key,
    required this.name,
    required this.kg,
    required this.total,
    required this.advance,
    required this.remaining,
    required this.dueDate,
    required this.paymentMethod,
    required this.isPaid,
    required this.notes,
    this.shopName = "Qurashi Meat",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptCard(context),
              const SizedBox(height: 16),
              if (notes.isNotEmpty) _buildNotesCard(context),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generatePdf(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    try {
      final receipt = Receipt(
        productName: name,
        quantity: kg,
        totalAmount: double.parse(total),
        advanceAmount: double.parse(advance),
        remainingAmount: double.parse(remaining),
        paymentMethod: paymentMethod,
        isPaid: isPaid,
        notes: notes,
        dueDate: dueDate.isNotEmpty ? DateFormat('dd MMM yyyy').parse(dueDate) : null,
        shopName: shopName,
      );

      // Show options dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('PDF Options', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text('Preview', style: GoogleFonts.bricolageGrotesque()),
                  onTap: () async {
                    Navigator.pop(context);
                    await PdfService.printReceipt(receipt);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text('Save & Share', style: GoogleFonts.bricolageGrotesque()),
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
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Widget _buildReceiptCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                shopName,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receipt #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(
                  label: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: isPaid ? Colors.white : Colors.black87,
                    ),
                  ),
                  backgroundColor: isPaid ? Colors.green : Colors.amber,
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Product', name),
            _buildInfoRow('Quantity', '$kg KG'),
            _buildInfoRow('Payment Method', paymentMethod),
            if (dueDate.isNotEmpty) _buildInfoRow('Due Date', dueDate),
            const Divider(),
            _buildAmountRow('Total Amount', total, context, isTotal: true),
            _buildAmountRow('Advance Paid', advance, context),
            _buildAmountRow('Remaining', remaining, context, isRemaining: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, BuildContext context, {bool isTotal = false, bool isRemaining = false}) {
    final formattedAmount = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(double.parse(amount));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isRemaining ? Colors.red : (isTotal ? Colors.black : Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
