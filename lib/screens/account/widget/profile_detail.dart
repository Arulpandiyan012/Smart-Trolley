import 'package:flutter/material.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:intl/intl.dart'; 

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
  
  // 🟢 VALIDATION: Letters only for Names
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    final nameRegExp = RegExp(r"^[a-zA-Z\s]+$");
    if (!nameRegExp.hasMatch(value)) {
      return "Please enter a valid $fieldName (letters only)";
    }
    return null;
  }

  // 🟢 DATE PICKER: Day-Month-Year format
  Future<void> _showCalendar(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        widget.dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  // 🟢 HELPER: Builds label with optional red asterisk
  Widget _buildFieldLabel(String label, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false, // New parameter
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            // Removed labelText to use the custom label above for the asterisk effect
            hintText: "Enter $label", 
            prefixIcon: label == "Date of Birth" ? const Icon(Icons.calendar_today, size: 20) : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSubscribed = widget.subsNewsLetter ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: widget.firstNameController, 
              label: "First Name", 
              isRequired: true, // Added required
              validator: (v) => _validateName(v, "First Name")
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.lastNameController, 
              label: "Last Name", 
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.emailController, 
              label: "Email", 
              isRequired: true, // Added required
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? "Required" : null
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            _buildTextField(
              controller: widget.phoneController, 
              label: "Phone Number",
              isRequired: true, // Added required
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? "Required" : null
            ),
            const SizedBox(height: AppSizes.spacingMedium),

            _buildTextField(
              controller: widget.dobController, 
              label: "Date of Birth", 
              readOnly: true, 
              onTap: () => _showCalendar(context)
            ),
            
            const SizedBox(height: AppSizes.spacingLarge),
            _buildFieldLabel("Gender", true), // Gender is required
            const SizedBox(height: 12),

            _buildGenderChips(),

            const SizedBox(height: AppSizes.spacingLarge),
            
            // 🟢 TRENDY NEWSLETTER SECTION
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSubscribed ? Colors.green.withValues(alpha: 0.08) : Colors.grey[100],
                border: Border.all(
                  color: isSubscribed ? Colors.green.withValues(alpha: 0.5) : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSubscribed ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSubscribed ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.subscribeToNewsletter.localized(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSubscribed ? Colors.green[800] : Colors.black87,
                          ),
                        ),
                        Text(
                          isSubscribed ? "You're on the list!" : "Get the latest updates",
                          style: TextStyle(
                            fontSize: 12,
                            color: isSubscribed ? Colors.green[600] : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    activeColor: Colors.greenAccent[700],
                    activeTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[400],
                    value: isSubscribed,
                    onChanged: (val) {
                      if (widget.onChanged != null) widget.onChanged!(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
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
                color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!, 
                  width: isSelected ? 2 : 1
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    index == 0 ? Icons.male : index == 1 ? Icons.female : Icons.transgender, 
                    color: isSelected ? color : Colors.grey
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.genderValues![index], 
                    style: TextStyle(
                      color: isSelected ? color : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}