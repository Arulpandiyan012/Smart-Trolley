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
import 'package:bagisto_app_demo/screens/account/widget/profile_image_view.dart';
import 'package:bagisto_app_demo/screens/account/widget/account_loader_view.dart';

GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with EmailValidator, PhoneNumberValidator {
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
  XFile? pickedFile; // 🟢 NEW: Store picked file here
  AccountInfoBloc? accountInfoBloc;
  bool subscribeNewsletter = false;

  @override
  void initState() {
    super.initState();
    accountInfoBloc = context.read<AccountInfoBloc>();
    accountInfoBloc?.add(AccountInfoDetailsEvent());
    _loadAccountData();
  }

  String _formatDob(String dob) {
    if (dob.isEmpty || dob == "0000-00-00") return "";
    // If it's yyyy-MM-dd, convert to dd-MM-yyyy
    if (dob.contains("-")) {
      var parts = dob.split("-");
      if (parts.length == 3 && parts[0].length == 4) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }
    return dob;
  }

  void _loadAccountData() {
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    if (isLoggedIn) {
      // 🟢 ROBUST NAME LOADING: Read distinct fields first
      String fName = appStoragePref.getCustomerFirstName();
      String lName = appStoragePref.getCustomerLastName();
      
      if (fName.isNotEmpty || lName.isNotEmpty) {
          firstNameController.text = fName;
          lastNameController.text = lName;
      } else {
          // Fallback to legacy name splitting if individual fields are empty
          String fullName = appStoragePref.getCustomerName();
          List<String> names = fullName.split(" ");
          firstNameController.text = names.isNotEmpty ? names.first : "";
          if (names.length > 1) {
            lastNameController.text = names.sublist(1).join(" ");
          }
      }
      
      emailController.text = appStoragePref.getCustomerEmail();
      String storedPhone = appStoragePref.getCustomerPhone();
      // 🟢 REVERT: Removed Strict Sanitization
      phoneController.text = storedPhone;

      dobController.text = _formatDob(appStoragePref.getCustomerDob());
      
      // 🟢 Initialize gender from storage
      String gender = appStoragePref.getCustomerGender().toLowerCase();
      if (gender.contains("female")) {
        currentGenderValue = 1;
      } else if (gender.contains("other")) {
        currentGenderValue = 2;
      } else {
        currentGenderValue = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
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

        /// ✅ FIXED BOTTOM SAVE BUTTON (SAFE AREA AWARE)
        bottomNavigationBar: SafeArea(
          top: false,
          child: BlocBuilder<AccountInfoBloc, AccountInfoBaseState>(
            builder: (context, state) {
              bool isLoading = (state is AccountInfoUpdateState &&
                  state.status != AccountStatus.success &&
                  state.status != AccountStatus.fail);

              final bottomInset =
                  MediaQuery.of(context).viewPadding.bottom;

              return Container(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.spacingMedium,
                  AppSizes.spacingMedium,
                  AppSizes.spacingMedium,
                  AppSizes.spacingMedium + bottomInset,
                ),
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
                child: SizedBox(
                  height: 55,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onPressSaveButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            StringConstants.save
                                .localized()
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileBloc(BuildContext context) {
    return BlocConsumer<AccountInfoBloc, AccountInfoBaseState>(
      listener: (context, state) {
        if (state is AccountInfoUpdateState) {
          if (state.status == AccountStatus.success &&
              (state.accountUpdate?.status == true || state.accountUpdate?.success == true)) {
            ShowMessage.successNotification(
                state.accountUpdate?.message ?? StringConstants.updatedSuccessfully.localized(), context);
            _updateSharedPreferences(state.accountUpdate!);
            // 🟢 FORCE REFRESH: Reload fields from updated storage immediately
            _loadAccountData(); 
            // Removed Auto-Pop: Allow user to see the "Saved" reflection on the screen
          } else if (state.status == AccountStatus.fail) {
            ShowMessage.errorNotification(
              state.error ?? state.accountUpdate?.graphqlErrors ??
                  StringConstants.invalidData.localized(),
              context,
            );
          }
        }
      },
      builder: (context, state) => buildUI(context, state),
    );
  }

  Widget buildUI(BuildContext context, AccountInfoBaseState state) {
    if (state is AccountInfoDetailState &&
        state.status == AccountStatus.success) {
      if (isLoad) {
        isLoad = false;
        _accountInfoDetails = state.accountInfoDetails;
        if (_accountInfoDetails != null) {
          firstNameController.text =
              _accountInfoDetails!.firstName ?? "";
          lastNameController.text =
              _accountInfoDetails!.lastName ?? "";
          emailController.text = _accountInfoDetails!.email ?? "";
          phoneController.text = _accountInfoDetails!.phone ?? "";
          dobController.text =
              _formatDob(_accountInfoDetails!.dateOfBirth ?? "");
          subscribeNewsletter =
              _accountInfoDetails!.subscribedToNewsLetter ?? false;
          
          // 🟢 ROBUST GENDER MAPPING (Case Insensitive)
          String gender = (_accountInfoDetails!.gender?.toLowerCase() ?? "");
          if (gender.contains("female")) {
            currentGenderValue = 1;
          } else if (gender.contains("other")) {
            currentGenderValue = 2;
          } else {
            currentGenderValue = 0; // Default Male
          }
        }
      }
    }

    if (state is InitialAccountState) {
      return const AccountLoaderView();
    }

    return SafeArea(
      child: ProfileDetailView(
        formKey: _formKey,
        upperChild: ProfileImageView(
          pickedFile: pickedFile,
          callback: (base64, file) {
            base64string = base64;
            pickedFile = file;
          },
        ),
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        emailController: emailController,
        phoneController: phoneController,
        dobController: dobController,
        subsNewsLetter: subscribeNewsletter,
        genderValues: genderValues,
        currentGenderValue: currentGenderValue,
        onGenderChanged: (index) {
          setState(() => currentGenderValue = index);
        },
        onChanged: (value) {
          setState(() => subscribeNewsletter = value);
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
        subscribedToNewsLetter: subscribeNewsletter,
      ));
    }
  }

  void _updateSharedPreferences(AccountUpdate accountUpdate) {
    appStoragePref.setCustomerLoggedIn(true);
    
    // 🟢 OPTIMISTIC OVERWRITE: 
    // The server often returns stale data. We must trust the UI input which the user just saved.
    String fName = firstNameController.text.trim();
    String lName = lastNameController.text.trim();
    String eMail = emailController.text.trim();
    String phone = phoneController.text.trim();
    String dob = dobController.text.trim();
    
    appStoragePref.setCustomerName("$fName $lName".trim());
    appStoragePref.setCustomerFirstName(fName);
    appStoragePref.setCustomerLastName(lName);
    appStoragePref.setCustomerEmail(eMail);
    appStoragePref.setCustomerPhone(phone);
    
    // Convert back to YYYY-MM-DD for storage if needed, or store as is if consistent
    // For now, storing as is since we control the display format
    appStoragePref.setCustomerDob(dob); 
        
    var data = accountUpdate.data;
    if (data != null) {
      // Only read fields not editable in this screen form if any
      appStoragePref.setCustomerGender(data.gender ?? "");

      
      // 🟢 ENSURE IMAGE IS SAVED
      String image = data.imageUrl ?? "";
      if (image.isNotEmpty) {
        appStoragePref.setCustomerImage(image);
      }

      // 🟢 BROADCAST
      GlobalData.profileUpdateStream.add({
        "image": image,
        "name": "$fName $lName".trim()
      });

      // 🟢 SYNC FULL MODEL: Helper for Drawer/Header listeners
      // DrawerListView listens to 'customerDetails' key, not individual fields.
      // We must construct and save the full model to trigger the UI update.
      AccountInfoModel updatedModel = AccountInfoModel(
        firstName: fName,
        lastName: lName,
        name: "$fName $lName".trim(),
        email: eMail,
        phone: phone,
        dateOfBirth: dob,
        gender: data.gender ?? "",
        imageUrl: image.isNotEmpty ? image : appStoragePref.getCustomerImage(),
        subscribedToNewsLetter: subscribeNewsletter,
        id: appStoragePref.getCustomerId().toString()
      );
      appStoragePref.setCustomerDetails(updatedModel);
    }
  }
}
