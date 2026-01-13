/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */

import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SortBottomSheet extends StatefulWidget {
  final int? page;
  final CategoryBloc? subCategoryBloc;
  final List<Map<String, dynamic>> filters;

  const SortBottomSheet(
      {Key? key,
      this.categorySlug,
      this.page,
      this.subCategoryBloc,
      required this.filters})
      : super(key: key);

  final String? categorySlug;

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  List<SortOrder>? data;
  String? value;

  @override
  void initState() {
    getSortValue();
    FilterBloc filterDataBloc = context.read<FilterBloc>();
    filterDataBloc.add(FilterSortFetchEvent(widget.categorySlug ?? ""));
    super.initState();
  }

  getSortValue() async {
    value = appStoragePref.getSortName();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FilterBloc, FilterBaseState>(
      listener: (BuildContext context, FilterBaseState state) {},
      builder: (BuildContext context, FilterBaseState state) {
        return getSort(state);
      },
    );
  }

  Widget getSort(FilterBaseState state) {
    if (state is FilterInitialState) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (state is FilterFetchState) {
      data = state.filterModel?.sortOrders;
      return sortList();
    }
    return sortList();
  }

  Widget sortList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sort By",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (value != null && value!.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _applySort("");
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Clear", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Sort Options List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: data?.length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                var itemLabel = data?[index].title ?? "";
                var itemValue = data?[index].value;
                bool isSelected = value == itemLabel;

                return InkWell(
                  onTap: () => _applySort(itemLabel, itemValue),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white, // Light Green tint if selected
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF16A34A) : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                        else
                          Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applySort(String label, [String? val]) {
    setState(() {
      value = label;
      appStoragePref.setSortName(value ?? "");
    });

    widget.filters.removeWhere((element) => element["key"] == '"sort"');

    if (val != null) {
      widget.filters.add({
        "key": '"sort"',
        "value": '"$val"'
      });
    }

    widget.subCategoryBloc?.add(FetchSubCategoryEvent(
      widget.filters,
      widget.page,
    ));

    widget.subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));

    Navigator.pop(context);
  }
}