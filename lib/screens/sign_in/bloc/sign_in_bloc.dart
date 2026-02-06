/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/data_model/account_models/account_info_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

// 🟢 1. Import Global Utils to access 'appStoragePref'
import 'package:bagisto_app_demo/utils/index.dart';

import 'package:bagisto_app_demo/screens/sign_in/utils/index.dart';

class SignInBloc extends Bloc<SignInBaseEvent, SignInBaseState> {
  SignInRepository? repository;

  SignInBloc({@required this.repository}) : super(InitialState()) {
    on<SignInBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      SignInBaseEvent event, Emitter<SignInBaseState> emit) async {
    if (event is FetchSignInEvent) {
      try {
        SignInModel signInModel = await repository!
            .callSignInApi(event.email ?? "", event.password ?? "");
        
        print("Sign In API Success Status: ${signInModel.success}");
        
        if (signInModel.success == true) {
          // 🟢 2. FORCE SAVE TOKEN & LOGIN STATUS
          // This is the critical fix for "Unauthenticated" errors
          if (signInModel.token != null) {
            await appStoragePref.setCustomerToken(signInModel.token!);
            print("✅ Token Saved: ${signInModel.token}"); 
          } else {
            print("⚠️ Warning: Token is NULL in response!");
          }

          await appStoragePref.setCustomerLoggedIn(true);
          await appStoragePref.setCustomerEmail(event.email ?? "");
          
          print("🔑 LOGIN SUCCESS - Data Present: ${signInModel.data != null}");

          // 🟢 3. SAVE FULL PROFILE DATA
          if (signInModel.data != null) {
            var data = signInModel.data!;
            String fName = data.firstName ?? "";
            String lName = data.lastName ?? "";
            String fullName = data.name ?? "$fName $lName".trim();
            
            await appStoragePref.setCustomerName(fullName);
            await appStoragePref.setCustomerFirstName(fName);
            await appStoragePref.setCustomerLastName(lName);
            await appStoragePref.setCustomerId(int.tryParse(data.id ?? "0") ?? 0);
            await appStoragePref.setCustomerImage(data.imageUrl ?? "");
            await appStoragePref.setCustomerPhone(data.phone?.toString() ?? "");
            await appStoragePref.setCustomerGender(data.gender ?? "");
            await appStoragePref.setCustomerDob(data.dateOfBirth ?? "");

            // Sync full model for listeners
            AccountInfoModel model = AccountInfoModel(
              id: data.id,
              email: data.email,
              firstName: fName,
              lastName: lName,
              name: fullName,
              imageUrl: data.imageUrl,
              dateOfBirth: data.dateOfBirth,
              phone: data.phone?.toString(),
              gender: data.gender,
            );
            await appStoragePref.setCustomerDetails(model);

            // 🟢 4. BROADCAST UPDATE: For instant Sidebar/Home sync
            print("💾 STORAGE SYNC: Name='$fullName', Email='${data.email}', ID='${data.id}'");
            GlobalData.profileUpdateStream.add({
              "image": data.imageUrl ?? "",
              "name": fullName
            });
          }

          emit(FetchSignInState.success(
              signInModel: signInModel, 
              successMsg: signInModel.message ?? "", 
              fingerPrint: event.fingerPrint
          ));
        } else {
          emit(FetchSignInState.fail(
              error: signInModel.graphqlErrors ?? "", 
              fingerPrint: event.fingerPrint
          ));
        }
      } catch (e) {
        print("Sign In Bloc Error: $e");
        emit(FetchSignInState.fail(
            error: e.toString(), 
            fingerPrint: event.fingerPrint
        ));
      }
    } else if (event is SocialLoginEvent) {
      try {
        SignInModel? signUpResponseModel = await repository!.socialLogin(
            event.email ?? "",
            event.firstName ?? "",
            event.lastName ?? "",
            event.phone ?? "",
            event.signUpType ?? "");

        if (signUpResponseModel?.status == true) {
          // 🟢 3. Force Save for Social Login too
          if (signUpResponseModel?.token != null) {
            await appStoragePref.setCustomerToken(signUpResponseModel!.token!);
          }
          await appStoragePref.setCustomerLoggedIn(true);

          // 🟢 5. SAVE FULL PROFILE DATA (Social)
          if (signUpResponseModel?.data != null) {
              var data = signUpResponseModel!.data!;
              String fName = data.firstName ?? "";
              String lName = data.lastName ?? "";
              String fullName = data.name ?? "$fName $lName".trim();
              
              await appStoragePref.setCustomerName(fullName);
              await appStoragePref.setCustomerFirstName(fName);
              await appStoragePref.setCustomerLastName(lName);
              await appStoragePref.setCustomerId(int.tryParse(data.id ?? "0") ?? 0);
              await appStoragePref.setCustomerImage(data.imageUrl ?? "");
              await appStoragePref.setCustomerPhone(data.phone?.toString() ?? "");
              await appStoragePref.setCustomerGender(data.gender ?? "");
              await appStoragePref.setCustomerDob(data.dateOfBirth ?? "");

              // Sync full model
              AccountInfoModel model = AccountInfoModel(
                id: data.id,
                email: data.email,
                firstName: fName,
                lastName: lName,
                name: fullName,
                imageUrl: data.imageUrl,
                dateOfBirth: data.dateOfBirth,
                phone: data.phone?.toString(),
                gender: data.gender,
              );
              await appStoragePref.setCustomerDetails(model);

              // 🟢 6. BROADCAST UPDATE
              GlobalData.profileUpdateStream.add({
                "image": data.imageUrl ?? "",
                "name": fullName
              });
          }

          emit(SocialLoginState.success(signInModel: signUpResponseModel));
        } else {
          emit(SocialLoginState.fail(
              error: signUpResponseModel?.graphqlErrors ?? ""));
        }
      } catch (e) {
        emit(SocialLoginState.fail(error: e.toString()));
      }
    }
  }
}