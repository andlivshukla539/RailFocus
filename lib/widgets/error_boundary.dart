// lib/widgets/error_boundary.dart
import 'package:flutter/material.dart';

class ErrorBoundary {
  static void setupGlobalErrorHandler() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF131620), // _P.panel
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFB83838)),
                const SizedBox(height: 24),
                const Text(
                  'ROUTING ERROR',
                  style: TextStyle(
                    fontFamily: 'Cormorant Garamond',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFFF5EDDB), // _P.cream
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 12,
                    color: Color(0xFF9A8E78), // _P.t2
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
}