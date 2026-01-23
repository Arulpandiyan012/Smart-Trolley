
import 'package:flutter/material.dart';

class OtpExplanationScreen extends StatelessWidget {
  const OtpExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: Column(
        children: [
          // ---------------------------------------------------------
          // 1. GREEN HEADER
          // ---------------------------------------------------------
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF81C784), // Light Green
                  Color(0xFF2E7D32), // Darker Green
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30), // Dynamic height with padding
            child: Column(
              children: [
                 Row(
                   children: [
                     InkWell(
                       onTap: () => Navigator.pop(context),
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.2),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.arrow_back, color: Colors.white),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 10), // Reduced spacing
                 const Icon(Icons.verified_user_outlined, size: 50, color: Colors.white), // Reduced icon size
                 const SizedBox(height: 10), // Reduced spacing
                 const Text(
                   "OTP Verification",
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   "Secure & Fast Login Guide",
                   style: TextStyle(
                     color: Colors.white.withOpacity(0.9),
                     fontSize: 14,
                   ),
                 ),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // 2. SCROLLABLE CONTENT (STEPS)
          // ---------------------------------------------------------
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Scroll only if needed to avoid crash
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildStepCard(
                      context,
                      step: "01",
                      icon: Icons.dialpad,
                      iconColor: Colors.blue,
                      iconBg: Colors.blue.withOpacity(0.1),
                      title: "Enter Mobile Number",
                      subtitle: "Enter your 10-digit number on the login screen.",
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      context,
                      step: "02",
                      icon: Icons.chat_bubble_outline,
                      iconColor: Colors.orange,
                      iconBg: Colors.orange.withOpacity(0.1),
                      title: "Receive SMS Code",
                      subtitle: "You will receive a 6-digit OTP via SMS.",
                    ),
                    const SizedBox(height: 10),
                    _buildStepCard(
                      context,
                      step: "03",
                      icon: Icons.lock_outline,
                      iconColor: Colors.green,
                      iconBg: Colors.green.withOpacity(0.1),
                      title: "Enter Verification Code",
                      subtitle: "Type the code to verify your identity instantly.",
                    ),
                    const SizedBox(height: 10),
                     _buildStepCard(
                      context,
                      step: "04",
                      icon: Icons.support_agent,
                      iconColor: Colors.purple,
                      iconBg: Colors.purple.withOpacity(0.1),
                      title: "Need Help?",
                      subtitle: "Didn't get it? Wait 30s and tap 'Resend'.",
                    ),
                    
                    const SizedBox(height: 20),

                    // ---------------------------------------------------------
                    // 3. BOTTOM BUTTON
                    // ---------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20), // Dark Green
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Got it!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, {
    required String step,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced from 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
