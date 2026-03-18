/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */



import  'package:bagisto_app_demo/screens/review/utils/index.dart';
import 'package:bagisto_app_demo/data_model/app_route_arguments.dart';

//ignore: must_be_immutable
class ReviewsList extends StatefulWidget {
  ReviewData? reviewData;
  ReviewsBloc? reviewsBloc;

  ReviewsList({Key? key, this.reviewData, this.reviewsBloc}) : super(key: key);

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  dynamic productFlats;

  @override
  void initState() {
    productFlats = widget.reviewData?.product?.productFlats
        ?.firstWhereOrNull((e) => e.locale == GlobalData.locale);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, productScreen,
            arguments: PassProductData(
                title: widget.reviewData?.product?.name ??
                    widget.reviewData?.product?.productFlats?[0].name,
                urlKey: widget.reviewData?.product?.urlKey,
                productId:
                    int.tryParse(widget.reviewData?.productId ?? "") ?? 0));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spacingNormal,
              AppSizes.spacingNormal, 0, AppSizes.spacingNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  (widget.reviewData?.product?.images ?? []).isNotEmpty
                      ? Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          child: ImageView(
                            url: widget.reviewData?.product?.images?[0].url ?? "",
                            width: 80, // Fixed legible size
                            height: 80,
                          ),
                        )
                      : ImageView(
                          url: "",
                          width: 80,
                          height: 80,
                        ),
                  
                  const SizedBox(width: AppSizes.spacingNormal),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating & Title
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                double rating = double.tryParse(widget.reviewData?.rating?.toString() ?? "0") ?? 0;
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: ReviewColorHelper.getColor(rating),
                                  size: 16.0,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              widget.reviewData?.title ?? "",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            )),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Comment
                        HtmlWidget(widget.reviewData?.comment ?? ""),
                        
                        const SizedBox(height: 8),
                        
                        // Review By
                        Row(
                          children: [
                            Text(
                              StringConstants.reviewBy.localized(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Flexible(child: Text(
                              widget.reviewData?.customer?.name ?? "",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            )),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Date (Right Aligned originally, but let's keep it simple here)
                        Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                              Text("${StringConstants.date.localized()}: ", 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                              ),
                              Flexible(
                                child: Text(
                                  widget.reviewData?.createdAt ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )
                           ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingNormal),
              widget.reviewData?.customerId == appStoragePref.getCustomerId().toString()
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, addReviewScreen,
                                arguments: AddReviewDetail(
                                    reviewId: widget.reviewData?.id?.toString(),
                                    rating: widget.reviewData?.rating,
                                    title: widget.reviewData?.title,
                                    comment: widget.reviewData?.comment,
                                    productId: widget.reviewData?.product?.id,
                                    productName: widget.reviewData?.product?.name))
                                .then((_) {
                              if (widget.reviewsBloc != null) {
                                widget.reviewsBloc?.add(FetchReviewsEvent(1));
                              }
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () => _onPressRemove(context),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  _onPressRemove(BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            StringConstants.deleteReviewWarning.localized(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          content: const Text("This action cannot be undone."),
          actions: [
            MaterialButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(StringConstants.no.localized()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                if (widget.reviewsBloc != null) {
                  widget.reviewsBloc?.add(RemoveReviewEvent(widget.reviewData?.id, ""));
                }
              },
              child: Text(StringConstants.yes.localized(), style: const TextStyle(color: Colors.red)),
            )
          ],
        );
      },
    );
  }
}
