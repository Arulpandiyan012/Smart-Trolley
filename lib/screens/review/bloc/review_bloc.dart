/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/review/utils/index.dart';

class ReviewsBloc extends Bloc<ReviewsBaseEvent, ReviewsBaseState> {
  ReviewsRepository? repository;
  BuildContext? context;

  ReviewsBloc({@required this.repository, this.context})
      : super(ReviewInitialState()) {
    on<ReviewsBaseEvent>(mapEventToState);
  }

  void mapEventToState(
      ReviewsBaseEvent event, Emitter<ReviewsBaseState> emit) async {
    if (event is FetchReviewsEvent) {
      try {
        ReviewModel reviewModel = await repository!.callReviewApi(event.page);

        emit(FetchReviewState.success(reviewModel: reviewModel));
      } catch (e) {
        emit(FetchReviewState.fail(
            error: StringConstants.somethingWrong.localized()));
      }
    } else if (event is RemoveReviewEvent) {
      try {
        BaseModel? baseModel = await repository!.callDeleteReviewApi(event.reviewId ?? "");
        if (baseModel?.success == true || baseModel?.status == true) {
          // Re-fetch reviews to update the list
          ReviewModel reviewModel = await repository!.callReviewApi(1);
          emit(FetchReviewState.success(reviewModel: reviewModel));
        } else {
          emit(FetchReviewState.fail(error: baseModel?.message ?? "Failed to delete"));
        }
      } catch (e) {
        emit(FetchReviewState.fail(error: e.toString()));
      }
    }
  }
}
