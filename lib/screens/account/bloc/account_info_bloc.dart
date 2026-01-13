/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data_model/account_models/account_info_details.dart';
import '../../../data_model/account_models/account_update_model.dart';
import '../../../data_model/graphql_base_model.dart';
import 'account_info_event.dart';
import 'account_info_state.dart';
import 'account_info_repository.dart';

class AccountInfoBloc extends Bloc<AccountInfoBaseEvent, AccountInfoBaseState> {
  AccountInfoRepository? repository;

  AccountInfoBloc({@required this.repository}) : super(InitialAccountState()) {
    on<AccountInfoBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      AccountInfoBaseEvent event, Emitter<AccountInfoBaseState> emit) async {
    if (event is AccountInfoDetailsEvent) {
      try {
        AccountInfoModel? accountInfoDetails =
            await repository!.callAccountDetailsApi();
        if (accountInfoDetails != null) {
          emit(AccountInfoDetailState.success(
              accountInfoDetails: accountInfoDetails));
        } else {
          emit(AccountInfoDetailState.fail(error: "Failed to fetch details"));
        }
      } catch (e) {
        emit(AccountInfoDetailState.fail(error: e.toString()));
      }
    } else if (event is AccountInfoUpdateEvent) {
      try {
        // ✅ Call Repository with correct arguments (No passwords)
        AccountUpdate? accountUpdate = await repository!.callAccountUpdateApi(
            event.firstName ?? "",
            event.lastName ?? "",
            event.email ?? "",
            event.gender ?? "",
            event.dob ?? "",
            event.phone ?? "",
            event.avatar ?? "",
            event.subscribedToNewsLetter ?? false);

        if (accountUpdate != null) {
          // ✅ FIX: Use ?.message to handle null safety
          emit(AccountInfoUpdateState.success(
              accountUpdate: accountUpdate, 
              successMsg: accountUpdate.message ?? "Updated Successfully"));
        } else {
          emit(AccountInfoUpdateState.fail(error: "Update returned null"));
        }
      } catch (e) {
        emit(AccountInfoUpdateState.fail(error: e.toString()));
      }
    } else if (event is AccountInfoDeleteEvent) {
      try {
        BaseModel? baseModel =
            await repository?.callDeleteAccountApi(event.password ?? "");
        if (baseModel?.success == true) {
          emit(AccountInfoDeleteState.success(
              baseModel: baseModel, successMsg: baseModel?.message));
        } else {
          emit(AccountInfoDeleteState.fail(
              error: baseModel?.message ?? baseModel?.graphqlErrors));
        }
      } catch (e) {
        emit(AccountInfoDeleteState.fail(error: e.toString()));
      }
    }
  }
}