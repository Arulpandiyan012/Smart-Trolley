/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/compare/utils/index.dart';

class CompareView extends StatelessWidget {
  final CompareProductsData compareScreenModel;
  final CompareScreenBloc? compareScreenBloc;

  const CompareView(
      {Key? key, required this.compareScreenModel, this.compareScreenBloc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 Must match width in CompareList (screen / 2.2)
    double cardWidth = MediaQuery.of(context).size.width / 2.2;
    double cardMargin = 12.0; 

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- 1. PRODUCT CARDS ROW ---
          CompareList(
              compareScreenModel: compareScreenModel,
              compareScreenBloc: compareScreenBloc),

          const SizedBox(height: 16),

          // --- 2. ATTRIBUTE: SKU ---
          _buildAttributeRow(
            context,
            title: StringConstants.sku.localized(),
            cardWidth: cardWidth,
            cardMargin: cardMargin,
            isAlternate: false, // White background
            itemBuilder: (index) {
              return Text(
                compareScreenModel.data?[index].product?.sku ?? "-",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),

          // --- 3. ATTRIBUTE: DESCRIPTION ---
          _buildAttributeRow(
            context,
            title: StringConstants.description.localized(),
            cardWidth: cardWidth,
            cardMargin: cardMargin,
            isAlternate: true, // Gray background
            itemBuilder: (index) {
              return SingleChildScrollView(
                child: HtmlWidget(
                  compareScreenModel.data?[index].product?.description ?? "",
                  textStyle: TextStyle(
                    color: Colors.grey[700], 
                    fontSize: 12, 
                    height: 1.4
                  ),
                ),
              );
            },
            height: 150, // Fixed height for description
          ),

          // --- 4. ATTRIBUTE: PRICE ---
          _buildAttributeRow(
             context,
             title: StringConstants.price.localized(),
             cardWidth: cardWidth,
             cardMargin: cardMargin,
             isAlternate: false, // White background
             itemBuilder: (index) {
                return PriceWidgetHtml(
                   priceHtml: compareScreenModel.data?[index].product?.priceHtml?.priceHtml ?? "-",
                );
             }
          ),

          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  /// 🟢 Custom Widget to build consistent table rows
  Widget _buildAttributeRow(
      BuildContext context, {
      required String title,
      required double cardWidth,
      required double cardMargin,
      required bool isAlternate,
      required Widget Function(int index) itemBuilder,
      double height = 50.0,
      }) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Label
        Container(
          width: (compareScreenModel.data?.length ?? 0) * cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isAlternate ? Colors.grey[50] : Colors.white,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
        
        // Horizontal List of Attributes
        Container(
          height: height,
          width: (compareScreenModel.data?.length ?? 0) * cardWidth,
          color: isAlternate ? Colors.grey[50] : Colors.white, // Row Background
          child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: compareScreenModel.data?.length ?? 0,
              itemBuilder: (context, index) {
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: cardMargin),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    // Optional: Vertical divider line
                    border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.05)))
                  ),
                  child: itemBuilder(index),
                );
              }),
        ),
        
        // Separator Line
        if (!isAlternate) const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }
}