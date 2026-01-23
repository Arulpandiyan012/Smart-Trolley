import 'package:bagisto_app_demo/screens/filter_screen/utils/index.dart';
import 'package:bagisto_app_demo/utils/extension.dart';
import 'package:flutter/material.dart';

class SubCategoriesFilterScreen extends StatefulWidget {
  const SubCategoriesFilterScreen(
      {super.key,
      this.categorySlug,
      this.page,
      this.subCategoryBloc,
      this.data,
      this.superAttributes,
      required this.filters});

  final List<Map<String, dynamic>> filters;
  final GetFilterAttribute? data;
  final String? categorySlug;
  final int? page;
  final CategoryBloc? subCategoryBloc;
  final List? superAttributes;

  @override
  State<SubCategoriesFilterScreen> createState() => _SubCategoriesFilterScreenState();
}

class _SubCategoriesFilterScreenState extends State<SubCategoriesFilterScreen> {
  Map<String, List> temp = {};
  Map<String, List> showTemp = {};
  List showItems = [];
  List superAttributes = [];
  double startPriceValue = 0, endPriceValue = 1;

  @override
  void initState() {
    if ((widget.superAttributes ?? []).isNotEmpty) {
      if (widget.superAttributes?[0]["key"] == "\"price\"") {
        startPriceValue = double.parse(widget.superAttributes?[0]["value"][0].replaceAll('"', ''));
        endPriceValue = double.parse(widget.superAttributes?[0]["value"][1].replaceAll('"', ''));
      } else {
        startPriceValue = widget.data?.minPrice ?? 0;
        endPriceValue = widget.data?.maxPrice ?? 1;
      }
    } else {
      startPriceValue = widget.data?.minPrice ?? 0;
      endPriceValue = widget.data?.maxPrice ?? 1;
    }
    fetchFilterData();
    super.initState();
  }

  void fetchFilterData() {
    temp.clear();
    showTemp.clear();
    showItems.clear();

    for (var attr in widget.data?.filterAttributes ?? []) {
      final code = getValueFromDynamic(attr, "code");

      if (!temp.containsKey(code)) {
        temp[code] = [];
        showTemp[code] = [];
      }

      final matchedFilter = widget.filters.firstWhere(
        (filter) => filter["key"] == '"$code"',
        orElse: () => {},
      );

      if (matchedFilter.isNotEmpty) {
        final values = matchedFilter["value"].toString().replaceAll('"', "").split(',');

        if (code == "price" && values.length == 2) {
          startPriceValue = double.tryParse(values[0]) ?? startPriceValue;
          endPriceValue = double.tryParse(values[1]) ?? endPriceValue;
        } else {
          for (var val in values) {
            final quoted = '"$val"';
            showTemp[code]?.add(quoted);
            temp[code]?.add(quoted);
            showItems.add(quoted);
          }
        }
      }
    }

    superAttributes.clear();
    temp.forEach((key, value) {
      if (value.isNotEmpty) {
        superAttributes.add({"key": '"$key"', "value": value});
      }
    });
    setState(() {});
  }

  void _applyFilters() {
    if (superAttributes.isNotEmpty) {
      Navigator.pop(context, superAttributes);
    } else {
      Navigator.pop(context, widget.superAttributes);
    }
    widget.subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));
    widget.subCategoryBloc?.add(FetchSubCategoryEvent(widget.filters, widget.page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Filters", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                superAttributes = [];
                widget.filters.removeWhere((element) =>
                    element["key"] != '"category_id"' && element["key"] != '"sort"');
                
                widget.subCategoryBloc?.add(FetchSubCategoryEvent(widget.filters, widget.page));
                Navigator.pop(context);
                widget.subCategoryBloc?.add(OnClickSubCategoriesLoaderEvent(isReqToShowLoader: true));
              });
            },
            child: const Text("CLEAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (widget.data?.filterAttributes ?? []).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, idx) {
                      final attr = widget.data?.filterAttributes?[idx];
                      final code = getValueFromDynamic(attr, "code");
                      
                      if (!temp.containsKey(code)) {
                        temp["$code"] = [];
                      }
                      
                      return _buildSection(
                        "${getValueFromDynamic(attr, "adminName")}",
                        "$code",
                        getValueFromDynamic(attr, "options"),
                        context,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String code, List<dynamic>? options, BuildContext context) {
    if ((options == null || options.isEmpty) && code != "price") return const SizedBox();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (title == "Price") ...[
            // Modern Price Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _priceBox("Min", startPriceValue),
                _priceBox("Max", endPriceValue),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              min: widget.data?.minPrice ?? 0,
              max: widget.data?.maxPrice ?? 500,
              activeColor: const Color(0xFF16A34A),
              inactiveColor: Colors.grey.shade200,
              values: RangeValues(startPriceValue, endPriceValue),
              onChanged: (RangeValues value) {
                setState(() {
                  widget.filters.removeWhere((element) => element["key"] == '"$code"');
                  widget.filters.add({"key": '"$code"', "value": '"${value.start}, ${value.end}"'});

                  temp[code]?.clear();
                  superAttributes.clear();
                  startPriceValue = value.start.floorToDouble();
                  endPriceValue = value.end.floorToDouble();
                  temp[code]?.add('"$startPriceValue"');
                  temp[code]?.add('"$endPriceValue"');
                  
                  // Rebuild Attributes
                  temp.addAll(showTemp);
                  temp.forEach((key, val) {
                    if (val.isNotEmpty) superAttributes.add({"key": '"$key"', "value": val});
                  });
                });
              },
            ),
          ] else ...[
            // Modern Filter Options (List)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                Map<String, dynamic>? option = options[index];
                String optId = getValueFromDynamic(option, "id");
                bool isSelected = showItems.contains('"$optId"');

                return InkWell(
                  onTap: () {
                    _toggleFilter(code, optId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getValueFromDynamic(option, "adminName") ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF16A34A) : Colors.black87
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
                          size: 22,
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          ]
        ],
      ),
    );
  }

  Widget _priceBox(String label, double val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text("₹${val.toInt()}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _toggleFilter(String code, String id) {
    bool isSelected = showItems.contains('"$id"');
    
    // Update UI List
    setState(() {
      if (isSelected) {
        showItems.remove('"$id"');
        temp[code]?.remove('"$id"');
      } else {
        showItems.add('"$id"');
        temp[code]?.add('"$id"');
      }
      
      // Rebuild Attributes
      superAttributes.clear();
      showTemp.addAll(temp);
      showTemp.forEach((key, val) {
        if (val.isNotEmpty) superAttributes.add({"key": '"$key"', "value": val});
      });
    });

    // Update Actual Filters for API
    int idx = widget.filters.indexWhere((e) => e["key"] == '"$code"');
    if (idx >= 0) {
      List<String> values = widget.filters[idx]['value'].toString().replaceAll('"', "").split(',');
      if (isSelected) {
        values.remove(id);
      } else {
        values.add(id);
      }
      
      if (values.isEmpty) {
        widget.filters.removeAt(idx);
      } else {
        widget.filters[idx] = {"key": '"$code"', "value": '"${values.join(',')}"'};
      }
    } else {
      widget.filters.add({"key": '"$code"', "value": '"$id"'});
    }
  }
}