import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/receipt.dart';

class PdfService {
  static Future<pw.Document> generateReceipt(Receipt receipt) async {
    final pdf = pw.Document();
    
    final fontRegular = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();
    
    // Load logo image
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.Image logoImage = pw.Image(pw.MemoryImage(logoBytes), width: 80, height: 80);
    
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final receiptNumber = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo and shop name
                pw.Center(
                  child: pw.Column(
                    children: [
                      logoImage,
                      pw.SizedBox(height: 10),
                      pw.Text(
                        receipt.shopName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Receipt #$receiptNumber',
                        style: pw.TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(receipt.createdAt),
                        style: pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Payment status
                pw.Center(
                  child: pw.Container(
                    width: 100,
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: receipt.isPaid 
                        ? PdfColors.green100 
                        : PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        receipt.isPaid ? 'PAID' : 'PENDING',
                        style: pw.TextStyle(
                          color: receipt.isPaid 
                            ? PdfColors.green900 
                            : PdfColors.orange900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Product details
                _buildInfoRow('Product', receipt.productName, fontBold),
                _buildInfoRow('Quantity', '${receipt.quantity} KG', fontBold),
                _buildInfoRow('Payment Method', receipt.paymentMethod, fontBold),
                if (receipt.dueDate != null) 
                  _buildInfoRow('Due Date', DateFormat('dd MMM yyyy').format(receipt.dueDate!), fontBold),
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                
                // Amount section
                _buildAmountRow('Total Amount', currencyFormat.format(receipt.totalAmount), fontBold, isTotal: true),
                _buildAmountRow('Advance Paid', currencyFormat.format(receipt.advanceAmount), fontBold),
                _buildAmountRow('Remaining', currencyFormat.format(receipt.remainingAmount), fontBold, isRemaining: true),
                
                pw.SizedBox(height: 20),
                
                // Notes section
                if (receipt.notes.isNotEmpty) ...[
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(receipt.notes),
                ],
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf;
  }
  
  static pw.Widget _buildInfoRow(String label, String value, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              font: boldFont,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAmountRow(String label, String amount, pw.Font boldFont, {bool isTotal = false, bool isRemaining = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              font: isTotal ? boldFont : null,
              color: isTotal ? PdfColors.black : PdfColors.grey700,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              font: boldFont,
              color: isRemaining ? PdfColors.red : (isTotal ? PdfColors.black : PdfColors.green700),
            ),
          ),
        ],
      ),
    );
  }
  
  static Future<void> printReceipt(Receipt receipt) async {
    final pdf = await generateReceipt(receipt);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
  
  static Future<File> saveReceipt(Receipt receipt) async {
    final pdf = await generateReceipt(receipt);
    final bytes = await pdf.save();
    
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(bytes);
    return file;
  }
} 