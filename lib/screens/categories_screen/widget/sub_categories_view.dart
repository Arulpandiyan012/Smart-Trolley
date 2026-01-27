import 'package:bagisto_app_demo/screens/categories_screen/utils/index.dart';
import 'blinkit_product_card.dart'; 
import 'blinkit_sidebar.dart';

//ignore: must_be_immutable
class SubCategoriesView extends StatefulWidget {
  bool? isLoading = false;
  int? page;
  CategoryBloc? subCategoryBloc;
  ScrollController? scrollController;
  String? title;
  String? image;
  String? categorySlug;
  String? metaDescription;
  NewProductsModel? categoriesData;
  bool? isLoggedIn;
  GetFilterAttribute? data;
  List<Map<String, dynamic>> filters;
  bool isPreCatching;

  SubCategoriesView(
      this.isLoading,
      this.page,
      this.subCategoryBloc,
      this.scrollController,
      this.title,
      this.image,
      this.categorySlug,
      this.metaDescription,
      this.categoriesData,
      this.isLoggedIn,
      this.data, this.filters, this.isPreCatching,
      {Key? key})
      : super(key: key);

  @override
  State<SubCategoriesView> createState() => _SubCategoriesViewState();
}

class _SubCategoriesViewState extends State<SubCategoriesView> {
  
  @override
  Widget build(BuildContext context) {
    // 1. TOP BAR (Filters/Sort) - Moved to top like Blinkit
    Widget topFilterBar = Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
           // Filter Button
           InkWell(
             onTap: () {
               // Your existing Filter Logic
                Navigator.of(context).push(MaterialPageRoute(builder: (context)=>
                    SubCategoriesFilterScreen(
                      categorySlug: widget.categorySlug ?? "",
                      subCategoryBloc: widget.subCategoryBloc,
                      page: widget.page,
                      data: widget.data,
                      filters: widget.filters,
                    ),
                ));
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 children: const [
                   Icon(Icons.tune, size: 16),
                   SizedBox(width: 4),
                   Text("Filters", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
           ),
           const SizedBox(width: 10),
           // Sort Button
           InkWell(
             onTap: () {
                // Your existing Sort Logic
                 showModalBottomSheet(
                    backgroundColor: Theme.of(context).cardColor,
                    context: context,
                    builder: (ctx) => BlocProvider(
                      create: (context) => FilterBloc(FilterRepositoryImp()),
                      child: SortBottomSheet(
                        categorySlug: widget.categorySlug ?? "",
                        page: widget.page,
                        filters: widget.filters,
                        subCategoryBloc: widget.subCategoryBloc,
                      ),
                    ));
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 children: const [
                   Icon(Icons.swap_vert, size: 16),
                   SizedBox(width: 4),
                   Text("Sort", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
           ),
        ],
      ),
    );

    // 2. MAIN BODY (Split View)
    return Column(
      children: [
        topFilterBar,
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDEBAR
              BlinkitSidebar(
                onCategorySelected: (index) {
                  // TODO: Add logic here to reload products based on sub-category
                  // For now, it just visually selects the item
                  // widget.subCategoryBloc.add(FetchSubCategoryEvent(...));
                },
              ),

              // RIGHT PRODUCT LIST
              Expanded(
                child: Container(
                  color: Colors.white, // Right side white background
                  child: RefreshIndicator(
                    onRefresh: () async {
                       widget.subCategoryBloc?.add(FetchSubCategoryEvent(widget.filters, widget.page));
                    },
                    child: (widget.categoriesData?.data?.isEmpty ?? false) 
                    ? const Center(child: Text("No Products Found"))
                    : ListView.builder(
                        controller: widget.scrollController, // Attach Pagination Controller here
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: (widget.categoriesData?.data?.length ?? 0) + 1, // +1 for loader
                        itemBuilder: (context, index) {
                          // Handle Bottom Loader
                          if (index == widget.categoriesData?.data?.length) {
                             if(widget.isLoading == true) {
                               return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                             }
                             return const SizedBox(height: 50);
                          }

                          // Render Blinkit Style Card
                          return BlinkitProductCard(
                            data: widget.categoriesData?.data?[index],
                            isLoggedIn: widget.isLoggedIn ?? false,
                            subCategoryBloc: widget.subCategoryBloc,
                          );
                        },
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}