/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/screens/checkout/utils/index.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/delivery_location_page.dart';
import 'package:bagisto_app_demo/screens/home_page/widget/address_details_sheet.dart';
import 'package:bagisto_app_demo/utils/current_location_manager.dart';

// ignore: must_be_immutable
class GuestAddAddressForm extends StatefulWidget {
  Function(
      String? billingCompanyName,
      String? billingFirstName,
      String? billingLastName,
      String? billingAddress,
      String? billingAddress2,
      String? billingCountry,
      String? billingState,
      String? billingCity,
      String? billingPostCode,
      String? billingPhone,
      String? billingEmail,
      String? shippingEmail,
      String? shippingCompanyName,
      String? shippingFirstName,
      String? shippingLastName,
      String? shippingAddress,
      String? shippingAddress2,
      String? shippingCountry,
      String? shippingState,
      String? shippingCity,
      String? shippingPostCode,
      String? shippingPhone)? callBack;

  GuestAddAddressForm({this.callBack, Key? key}) : super(key: key);

  @override
  State<GuestAddAddressForm> createState() => _GuestAddAddressFormState();
}

class _GuestAddAddressFormState extends State<GuestAddAddressForm> {
  String? _displayAddress;
  final _nameController = TextEditingController(); // Replaces Email Controller
  
  // Internal controllers to hold data
  final _street1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _displayAddress = CurrentLocationManager.address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Blinkit Grey
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Guest Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              "Enter your name and delivery location",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // 1. NAME INPUT (Replaces Email)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Your Name",
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. LOCATION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FFF9), // Light Green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0C831F).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF0C831F), size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Deliver to Current Location",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0C831F)),
                        ),
                      ),
                      InkWell(
                        onTap: _openMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Text("CHANGE", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _displayAddress ?? "Tap button below to select address",
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _openAddressDetailsSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C831F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("USE THIS ADDRESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryLocationPage()),
    );
    if (result != null && result is Map) {
      setState(() {
        _displayAddress = result['address'];
      });
    }
  }

  void _openAddressDetailsSheet() {
    if (_nameController.text.trim().isEmpty) {
      ShowMessage.errorNotification("Please enter your name", context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: AddressDetailsSheet(initialArea: _displayAddress),
      ),
    ).then((value) {
      if (value != null && value is Map) {
        
        // --- 1. HANDLE NAME SPLITTING (Single Field -> First/Last) ---
        String fullName = _nameController.text.trim();
        String fName = fullName;
        String lName = "";
        if (fullName.contains(" ")) {
          int idx = fullName.lastIndexOf(" ");
          fName = fullName.substring(0, idx);
          lName = fullName.substring(idx + 1);
        }

        // --- 2. HANDLE "SOMEONE ELSE" NAME ---
        // If user selected "Someone else", use that name for Shipping
        String shipFName = fName;
        String shipLName = lName;
        if (value['firstName'] != null) {
          shipFName = value['firstName'];
          shipLName = value['lastName'] ?? "";
        }

        // --- 3. GENERATE DUMMY EMAIL ---
        // Backend needs email, so we create one using phone
        String phone = value['phone'] ?? "0000000000";
        String generatedEmail = "$phone@mobile.com";

        _street1Controller.text = "${value['flatHouseBuilding']}, ${value['landmark'] ?? ''}";
        _cityController.text = value['area'] ?? "";
        _phoneController.text = phone;
        _zipCodeController.text = CurrentLocationManager.pincode ?? "000000"; 
        _stateController.text = CurrentLocationManager.state ?? "State";
        
        // --- 4. TRIGGER CALLBACK ---
        widget.callBack!(
          "", // Company
          fName, // Billing First Name
          lName, // Billing Last Name
          _street1Controller.text, 
          value['area'], 
          "IN", // Country
          _stateController.text,
          _cityController.text,
          _zipCodeController.text,
          _phoneController.text,
          generatedEmail, // Billing Email (Generated)
          generatedEmail, // Shipping Email (Generated)
          "", // Ship Company
          shipFName, // Shipping First Name
          shipLName, // Shipping Last Name
          _street1Controller.text,
          value['area'],
          "IN",
          _stateController.text,
          _cityController.text,
          _zipCodeController.text,
          _phoneController.text,
        );
      }
    });
  }
}