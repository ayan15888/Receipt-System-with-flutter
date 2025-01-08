import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/listviewscreen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Form and Screenshot',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black, fontSize: 12),
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

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final ScreenshotController screenshotController = ScreenshotController();

  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _remainingController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _kgController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    _advanceController
        .addListener(() => setState(() => _updateRemainingPayment()));
    _totalController
        .addListener(() => setState(() => _updateRemainingPayment()));
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
          text: 'Here is your receipt! ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Form', style: TextStyle(color: Colors.white,fontFamily: 'Courier',fontWeight: FontWeight.bold,fontSize: 25)),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                  _kgController, 'Number of KG', TextInputType.number,
                  icon: Icons.format_list_numbered),
              _buildTextField(
                  _nameController, 'Product Name', TextInputType.text,
                  icon: Icons.shopping_cart),
              _buildTextField(
                _totalController,
                'Total Payment',
                TextInputType.number,
                icon: Icons.monetization_on,
                onChanged: (_) => _updateRemainingPayment(),
              ),
              _buildTextField(
                _advanceController,
                'Advance Payment',
                TextInputType.number,
                icon: Icons.payment,
                onChanged: (_) => _updateRemainingPayment(),
              ),
              _buildReadOnlyTextField(
                  _remainingController, 'Remaining Payment'),
              _buildDatePickerButton(),
              _buildCustomerSummaryCard(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 75, right: 75),
                child: ElevatedButton.icon(
                  onPressed: _shareScreenshot,
                  icon: Icon(
                    Icons.share,
                    color: Colors.black,
                    size: 24,
                  ), // Icon widget
                  label: const Text(
                    'Share Screenshot',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ), // Text widget for the label
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                          color: Colors.black,
                          width: 1), // Correctly added border
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),

      // Updated Floating Action Button
      // floatingActionButton: Container(
      //   decoration: BoxDecoration(
      //     color: Colors.lime, // Background color
      //     borderRadius: BorderRadius.circular(30),
      //     border: Border.all(
      //       color: Colors.black, // Border color
      //       width: 1, // Border width
      //     ),
      //   ),
      //   child: FloatingActionButton.extended(
      //     onPressed: () {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => listview(
      //             Name: _nameController.text,
      //             Kg: _kgController.text,
      //             Total: _totalController.text,
      //             Advance: _advanceController.text,
      //             Remaining: _remainingController.text,
      //             DueDate: _selectedDate.toString().split(' ')[0],
      //             screenshotController: screenshotController,
      //           ),
      //         ),
      //       );
      //     },
      //     label: const Text(
      //       'Add to List',
      //       style: TextStyle(color: Colors.black87),
      //     ),
      //     icon: const Icon(Icons.add),
      //     backgroundColor: Colors
      //         .transparent, // Make it transparent so container color is visible
      //     elevation: 0, // Remove shadow if desired
      //   ),
      // ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, TextInputType inputType,
      {ValueChanged<String>? onChanged, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(255, 2, 59, 4), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildReadOnlyTextField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          prefixIcon: const Icon(Icons.money),
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() => _selectedDate = pickedDate);
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.grey[200],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(_selectedDate == null
            ? 'Pick Date'
            : 'Due Date : ${_selectedDate.toString().split(' ')[0]}'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Courier',
          ),
        ),
        Text(
          value.isNotEmpty ? value : "-",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: isRed ? Colors.red : Colors.black54,
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
        style: TextStyle(
          color: Colors.black, // Softer black for other text
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
