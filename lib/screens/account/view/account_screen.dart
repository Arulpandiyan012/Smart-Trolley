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

GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

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
        appBar: AppBar(
          centerTitle: false,
          title: Text(StringConstants.accountInfo.localized()),
        ),
        body: _profileBloc(context),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          child: MaterialButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.spacingNormal)),
            elevation: 2.0,
            height: AppSizes.buttonHeight,
            minWidth: MediaQuery.of(context).size.width,
            // 🟢 FIXED: Replaced onBackground with onSurface
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: _onPressSaveButton,
            child: Text(
              StringConstants.save.localized().toUpperCase(),
              style: TextStyle(
                fontSize: AppSizes.spacingLarge, 
                color: Theme.of(context).colorScheme.secondaryContainer
              ),
            ),
          ),
        ),
      ),
    );
  }

  _profileBloc(BuildContext context) {
    return BlocConsumer<AccountInfoBloc, AccountInfoBaseState>(
      listener: (context, state) {
        if (state is AccountInfoUpdateState) {
          if (state.status == AccountStatus.success && state.accountUpdate?.status == true) {
            ShowMessage.successNotification(state.accountUpdate?.message ?? "", context);
            _updateSharedPreferences(state.accountUpdate!);
            Navigator.pop(context, true);
          } else {
            ShowMessage.errorNotification(StringConstants.invalidData.localized(), context);
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
          
          // 🟢 FIXED: Default to 0 as the model lacks a gender field
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

  _onPressSaveButton() {
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

  _updateSharedPreferences(AccountUpdate accountUpdate) {
    appStoragePref.setCustomerLoggedIn(true);
    var data = accountUpdate.data;
    if (data != null) {
      appStoragePref.setCustomerName("${data.firstName ?? ""} ${data.lastName ?? ""}".trim());
      appStoragePref.setCustomerEmail(data.email ?? "");
      appStoragePref.setCustomerImage(data.imageUrl ?? "");
    }
  }
}