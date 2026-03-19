import 'dart:async';
import 'package:bagisto_app_demo/screens/search_screen/utils/index.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
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
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchText = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FocusNode _focusNode = FocusNode();
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

  // 🟢 Recent Searches
  List<String> _recentSearches = [];

  // 🟢 Suggestions (live autocomplete from search results)
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  // Debounce timer
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    activateSpeechRecognizer();
    searchBloc = context.read<SearchBloc>();
    searchBloc?.add(FetchCategoryPageEvent([
      {"key": '"status"', "value": '"1"'},
      {"key": '"locale"', "value": '"${GlobalData.locale}"'},
      {"key": '"parent_id"', "value": '"1"'}
    ]));
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    if (mounted) setState(() => _recentSearches = appStoragePref.getRecentSearches());
  }

  void _saveRecentSearch(String query) {
    appStoragePref.saveRecentSearch(query);
    if (mounted) setState(() => _recentSearches = appStoragePref.getRecentSearches());
  }

  void _clearRecentSearches() {
    appStoragePref.clearRecentSearches();
    if (mounted) setState(() => _recentSearches = []);
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
        _triggerSearch(transcription);
      }
      stop();
    });
  }

  void _triggerSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      searchBloc?.add(CircularBarEvent(isReqToShowLoader: true));
      searchBloc?.add(FetchSearchEvent([
        {"key": '"name"', "value": '"$value"'}
      ]));
    });
  }

  void _onSearchChanged(String value) {
    searchBloc?.add(SearchBarTextEvent(searchText: value));
    if (value.length >= 2) {
      _triggerSearch(value);
      setState(() => _showSuggestions = true);
    } else {
      _debounce?.cancel();
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
        if (value.isEmpty) products = null;
      });
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchText.text = suggestion;
    _searchText.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() => _showSuggestions = false);
    _saveRecentSearch(suggestion);
    searchBloc?.add(SearchBarTextEvent(searchText: suggestion));
    _triggerSearch(suggestion);
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _saveRecentSearch(value.trim());
      setState(() => _showSuggestions = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchBloc, SearchBaseState>(
      listener: (BuildContext context, SearchBaseState current) {},
      builder: (BuildContext context, SearchBaseState state) {
        // Sync text controller
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
            products = state.products;
            // Generate suggestions from product names
            final q = _searchText.text.toLowerCase();
            _suggestions = (products?.data ?? [])
                .map((p) => p.name ?? "")
                .where((n) => n.isNotEmpty && n.toLowerCase().contains(q))
                .toSet()
                .take(8)
                .toList();
          }
        }

        final bool isEmpty = _searchText.text.isEmpty;
        final bool hasResults = (products?.data ?? []).isNotEmpty;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Loading indicator
              if (isLoading)
                const LinearProgressIndicator(
                  backgroundColor: MobiKulTheme.accentColor,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  minHeight: 3,
                ),

              // 🟢 Suggestions overlay
              if (_showSuggestions && _suggestions.isNotEmpty && !isEmpty)
                _buildSuggestionsOverlay(),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟢 Empty state: Recent Searches + Categories
                      if (isEmpty) ...[
                        if (_recentSearches.isNotEmpty) _buildRecentSearches(),
                        if ((data ?? []).isNotEmpty) _buildModernCategoryGrid(data!),
                        if ((data ?? []).isEmpty && _recentSearches.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SkeletonLoader(
                              highlightColor: Theme.of(context).highlightColor,
                              baseColor: Theme.of(context).scaffoldBackgroundColor,
                              builder: const SizedBox(height: 100, child: Card(color: Colors.red)),
                            ),
                          ),
                      ],

                      // 🟢 Results
                      if (!isEmpty) ...[
                        if (hasResults) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              "${products!.data!.length} results for \"${_searchText.text}\"",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          _getSearchData(products),
                        ] else if (!isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No results for \"${_searchText.text}\"",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Try a different keyword",
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // 🟢 SUGGESTIONS OVERLAY
  // ──────────────────────────────────────────────
  Widget _buildSuggestionsOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchText.text.toLowerCase();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
        itemBuilder: (context, index) {
          final name = _suggestions[index];
          final matchIdx = name.toLowerCase().indexOf(query);

          return InkWell(
            onTap: () => _onSuggestionTap(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: matchIdx >= 0
                        ? RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              children: [
                                TextSpan(text: name.substring(0, matchIdx)),
                                TextSpan(
                                  text: name.substring(matchIdx, matchIdx + query.length),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: name.substring(matchIdx + query.length)),
                              ],
                            ),
                          )
                        : Text(name, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                  Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 🟢 RECENT SEARCHES
  // ──────────────────────────────────────────────
  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent searches",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: const Text(
                  "clear",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27C16B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return GestureDetector(
                onTap: () {
                  _searchText.text = term;
                  searchBloc?.add(SearchBarTextEvent(searchText: term));
                  setState(() => _showSuggestions = false);
                  _triggerSearch(term);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 🟢 CATEGORY GRID
  // ──────────────────────────────────────────────
  Widget _buildModernCategoryGrid(List<HomeCategories> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Browse Categories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index], index);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _getCategoryImageUrl(HomeCategories item) {
    try {
      final dynamicItem = item as dynamic;
      try { if (dynamicItem.bannerUrl != null) return dynamicItem.bannerUrl; } catch (_) {}
      try { if (dynamicItem.imageUrl != null) return dynamicItem.imageUrl; } catch (_) {}
      return "";
    } catch (_) { return ""; }
  }

  IconData _categoryIconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('dairy') || n.contains('bread') || n.contains('breakfast') || n.contains('bakery')) return Icons.breakfast_dining_outlined;
    if (n.contains('grain') || n.contains('rice') || n.contains('atta')) return Icons.grass_outlined;
    if (n.contains('fruit')) return Icons.apple_outlined;
    if (n.contains('vegetable') || n.contains('farm')) return Icons.eco_outlined;
    if (n.contains('meat') || n.contains('fish') || n.contains('chicken')) return Icons.set_meal_outlined;
    if (n.contains('egg')) return Icons.egg_outlined;
    if (n.contains('grocery') || n.contains('staple')) return Icons.shopping_basket_outlined;
    if (n.contains('oil') || n.contains('ghee')) return Icons.opacity_outlined;
    if (n.contains('spice') || n.contains('masala')) return Icons.whatshot_outlined;
    if (n.contains('snack') || n.contains('chip') || n.contains('biscuit')) return Icons.fastfood_outlined;
    if (n.contains('beverage') || n.contains('drink') || n.contains('tea') || n.contains('coffee')) return Icons.local_cafe_outlined;
    if (n.contains('sweet') || n.contains('chocolate')) return Icons.icecream_outlined;
    if (n.contains('personal') || n.contains('beauty') || n.contains('skin')) return Icons.face_retouching_natural_outlined;
    if (n.contains('home') || n.contains('clean') || n.contains('detergent')) return Icons.cleaning_services_outlined;
    if (n.contains('baby') || n.contains('diaper')) return Icons.child_care_outlined;
    if (n.contains('pet')) return Icons.pets_outlined;
    if (n.contains('kitchen')) return Icons.kitchen_outlined;
    return Icons.category_outlined;
  }

  Widget _buildCategoryCard(HomeCategories item, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> bgColors = isDark ? [
      const Color(0xFF1B2A2B), const Color(0xFF2B2A1B), const Color(0xFF2A1B2B),
      const Color(0xFF1B2B1B), const Color(0xFF1B1B2B), const Color(0xFF2B1B1B),
    ] : [
      const Color(0xFFE0F7FA), const Color(0xFFFFF9C4), const Color(0xFFE1BEE7),
      const Color(0xFFC8E6C9), const Color(0xFFBBDEFB), const Color(0xFFFFCCBC),
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: imageUrl.isNotEmpty
                    ? ImageView(url: imageUrl, fit: BoxFit.contain)
                    : Icon(_categoryIconFor(label), color: Colors.black54, size: 32),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 🟢 APP BAR
  // ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  autofocus: true,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSubmitted,
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
                    setState(() {
                      _showSuggestions = false;
                      _suggestions = [];
                      products = null;
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.grey,
            ),
            onPressed: _speechToText.isNotListening ? start : stop,
          ),
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

  void stop() async {
    await _speechToText.stop();
    _isListening = false;
    setState(() {});
  }

  void start() async {
    await _speechToText.listen(onResult: onRecognitionResult);
    _isListening = true;
    setState(() {});
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
    return await InternetConnectionChecker.createInstance().hasConnection;
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
}