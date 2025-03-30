import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/listviewscreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/credit_customers_screen.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/receipt_service.dart';
import 'screens/history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Import to access StatusColors
import 'services/pdf_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Form and Screenshot',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C), // Deep red (primary color for meat shop)
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFB71C1C), // Deep red
          secondary: const Color(0xFF8D4C2E), // Warm brown
          tertiary: const Color(0xFF5D4037), // Dark brown
        ),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
          const TextTheme(
            bodyMedium: TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFB71C1C),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const PermissionPage(),
    );
  }
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  _PermissionPageState createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  Future<void> requestPermissionsAndNavigate() async {
    PermissionStatus storageStatus = await Permission.storage.request();
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (storageStatus.isGranted && cameraStatus.isGranted) {
      Fluttertoast.showToast(
        msg: "Permissions granted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomerForm()),
      );
    } else {
      Fluttertoast.showToast(
        msg: "Permissions denied!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Permissions'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: requestPermissionsAndNavigate,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: Colors.greenAccent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: const Text(
            'Grant Permissions & Continue',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ScreenshotController screenshotController = ScreenshotController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _remainingController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  String _paymentMethod = 'Cash';
  bool _isPaid = false;
  final String _shopName = "Qurashi Meat";

  @override
  void initState() {
    super.initState();
    _kgController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _advanceController
        .addListener(() => setState(() => _updateRemainingPayment()));
    _totalController
        .addListener(() => setState(() => _updateRemainingPayment()));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  void _updateRemainingPayment() {
    final total = double.tryParse(_totalController.text) ?? 0.0;
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    final remaining = total - advance;

    _remainingController.text =
        remaining >= 0 ? remaining.toStringAsFixed(2) : '0.00';
  }

  Future<void> _shareScreenshot() async {
    final image = await screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Here is your receipt from $_shopName!');
    }
  }

  Future<void> _generatePdf() async {
    // Check if form is valid
    if (_formKey.currentState!.validate()) {
      final receipt = Receipt(
        productName: _nameController.text,
        quantity: _kgController.text,
        totalAmount: double.parse(_totalController.text),
        advanceAmount: double.parse(_advanceController.text),
        remainingAmount: double.parse(_totalController.text) - double.parse(_advanceController.text),
        paymentMethod: _paymentMethod,
        isPaid: _isPaid,
        notes: _notesController.text,
        dueDate: _selectedDate,
        shopName: _shopName,
      );

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
                  title: Text('Preview PDF', style: GoogleFonts.bricolageGrotesque()),
                  onTap: () async {
                    Navigator.pop(context);
                    await PdfService.printReceipt(receipt);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text('Save & Share PDF', style: GoogleFonts.bricolageGrotesque()),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await PdfService.saveReceipt(receipt);
                    if (context.mounted) {
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: 'Receipt from $_shopName',
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final receipt = Receipt(
        productName: _nameController.text,
        quantity: _kgController.text,
        totalAmount: double.parse(_totalController.text),
        advanceAmount: double.parse(_advanceController.text),
        remainingAmount: double.parse(_totalController.text) - double.parse(_advanceController.text),
        paymentMethod: _paymentMethod,
        isPaid: _isPaid,
        notes: _notesController.text,
        dueDate: _selectedDate,
        shopName: _shopName,
      );

      try {
        await ReceiptService.saveReceipt(receipt);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear the form
          _formKey.currentState!.reset();
          _nameController.clear();
          _kgController.clear();
          _totalController.clear();
          _advanceController.clear();
          _notesController.clear();
          setState(() {
            _paymentMethod = 'Cash';
            _isPaid = false;
            _selectedDate = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving receipt: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Receipt',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreditCustomersScreen()),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _kgController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity (KG)',
                              prefixIcon: Icon(
                                Icons.scale,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _totalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total Amount',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter total amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _advanceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Advance Payment',
                              prefixIcon: Icon(
                                Icons.payments,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _remainingController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Remaining Amount',
                              prefixIcon: Icon(
                                Icons.account_balance_wallet,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _paymentMethod,
                                  decoration: InputDecoration(
                                    labelText: 'Payment Method',
                                    prefixIcon: Icon(
                                      Icons.payment,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  items: ['Cash', 'Card', 'UPI']
                                      .map((method) => DropdownMenuItem(
                                            value: method,
                                            child: Text(method),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _paymentMethod = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _isPaid,
                                onChanged: (value) {
                                  setState(() {
                                    _isPaid = value!;
                                  });
                                },
                              ),
                              const Text('Fully Paid'),
                              const Spacer(),
                              TextButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_selectedDate == null
                                    ? 'Select Due Date'
                                    : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Notes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any additional notes here...',
                              prefixIcon: Icon(
                                Icons.note,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_rounded, size: 24, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context).colorScheme.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _generatePdf,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, size: 24, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PDF',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSummaryCard() {
    return Screenshot(
      controller: screenshotController,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          // elevation: 5,
          margin: const EdgeInsets.all(12),

          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.black, width: 1)),
          color: Colors.white, // Cleaner white background
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 100,
                        height: 100,
                      ),
                    ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Qurashi\nMeatShop",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 17,
                       
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow('Product name:', _nameController.text),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow('Total Kg:', '${_kgController.text} Kg',
                    isRed: false),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow(
                    'Total Amount:', '₹${_totalController.text}'),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow(
                    'Advance payment:', '₹${_advanceController.text}'),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow(
                    'Remaining Amount:', '₹${_remainingController.text}',
                    isRed: true),
                const Divider(thickness: 1, height: 24),
                _buildDetailRow('Due Date:',
                    _selectedDate?.toString().split(' ')[0] ?? "-"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isRed = false}) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final pendingColor = statusColors?.pending ?? const Color(0xFFF57C00);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          value.isNotEmpty ? value : "-",
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: isRed ? pendingColor : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: GoogleFonts.bricolageGrotesque(
          color: Colors.black, // Softer black for other text
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

