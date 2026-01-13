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
  final ValueChanged<dynamic>? onChanged;
  
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
  }) : super(key: key);

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
  
  // Helper to build Text Fields safely
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: validator,
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
              // 🟢 FIX: Use hardcoded string if constant is missing
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            _buildTextField(
              controller: widget.lastNameController,
              label: StringConstants.lastNameLabel.localized(),
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.emailController,
              // 🟢 FIX: Use hardcoded string to avoid 'emailLabel' error
              label: "Email",
              validator: (v) => (v?.isEmpty ?? true) ? "This field is required" : null,
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.phoneController,
              // 🟢 FIX: Use hardcoded string
              label: "Phone Number",
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.dobController,
              // 🟢 FIX: Use hardcoded string
              label: "Date of Birth",
              hint: "YYYY-MM-DD",
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            // Gender Dropdown
            if (widget.genderValues != null && widget.genderValues!.isNotEmpty)
              DropdownButtonFormField<String>(
                value: widget.genderValues!.length > (widget.currentGenderValue ?? 0) 
                    ? widget.genderValues![widget.currentGenderValue ?? 0] 
                    : widget.genderValues![0],
                items: widget.genderValues!.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (_) {}, 
                decoration: const InputDecoration(
                  // 🟢 FIX: Use hardcoded string
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
              ),
              
            const SizedBox(height: AppSizes.spacingMedium),

            // Newsletter Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(StringConstants.subscribeToNewsletter.localized()),
                Switch(
                  value: widget.subsNewsLetter ?? false,
                  onChanged: (val) {
                    if (widget.onChanged != null) widget.onChanged!(val);
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}