/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/utils/app_constants.dart';
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/screens/account/bloc/account_info_bloc.dart';
import 'package:bagisto_app_demo/screens/account/bloc/account_info_event.dart';

class ChangeEmailAndPasswordView extends StatefulWidget {
  const ChangeEmailAndPasswordView({Key? key}) : super(key: key);

  @override
  State<ChangeEmailAndPasswordView> createState() => _ChangeEmailAndPasswordState();
}

class _ChangeEmailAndPasswordState extends State<ChangeEmailAndPasswordView> {
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();
  final deleteAccountPassword = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Change Password", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: currentPasswordController,
              label: StringConstants.currentPassword.localized(),
              isPassword: true,
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: newPasswordController,
              label: StringConstants.newPassword.localized(),
              isPassword: true,
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: confirmNewPasswordController,
              label: StringConstants.confirmPassword.localized(),
              isPassword: true,
              validator: (val) {
                if (val != newPasswordController.text) {
                  return StringConstants.matchPassword.localized();
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            Text("Delete Account", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
            const SizedBox(height: 10),
            _buildTextField(
              controller: deleteAccountPassword,
              label: "Confirm Password to Delete",
              isPassword: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (deleteAccountPassword.text.isNotEmpty) {
                  context.read<AccountInfoBloc>().add(AccountInfoDeleteEvent(password: deleteAccountPassword.text));
                }
              },
              child: const Text("DELETE ACCOUNT", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}