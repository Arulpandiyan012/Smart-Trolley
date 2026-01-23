import 'package:flutter/material.dart';

class ModernCheckoutHeader extends StatelessWidget {
  final int currentStep; // 1 to 4
  final String total;

  const ModernCheckoutHeader({
    super.key,
    required this.currentStep,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.25 to 1.0)
    double progress = currentStep / 4;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(currentStep),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Step $currentStep/4",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Modern Progress Bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C831F), // Blinkit Green
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1: return "Address Details";
      case 2: return "Shipping Method";
      case 3: return "Payment Method";
      case 4: return "Review Order";
      default: return "Checkout";
    }
  }
}