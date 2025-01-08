import 'package:flutter/material.dart';
import 'splash.dart'; // Import SplashScreen
import 'customer_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Customer Form',
      theme: ThemeData(
        primarySwatch: Colors.green,
        datePickerTheme: DatePickerThemeData(
          cancelButtonStyle: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.green[800]),
            
          ),
          
          backgroundColor: Colors.white,
          dividerColor: Colors.green,
          dayStyle: TextStyle(color: Colors.green[800]), // Day numbers
          yearStyle: TextStyle(color: Colors.green[800]), // Year numbers
          weekdayStyle: TextStyle(color: Colors.green[800]), // Weekday labels
          headerForegroundColor: Colors.green[800], // Month and year header
        ),
      ),
      home: SplashScreen(),
    );
  }
}
