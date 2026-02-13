import 'package:flutter/material.dart';

class PaymentSettingsScreen extends StatelessWidget {
  const PaymentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment Settings",
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "SAVED PAYMENT METHODS"),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                children: [
                   _buildPaymentTile(
                    context, 
                    Icons.credit_card, 
                    "•••• •••• •••• 4242", 
                    "Visa Debit Card",
                    trailing: const Text("EXP 12/26", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  _buildPaymentTile(
                    context, 
                    Icons.account_balance_wallet_outlined, 
                    "Smart Wallet", 
                    "Balance: ₹450.00",
                    trailing: Text("TOP UP", style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, "UPI METHODS"),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                children: [
                  _buildPaymentTile(context, Icons.account_balance, "amark@okicici", "Primary UPI ID", isVerified: true),
                  const Divider(height: 1),
                  _buildPaymentTile(context, Icons.add_circle_outline, "Add New UPI ID", "Google Pay, PhonePe, Paytm", isAction: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, "OTHER OPTIONS"),
            const SizedBox(height: 12),
            _buildCard(
              context,
              Column(
                children: [
                  _buildPaymentTile(context, Icons.credit_score_outlined, "Add New Card", "Visa, Mastercard, RuPay", isAction: true),
                  const Divider(height: 1),
                  _buildPaymentTile(context, Icons.account_balance_outlined, "Net Banking", "All major Indian banks", isAction: true),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Icon(Icons.security, size: 24, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    const Text(
                      "Secure & Encrypted Payments",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).primaryColor.withOpacity(0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPaymentTile(
    BuildContext context, 
    IconData icon, 
    String title, 
    String subtitle, {
    Widget? trailing, 
    bool isAction = false,
    bool isVerified = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isAction ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color, size: 22),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isAction ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, size: 14, color: Colors.blue),
          ]
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: Theme.of(context).dividerColor),
      onTap: () {},
    );
  }
}
