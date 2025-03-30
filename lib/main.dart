import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash.dart';
import 'customer_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.urbanistTextTheme(Theme.of(context).textTheme);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Receipt System',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        textTheme: baseTextTheme.copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A5D1A),
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A5D1A),
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A5D1A),
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A5D1A),
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A5D1A),
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5D1A),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF455A64),
          tertiary: const Color(0xFF78909C),
          background: const Color(0xFFFAFAFA),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          error: const Color(0xFFD32F2F),
          surfaceVariant: const Color(0xFFF5F5F5),
        ),
        extensions: [
          StatusColors(
            error: const Color(0xFFD32F2F),
            errorContainer: const Color(0xFFFFEBEE),
            success: const Color(0xFF2E7D32),
            successContainer: const Color(0xFFE8F5E9),
            pending: const Color(0xFF455A64),
            pendingContainer: const Color(0xFFECEFF1),
            info: const Color(0xFF1976D2),
            infoContainer: const Color(0xFFE3F2FD),
          ),
        ],
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF1B5E20);
            }
            return Colors.grey;
          }),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        iconTheme: IconThemeData(
          color: const Color(0xFF2E7D32),
          size: 24,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          surfaceTintColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.shade200;
              }
              if (states.contains(MaterialState.pressed)) {
                return const Color(0xFF0D3F0D);
              }
              return const Color(0xFF1A5D1A);
            }),
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.shade500;
              }
              return Colors.white;
            }),
            textStyle: MaterialStateProperty.all(
              GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            elevation: MaterialStateProperty.resolveWith<double>((states) {
              if (states.contains(MaterialState.pressed)) return 0;
              if (states.contains(MaterialState.hovered)) return 3;
              return 1;
            }),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.white.withOpacity(0.2);
              }
              return null;
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.shade400;
              }
              if (states.contains(MaterialState.pressed)) {
                return const Color(0xFF1B5E20);
              }
              return const Color(0xFF2E7D32);
            }),
            side: MaterialStateProperty.resolveWith<BorderSide>((states) {
              if (states.contains(MaterialState.disabled)) {
                return BorderSide(color: Colors.grey.shade300);
              }
              if (states.contains(MaterialState.pressed)) {
                return const BorderSide(color: Color(0xFF1B5E20), width: 2);
              }
              return const BorderSide(color: Color(0xFF2E7D32), width: 1.5);
            }),
            textStyle: MaterialStateProperty.all(
              GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.shade400;
              }
              if (states.contains(MaterialState.pressed)) {
                return const Color(0xFF1B5E20);
              }
              return const Color(0xFF2E7D32);
            }),
            textStyle: MaterialStateProperty.all(
              GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.urbanist(
            color: const Color(0xFF2E7D32),
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: GoogleFonts.urbanist(
            color: const Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
          hintStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          helperStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          errorStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB71C1C),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class StatusColors extends ThemeExtension<StatusColors> {
  final Color? error;
  final Color? errorContainer;
  final Color? success;
  final Color? successContainer;
  final Color? pending;
  final Color? pendingContainer;
  final Color? info;
  final Color? infoContainer;

  StatusColors({
    this.error,
    this.errorContainer,
    this.success,
    this.successContainer,
    this.pending,
    this.pendingContainer,
    this.info,
    this.infoContainer,
  });

  @override
  ThemeExtension<StatusColors> copyWith({
    Color? error,
    Color? errorContainer,
    Color? success,
    Color? successContainer,
    Color? pending,
    Color? pendingContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return StatusColors(
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      pending: pending ?? this.pending,
      pendingContainer: pendingContainer ?? this.pendingContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  ThemeExtension<StatusColors> lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) {
      return this;
    }
    return StatusColors(
      error: Color.lerp(error, other.error, t),
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t),
      success: Color.lerp(success, other.success, t),
      successContainer: Color.lerp(successContainer, other.successContainer, t),
      pending: Color.lerp(pending, other.pending, t),
      pendingContainer: Color.lerp(pendingContainer, other.pendingContainer, t),
      info: Color.lerp(info, other.info, t),
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t),
    );
  }
}
