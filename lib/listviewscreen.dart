import 'dart:math';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class listview extends StatefulWidget {
  // Declare the required parameters as final variables
  final String Name;
  final String Kg;
  final String Total;
  final String Advance;
  final String DueDate;
  final String Remaining;

  // Constructor with required parameters
  const listview({
    Key? key,
    required this.Name,
    required this.Kg,
    required this.Total,
    required this.Advance,
    required this.DueDate,
    required this.Remaining,
     required ScreenshotController screenshotController,
  }) : super(key: key);

  @override
  State<listview> createState() => _listviewState();
}

class _listviewState extends State<listview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Data'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.grey[300],
      body: Center(
      
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Inner padding of the card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(
                color: Colors.grey,
                thickness: sqrt1_2,
              ),
              _buildCardRow('Name', widget.Name),
  
              Divider(
                color: Colors.grey,
                thickness: sqrt1_2,
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build a row of label and value
  Widget _buildCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            label == 'Name'
                ? GestureDetector(
                    onTap: () {
                      _showDetailsPopup(context); // Show details on tap of name
                    },
                    child: Material(
                      shape: RoundedRectangleBorder(
        
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child:Container(
                          width: 300,
                          child:  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$label: $value',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            Icon(
                              Icons.info,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        )
                      )
                        
                        
                      ),
                      
                    )
                  
                : Text(
                    '$label: $value',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Function to show the popup with details when Name is clicked
  void _showDetailsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.Name ,style: TextStyle(color: Colors.black),), // Name as the title of the popup
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPopupRow('Kg', widget.Kg + " Kg"),
              _buildPopupRow('Total', "₹ " + widget.Total),
              _buildPopupRow('Advance', "₹ " + widget.Advance),
              _buildPopupRow('Remaining', "₹ " + widget.Remaining),
              _buildPopupRow('Due Date', widget.DueDate),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to build rows for the popup content
  Widget _buildPopupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
