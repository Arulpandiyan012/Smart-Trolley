/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */



import 'package:bagisto_app_demo/screens/product_screen/utils/index.dart';


class ProductReviewSummaryView extends StatefulWidget {
  final List<Reviews>? review;
  final String? productId;
  final String? averageRating;
  final dynamic percentage;
  final String? productName;
  final String? productImage;
  final bool? isLogin;

  const ProductReviewSummaryView(
      {Key? key,
      this.review,
      this.productName,
      this.productImage,
      this.averageRating,
      this.percentage,
      this.productId,
      this.isLogin})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProductReviewSummaryViewState();
  }
}

class ProductReviewSummaryViewState extends State<ProductReviewSummaryView> {
  dynamic percentage;

  @override
  void initState() {
    percentage = (widget.percentage.toString()) != "[]"
        ? json.decode(widget.percentage.toString())
        : [];
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Theme(
      data:Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Theme.of(context).iconTheme.color, // 🟢 Theme-aware
        collapsedIconColor: Theme.of(context).iconTheme.color,
        tilePadding:const EdgeInsets.symmetric(horizontal: AppSizes.spacingLarge) ,
        title: Text(
          StringConstants.customerRating.localized(),
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color, 
            fontWeight: FontWeight.w700, 
            fontSize: 18,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(AppSizes.spacingNormal),
              alignment: Alignment.topLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if ((widget.review?.length ?? 0) > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Column(children: [
                              Text(
                                  "${widget.averageRating?.toString() ?? ''} ${StringConstants.star.localized()}",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              RatingBar(
                                starCount: 5,
                                color: Theme.of(context).colorScheme.onPrimary,
                                rating: num.tryParse(widget.averageRating.toString())?.toDouble() ??0.0,
                              ),

                              const SizedBox(height: 6),
                                  Text(
                                  "${widget.averageRating?.toString() ?? ''} Rating & "
                                  "${widget.review?.length.toString() ?? ''} Reviews",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                  )),
                              const SizedBox(height: 8),
                            ]),
                          ),
                          ReviewLinearProgressIndicator(percentage: percentage),
                        ],
                      ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(
                            8, ((widget.review?.length ?? 0) > 0 ? 8 : 0), 0, 0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF27C16B), width: 1.2),
                                backgroundColor: const Color(0xFFF0FDF4), // Very light green tint
                                foregroundColor: const Color(0xFF27C16B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: () {
                                widget.isLogin ?? false
                                    ? Navigator.pushNamed(context, addReviewScreen,
                                        arguments: AddReviewDetail(
                                            imageUrl: widget.productImage,
                                            productId: widget.productId,
                                            productName: widget.productName))
                                    : ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                        content:
                                            Text(StringConstants.pleaseLoginReview.localized()),
                                        duration: const Duration(seconds: 3),
                                      ));
                              },
                              icon: const Icon(Icons.edit_note, size: 20),
                              label: Text(
                                StringConstants.writeReview.localized().toUpperCase(), 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                              ),
                          ),
                        )),
                  ])),
          
          // 🟢 ADDED: Review List
          if ((widget.review?.length ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingNormal),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: (widget.review!.length > 3) ? 3 : widget.review!.length,
                separatorBuilder: (ctx, index) => const Divider(),
                itemBuilder: (context, index) {
                  var item = widget.review![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RatingBar(
                              starCount: 5,
                              color: Theme.of(context).colorScheme.onPrimary,
                              rating: double.tryParse(item.rating?.toString() ?? "0.0") ?? 0.0,
                              size: 14,
                            ),
                            const Spacer(),
                            Text(item.createdAt ?? "", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.title ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.titleSmall?.color)),
                        const SizedBox(height: 4),
                        Text(item.comment ?? "", style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 6),
                        Text("${StringConstants.reviewBy.localized()} ${item.customerName ?? item.title ?? 'Guest'}", 
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                },
              ),
            ),

          if ((widget.review?.length ?? 0) > 3)
            Padding(
               padding: const EdgeInsets.all(8.0),
               child: TextButton(
                 onPressed: () {
                    _showAllReviews(context);
                 }, 
                 child: const Text("View All Reviews", style: TextStyle(color: Color(0xFF27C16B), fontWeight: FontWeight.bold))
               ),
            ),
             
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("All Reviews (${widget.review?.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: widget.review?.length ?? 0,
                    separatorBuilder: (ctx, index) => const Divider(),
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      var item = widget.review![index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RatingBar(
                                starCount: 5,
                                color: Theme.of(context).colorScheme.onPrimary,
                                rating: double.tryParse(item.rating?.toString() ?? "0.0") ?? 0.0,
                                size: 14,
                              ),
                              const Spacer(),
                              Text(item.createdAt ?? "", style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.title ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.titleSmall?.color)),
                          const SizedBox(height: 4),
                          Text(item.comment ?? "", style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
                          const SizedBox(height: 6),
                          Text("${StringConstants.reviewBy.localized()} ${item.customerName ?? item.title ?? 'Guest'}", 
                              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontStyle: FontStyle.italic)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
