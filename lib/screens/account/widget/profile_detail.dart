/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 

class ProfileDetailView extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool? subsNewsLetter;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<int>? onGenderChanged; 
  
  // Controllers
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController dobController;
  
  final List<String>? genderValues;
  final int? currentGenderValue;

  const ProfileDetailView({
    Key? key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.dobController,
    this.genderValues,
    this.currentGenderValue,
    this.subsNewsLetter,
    this.onChanged,
    this.onGenderChanged,
  }) : super(key: key);

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
  
  Widget _buildGenderCard(int index, String label, IconData icon) {
    bool isSelected = (widget.currentGenderValue == index);
    Color color = isSelected ? Colors.blue : Colors.grey;
    Color bgColor = isSelected ? Colors.blue.withOpacity(0.05) : const Color(0xFFF5F5F5);
    // Use Hex color for safety
    Color borderColor = isSelected ? Colors.blue : const Color(0xFFE0E0E0); 

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.onGenderChanged != null) {
            widget.onGenderChanged!(index);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label, 
                style: TextStyle(
                  color: color, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
    bool isRequired = false, 
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: widget.firstNameController,
              label: StringConstants.firstNameLabel.localized(),
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
              isRequired: true, 
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            _buildTextField(
              controller: widget.lastNameController,
              label: StringConstants.lastNameLabel.localized(),
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
              isRequired: true, 
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.emailController,
              label: "Email",
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
              isRequired: true, 
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.phoneController,
              label: "Phone Number",
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
              isRequired: true,
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.dobController,
              label: "Date of Birth",
              hint: "dd-mm-yyyy",
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
              isRequired: true,
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900), 
                  lastDate: DateTime.now(),
                );
                
                if (pickedDate != null) {
                  // Format: dd-mm-yyyy
                  String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                  setState(() {
                    widget.dobController.text = formattedDate;
                  });
                }
              },
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // Gender Label - Non-const to allow flexible types
            RichText(
              text: TextSpan(
                text: "Gender",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                children: [
                   const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            if (widget.genderValues != null && widget.genderValues!.isNotEmpty)
              Row(
                children: [
                  _buildGenderCard(0, "Male", Icons.male),
                  const SizedBox(width: 8),
                  _buildGenderCard(1, "Female", Icons.female),
                  const SizedBox(width: 8),
                  _buildGenderCard(2, "Other", Icons.transgender), 
                ],
              ),
              
            const SizedBox(height: AppSizes.spacingMedium),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Colors.grey[100] safe alternative
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                     padding: const EdgeInsets.all(8),
                     decoration: const BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.notifications_none, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.subscribeToNewsletter.localized(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Get the latest updates",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: widget.subsNewsLetter ?? false,
                    onChanged: (val) {
                      if (widget.onChanged != null) widget.onChanged!(val);
                    },
                    activeColor: Colors.green, 
                    inactiveThumbColor: const Color(0xFF9E9E9E), // Grey 500
                    inactiveTrackColor: const Color(0xFFE0E0E0), // Grey 300 
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}