import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 

class ProfileDetailView extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool? subsNewsLetter;
  final ValueChanged<dynamic>? onChanged;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController dobController;
  final List<String>? genderValues;
  final int? currentGenderValue;
  final Function(int)? onGenderChanged;

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
    this.onGenderChanged,
    this.subsNewsLetter,
    this.onChanged,
  }) : super(key: key);

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
  
  // 🟢 VALIDATION LOGIC: Check for numbers in name
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    // This regex checks if the string contains only letters and spaces
    final nameRegExp = RegExp(r"^[a-zA-Z\s]+$");
    if (!nameRegExp.hasMatch(value)) {
      return "Please enter a valid $fieldName (letters only)";
    }
    return null;
  }

  Future<void> _showCalendar(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        widget.dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text, // Added keyboard type
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: label == "Date of Birth" ? const Icon(Icons.calendar_today, size: 20) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction, // Shows error as user types
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
            // 🟢 Name fields now use _validateName
            _buildTextField(
              controller: widget.firstNameController, 
              label: "First Name", 
              validator: (v) => _validateName(v, "First Name")
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.lastNameController, 
              label: "Last Name", 
              validator: (v) => _validateName(v, "Last Name")
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.emailController, 
              label: "Email", 
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? "Required" : null
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.phoneController, 
              label: "Phone Number",
              keyboardType: TextInputType.phone
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.dobController, 
              label: "Date of Birth", 
              readOnly: true, 
              onTap: () => _showCalendar(context)
            ),
            
            const SizedBox(height: AppSizes.spacingLarge),
            const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _buildGenderChips(),

            const SizedBox(height: AppSizes.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(StringConstants.subscribeToNewsletter.localized()),
                Switch(
                  value: widget.subsNewsLetter ?? false,
                  onChanged: (val) { if (widget.onChanged != null) widget.onChanged!(val); },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChips() {
    if (widget.genderValues == null) return const SizedBox();
    return Row(
      children: List.generate(widget.genderValues!.length, (index) {
        bool isSelected = widget.currentGenderValue == index;
        Color color = index == 0 ? Colors.blue : index == 1 ? Colors.pink : Colors.purple;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onGenderChanged?.call(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: (0.1)) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
              ),
              child: Column(
                children: [
                  Icon(index == 0 ? Icons.male : index == 1 ? Icons.female : Icons.transgender, 
                       color: isSelected ? color : Colors.grey),
                  Text(widget.genderValues![index], style: TextStyle(color: isSelected ? color : Colors.black54)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}