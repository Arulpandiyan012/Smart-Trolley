/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/data_model/account_models/account_update_model.dart';
import 'package:bagisto_app_demo/data_model/account_models/account_info_details.dart';
import 'package:bagisto_app_demo/screens/account/utils/index.dart';
import 'package:bagisto_app_demo/utils/shared_preference_helper.dart'; 
import 'package:bagisto_app_demo/utils/string_constants.dart';
import 'package:bagisto_app_demo/utils/index.dart'; 
import 'package:bagisto_app_demo/screens/account/widget/profile_detail.dart';
import 'package:bagisto_app_demo/screens/account/widget/account_loader_view.dart';
//import 'package:bagisto_app_demo/widgets/common_widgets.dart';

GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with EmailValidator, PhoneNumberValidator {
  
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  
  bool isLoggedIn = false;
  List<String> genderValues = ["Male", "Female", "Other"];
  int currentGenderValue = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  AccountInfoModel? _accountInfoDetails;
  bool isLoad = true;
  String? base64string;
  AccountInfoBloc? accountInfoBloc;
  bool subscribeNewsletter = false;

  @override
  void initState() {
    super.initState();
    accountInfoBloc = context.read<AccountInfoBloc>();
    accountInfoBloc?.add(AccountInfoDetailsEvent());
    _loadAccountData();
  }

  void _loadAccountData() {
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    if (isLoggedIn) {
      String fullName = appStoragePref.getCustomerName(); 
      List<String> names = fullName.split(" ");
      firstNameController.text = names.isNotEmpty ? names.first : "";
      if (names.length > 1) {
        lastNameController.text = names.sublist(1).join(" ");
      }
      emailController.text = appStoragePref.getCustomerEmail(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        // 🟢 FIXED: Changed 'app_bar' to 'appBar'
        appBar: AppBar( 
          centerTitle: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            StringConstants.accountInfo.localized(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _profileBloc(context),
        
        bottomNavigationBar: BlocBuilder<AccountInfoBloc, AccountInfoBaseState>(
          builder: (context, state) {
            // Check if we are currently saving/loading
            bool isLoading = (state is AccountInfoUpdateState && 
                              state.status != AccountStatus.success && 
                              state.status != AccountStatus.fail);

            return Container(
              padding: const EdgeInsets.all(AppSizes.spacingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onPressSaveButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          StringConstants.save.localized().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, 
                            color: Colors.white, letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileBloc(BuildContext context) {
    return BlocConsumer<AccountInfoBloc, AccountInfoBaseState>(
      listener: (context, state) {
        if (state is AccountInfoUpdateState) {
          if (state.status == AccountStatus.success && state.accountUpdate?.status == true) {
            ShowMessage.successNotification(state.accountUpdate?.message ?? "", context);
            _updateSharedPreferences(state.accountUpdate!);
            Navigator.pop(context, true);
          } 
          // 🟢 FIXED: Changed .error to .fail
          else if (state.status == AccountStatus.fail) {
            ShowMessage.errorNotification(
              state.accountUpdate?.graphqlErrors ?? StringConstants.invalidData.localized(), 
              context
            );
          }
        }
      },
      builder: (context, state) => buildUI(context, state),
    );
  }

  Widget buildUI(BuildContext context, AccountInfoBaseState state) {
    if (state is AccountInfoDetailState && state.status == AccountStatus.success) {
      if (isLoad) {
        isLoad = false;
        _accountInfoDetails = state.accountInfoDetails;
        if (_accountInfoDetails != null) {
          firstNameController.text = _accountInfoDetails!.firstName ?? "";
          lastNameController.text = _accountInfoDetails!.lastName ?? "";
          emailController.text = _accountInfoDetails!.email ?? "";
          phoneController.text = _accountInfoDetails!.phone ?? "";
          dobController.text = _accountInfoDetails!.dateOfBirth ?? "";
          subscribeNewsletter = _accountInfoDetails!.subscribedToNewsLetter ?? false;
          currentGenderValue = 0; 
        }
      }
    }

    if (state is InitialAccountState) return const AccountLoaderView();

    return SafeArea(
      child: ProfileDetailView(
        formKey: _formKey,
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        emailController: emailController,
        phoneController: phoneController,
        dobController: dobController,
        subsNewsLetter: subscribeNewsletter,
        genderValues: genderValues,
        currentGenderValue: currentGenderValue,
        onGenderChanged: (index) {
          setState(() {
            currentGenderValue = index;
          });
        },
        onChanged: (value) {
          setState(() {
            subscribeNewsletter = value;
          });
        },
      ),
    );
  }

  void _onPressSaveButton() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      accountInfoBloc?.add(AccountInfoUpdateEvent(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        gender: genderValues[currentGenderValue],
        email: emailController.text,
        dob: dobController.text,
        phone: phoneController.text,
        oldPassword: "", 
        password: "",
        confirmPassword: "",
        avatar: base64string ?? "",
        subscribedToNewsLetter: subscribeNewsletter
      ));
    }
  }

  void _updateSharedPreferences(AccountUpdate accountUpdate) {
    appStoragePref.setCustomerLoggedIn(true);
    var data = accountUpdate.data;
    if (data != null) {
      String fName = data.firstName ?? "";
      String lName = data.lastName ?? "";
      appStoragePref.setCustomerName("$fName $lName".trim());
      appStoragePref.setCustomerEmail(data.email ?? "");
      appStoragePref.setCustomerImage(data.imageUrl ?? "");
    }
  }
}