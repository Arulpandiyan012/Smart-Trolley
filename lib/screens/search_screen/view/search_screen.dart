/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/services.dart';

// 🟢 Navigation Imports
import 'package:bagisto_app_demo/screens/drawer_sub_categories/utils/index.dart'
    show drawerSubCategoryScreen, CategoriesArguments;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchText = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  AnimationController? _controller;
  String transcription = '';
  bool _isListening = false;
  List<HomeCategories>? data;
  String searchImage = "imageSearch";
  String searchText = "textSearch";
  final Permission _permission = Permission.camera;
  SearchBloc? searchBloc;
  NewProductsModel? products;
  bool isLoading = false;

  @override
  void initState() {
    activateSpeechRecognizer();
    searchBloc = context.read<SearchBloc>();
    // Fetch initial categories
    searchBloc?.add(FetchCategoryPageEvent([
      {"key": '"status"', "value": '"1"'},
      {"key": '"locale"', "value": '"${GlobalData.locale}"'},
      {"key": '"parent_id"', "value": '"1"'}
    ]));
    super.initState();
  }

  void activateSpeechRecognizer() async {
    _controller = AnimationController(
      lowerBound: 0.5,
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void onRecognitionResult(SpeechRecognitionResult result) {
    setState(() {
      transcription = result.recognizedWords;
      _searchText.text = transcription;
      if (transcription.length > 2) {
        searchBloc?.add(CircularBarEvent(isReqToShowLoader: true));
        searchBloc?.add(SearchBarTextEvent(searchText: transcription));
        searchBloc?.add(FetchSearchEvent([
          {"key": '"name"', "value": '"$transcription"'}
        ]));
      }
      stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchBloc, SearchBaseState>(
        listener: (BuildContext context, SearchBaseState current) {},
        builder: (BuildContext context, SearchBaseState state) {
          _searchText.text = (state is AppBarSearchTextState
              ? state.searchText
              : ((state is ClearSearchBarTextState) ? "" : _searchText.text))!;
          _searchText.value = _searchText.value.copyWith(
            text: _searchText.text,
            selection: TextSelection.fromPosition(
              TextPosition(offset: _searchText.text.length),
            ),
          );
          if (state is CircularBarState) {
            isLoading = state.isReqToShowLoader!;
          }
          if (state is FetchCategoriesPageDataState) {
            if (state.status == Status.success) {
              data = state.getCategoriesData?.data;
            }
          }
          if (state is FetchSearchDataState) {
            searchBloc?.add(CircularBarEvent(isReqToShowLoader: false));
            if (state.status == Status.success) {
              products = state.products!;
            }
            if (state.status == Status.fail) {
              return (state.products?.data ?? []).isEmpty
                  ? const EmptyDataView(
                      assetPath: AssetConstants.emptyCatalog,
                      message: StringConstants.emptyPageGenericLabel,
                    )
                  : const SizedBox();
            }
          }
          return Scaffold(
              backgroundColor: Colors.white,
              appBar: _setAppBarView(context),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Visibility(
                    visible: isLoading,
                    child: const LinearProgressIndicator(
                      backgroundColor: MobiKulTheme.accentColor,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  
                  // 🟢 Modern Grid for Categories
                  if ((products?.data ?? []).isEmpty && _searchText.text.isEmpty)
                    ((data ?? []).isNotEmpty)
                        ? _buildModernCategoryGrid(data!)
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SkeletonLoader(
                                highlightColor: Theme.of(context).highlightColor,
                                baseColor: Theme.of(context).scaffoldBackgroundColor,
                                builder: const SizedBox(
                                  height: 100,
                                  child: Card(color: Colors.red),
                                )),
                          ),

                  // Search Results
                  ((products?.data ?? []).isNotEmpty)
                      ? _getSearchData(products)
                      : _searchText.text.isNotEmpty
                          ? (products?.data ?? []).isEmpty
                              ? const EmptyDataView(
                                  assetPath: AssetConstants.emptyCatalog,
                                  message: StringConstants.emptyPageGenericLabel,
                                )
                              : const SizedBox()
                          : const SizedBox(),
                ]),
              ));
        });
  }

  /// 🟢 Modern Category Grid
  Widget _buildModernCategoryGrid(List<HomeCategories> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Browse Categories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 Columns
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final item = categories[index];
            return _buildCategoryCard(item, index);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 🟢 Helper to safely get image URL
  String _getCategoryImageUrl(HomeCategories item) {
    try {
      final dynamicItem = item as dynamic;
      try {
        if (dynamicItem.bannerUrl != null) return dynamicItem.bannerUrl;
      } catch (_) {}
      try {
        if (dynamicItem.imageUrl != null) return dynamicItem.imageUrl;
      } catch (_) {}
      return "";
    } catch (_) {
      return "";
    }
  }

  /// 🟢 ICON MAPPER: Ensures every category gets a relevant icon/image
  IconData _categoryIconFor(String name) {
    final n = name.toLowerCase();

    if (n.contains('event') || n.contains('party') || n.contains('wedding')) return Icons.event_outlined;
    if (n.contains('dairy') || n.contains('bread') || n.contains('breakfast') || n.contains('bakery')) return Icons.breakfast_dining_outlined; 
    if (n.contains('grain') || n.contains('cereal') || n.contains('oat') || n.contains('pulse') || n.contains('rice') || n.contains('atta')) return Icons.grass_outlined; 
    
    // Fresh
    if (n.contains('fruit')) return Icons.apple_outlined;
    if (n.contains('vegetable') || n.contains('farm')) return Icons.eco_outlined;
    if (n.contains('meat') || n.contains('fish') || n.contains('chicken') || n.contains('non veg')) return Icons.set_meal_outlined;
    if (n.contains('egg')) return Icons.egg_outlined; 
    
    // Grocery
    if (n.contains('grocery') || n.contains('staple')) return Icons.shopping_bag_outlined;
    if (n.contains('oil') || n.contains('ghee')) return Icons.opacity_outlined;
    if (n.contains('spice') || n.contains('masala')) return Icons.whatshot_outlined;

    // Snacks
    if (n.contains('snack') || n.contains('chip') || n.contains('biscuit') || n.contains('namkeen')) return Icons.fastfood_outlined;
    if (n.contains('beverage') || n.contains('drink') || n.contains('juice') || n.contains('tea') || n.contains('coffee')) return Icons.local_cafe_outlined;
    if (n.contains('sweet') || n.contains('chocolate') || n.contains('ice cream')) return Icons.icecream_outlined;

    // Other
    if (n.contains('personal') || n.contains('beauty') || n.contains('skin') || n.contains('hair') || n.contains('face')) return Icons.face_retouching_natural_outlined;
    if (n.contains('home') || n.contains('clean') || n.contains('detergent') || n.contains('wash')) return Icons.cleaning_services_outlined;
    if (n.contains('baby') || n.contains('diaper')) return Icons.child_care_outlined;
    if (n.contains('pet') || n.contains('dog') || n.contains('cat')) return Icons.pets_outlined;
    if (n.contains('kitchen')) return Icons.kitchen_outlined;
    if (n.contains('pharmacy') || n.contains('medicin') || n.contains('health')) return Icons.medication_outlined;
    if (n.contains('electr') || n.contains('mobile') || n.contains('phone')) return Icons.devices_outlined;
    if (n.contains('fashion') || n.contains('cloth')) return Icons.checkroom_outlined;

    return Icons.category_outlined;
  }

  /// 🟢 NEW: Single Category Card
  Widget _buildCategoryCard(HomeCategories item, int index) {
    // 🎨 UPDATED COLORS: More vibrant & clean (Pastel Pop)
    final List<Color> bgColors = [
      const Color(0xFFE0F7FA), // Cyan tint
      const Color(0xFFFFF9C4), // Yellow tint
      const Color(0xFFE1BEE7), // Purple tint
      const Color(0xFFC8E6C9), // Green tint
      const Color(0xFFBBDEFB), // Blue tint
      const Color(0xFFFFCCBC), // Deep Orange tint
    ];
    final color = bgColors[index % bgColors.length];
    
    final String imageUrl = _getCategoryImageUrl(item);
    final String label = item.name ?? "";

    return GestureDetector(
      onTap: () {
        if (item.slug != null) {
          Navigator.pushNamed(
            context,
            drawerSubCategoryScreen,
            arguments: CategoriesArguments(
              categorySlug: item.slug,
              title: label,
              id: item.id?.toString(),
              image: imageUrl, 
              parentId: item.id?.toString(),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          // No border, just a subtle shadow for pop
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: (imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (c, o, s) => Icon(
                          _categoryIconFor(label), 
                          color: Colors.black54, 
                          size: 32
                        ),
                      )
                    : Icon(
                        _categoryIconFor(label), 
                        color: Colors.black54, 
                        size: 32
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700, // Bolder text
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// App Bar View
  PreferredSize _setAppBarView(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 8), 
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  autofocus: true, 
                  onChanged: (value) async {
                    if (value.length > 2) {
                      searchBloc?.add(SearchBarTextEvent(searchText: value));
                      searchBloc?.add(CircularBarEvent(isReqToShowLoader: true));
                      searchBloc?.add(FetchSearchEvent([
                        {"key": '"name"', "value": '"$value"'}
                      ]));
                    }
                  },
                  readOnly: _isListening,
                  controller: _searchText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: StringConstants.searchScreenTitle.localized(),
                    contentPadding: const EdgeInsets.only(bottom: 10),
                  ),
                ),
              ),
              if (_searchText.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () {
                    _searchText.clear();
                    searchBloc?.add(SearchBarTextEvent(searchText: ""));
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
            onPressed: _speechToText.isNotListening ? start : stop,
          ),
          // 🟢 Camera Icon (Restored)
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
            onPressed: () async {
              DialogHelper.searchDialog(context, () {
                Navigator.of(context).pop();
                _checkPermission(_permission, searchImage);
              }, () {
                Navigator.of(context).pop();
                _checkPermission(_permission, searchText);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _getSearchData(NewProductsModel? model) {
    var productList = model?.data;
    return (productList != null && productList.isNotEmpty)
        ? ProductList(model: model!)
        : const SizedBox();
  }

  Widget _buildVoiceInput({VoidCallback? onPressed}) => GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        child: AnimatedBuilder(
          animation: CurvedAnimation(
              parent: _controller!, curve: Curves.fastOutSlowIn),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                _buildContainer(10 * (_isListening ? _controller!.value : 0)),
                _buildContainer(20 * (_isListening ? _controller!.value : 0)),
                _buildContainer(30 * (_isListening ? _controller!.value : 0)),
                _buildContainer(40 * (_isListening ? _controller!.value : 0)),
                Align(
                  child: Icon(
                    !_isListening ? Icons.mic : Icons.mic_off,
                    size: AppSizes.spacingWide,
                  ),
                ),
              ],
            );
          },
        ),
      ));

  void stop() async {
    await _speechToText.stop();
    _isListening = false;
    setState(() {});
  }

  void start() async {
    await _speechToText.listen(
      onResult: onRecognitionResult,
    );
    _isListening = true;
    setState(() {});
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade400.withOpacity(1 - _controller!.value),
      ),
    );
  }

  Future<void> _checkPermission(Permission permission, String type) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      try {
        const platform = MethodChannel(defaultChannelName);
        var value = await platform.invokeMethod(type);
        _searchText.text = value;
        onImageSearch(value);
      } on PlatformException catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ShowMessage.showNotification(StringConstants.warning.localized(),
              e.message, Colors.yellow, const Icon(Icons.warning_amber));
        });
      }
    } else if (status == PermissionStatus.denied) {
      _checkPermission(_permission, type);
    } else if (status == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> onImageSearch(data) async {
    dynamic connected = await connectedToNetwork();
    if (connected == true) {
      searchBloc?.add(CircularBarEvent(isReqToShowLoader: true));
      searchBloc?.add(SearchBarTextEvent(searchText: data));
      searchBloc?.add(FetchSearchEvent([
        {"key": '"name"', "value": '"$data"'}
      ]));
    } else {
      DialogHelper.networkErrorDialog(context, onConfirm: () {
        onImageSearch(data);
      });
    }
  }

  static Future<bool> connectedToNetwork() async {
    bool result =
        await InternetConnectionChecker.createInstance().hasConnection;
    return result;
  }
}