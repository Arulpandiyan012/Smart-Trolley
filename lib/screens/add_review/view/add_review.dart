/*
 *   Webkul Software.
 *   @package Mobikul Application Code.
 *   @Category Mobikul
 *   @author Webkul <support@webkul.com>
 *   @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 *   @license https://store.webkul.com/license.html
 *   @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/add_review/utils/index.dart';

class AddReview extends StatefulWidget {
  final String? imageUrl;
  final String? productId;
  final String? productName;
  final String? reviewId; // 🟢 ADDED
  final int? rating;      // 🟢 ADDED
  final String? title;       // 🟢 ADDED
  final String? comment;     // 🟢 ADDED

  const AddReview({
    Key? key, 
    this.imageUrl, 
    this.productId, 
    this.productName,
    this.reviewId,
    this.rating,
    this.title,
    this.comment
  }) : super(key: key);

  @override
  State<AddReview> createState() => _AddReviewState();
}

class _AddReviewState extends State<AddReview> {
  final bool _autoValidate = false;
  final _reviewFormKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final commentController = TextEditingController();
  var rating = 0;
  bool isLoading = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  AddReviewBloc? addReviewBloc;
  List<Map<String, String>> images = [];
  String? reviewId; // 🟢 STORE ID

  @override
  void initState() {
    addReviewBloc = context.read<AddReviewBloc>();

    // 🟢 DIRECT PREFILL: From constructor parameters
    reviewId = widget.reviewId;
    titleController.text = widget.title ?? "";
    commentController.text = widget.comment ?? "";
    rating = widget.rating ?? 0;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(StringConstants.addaReview.localized()),
          centerTitle: false,
        ),
        body: _addReviewBloc(context),
      ),
    );
  }

  ///Bloc Container
  _addReviewBloc(BuildContext context) {
    return BlocConsumer<AddReviewBloc, AddReviewBaseState>(
      listener: (BuildContext context, AddReviewBaseState state) {
        if (state is AddReviewFetchState) {
          isLoading = true;
          if (state.status == AddReviewStatus.fail) {
            ShowMessage.showNotification(StringConstants.failed, state.error,
                Colors.red, const Icon(Icons.cancel_outlined));
          } else if (state.status == AddReviewStatus.success) {
            ShowMessage.showNotification(
                StringConstants.success.localized(),
                // state.addReviewModel!.success ?? StringConstants.updated.localized(),
                state.addReviewModel?.message.toString(),
                Colors.green.shade400,
                const Icon(Icons.check_circle_outline));
          }
        }
      },
      builder: (BuildContext context, AddReviewBaseState state) {
        return buildUI(context, state);
      },
    );
  }

  ///add Review Ui method
  Widget buildUI(BuildContext context, AddReviewBaseState state) {
    if (state is AddReviewFetchState) {
      isLoading = true;
      if (state.status == AddReviewStatus.success) {
        return _reviewForm();
      }
      if (state.status == AddReviewStatus.fail) {
        return ErrorMessage.errorMsg(state.error ?? "");
      }
    }

    if (state is AddReviewInitialState) {
      return _reviewForm();
    }
    if (state is ImagePickerState) {
      String? image = state.image;
      images.clear();
      if (image != null) {
        images.add({
          "uploadType": '"base64"',
          "imageUrl": '"data:image/png;base64,$image"'
        });
      }
      return _reviewForm();
    }
    return const SizedBox();
  }

  Widget _reviewForm() {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _reviewFormKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟢 1. PRODUCT HERO CARD (Compact & Trendy)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageView(
                              url: widget.imageUrl ?? "",
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Reviewing",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.productName ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🟢 2. RATING SECTION
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "How was your experience?",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          RatingBar.builder(
                            itemSize: 45,
                            initialRating: rating.toDouble(),
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            glow: true,
                            glowColor: Colors.amber.withOpacity(0.3),
                            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                            itemBuilder: (context, _) => const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (updatedRating) {
                              setState(() {
                                rating = updatedRating.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getRatingText(rating),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🟢 3. FORM FIELDS
                    _buildModernTextField(
                      controller: titleController,
                      hint: "e.g., Amazing product!",
                      label: "Title",
                      isRequired: true,
                    ),
                    const SizedBox(height: 20),
                    _buildModernTextField(
                      controller: commentController,
                      hint: "Share your detailed thoughts about the product...",
                      label: "Your Review",
                      maxLines: 5,
                      isRequired: true,
                    ),

                    const SizedBox(height: 40),

                    // 🟢 4. SUBMIT BUTTON
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF27C16B), Color(0xFF1B8A4C)], // Trendy Green Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF27C16B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _onPressSubmitButton,
                        child: const Text(
                          "SUBMIT REVIEW",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading) Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(child: Loader()),
        )
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return "Terrible";
      case 2: return "Poor";
      case 3: return "Average";
      case 4: return "Good";
      case 5: return "Excellent!";
      default: return "Select Rating";
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.4), fontSize: 13),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return "This field is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  ///method will call on press submit review button
  _onPressSubmitButton() {
    if (_reviewFormKey.currentState!.validate()) {
      // if (images.isNotEmpty) {
        if ((rating) > 0) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.spacingWide),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: AppSizes.spacingMedium,
                        ),
                        const Loader(),
                        const SizedBox(
                          height: AppSizes.spacingWide,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2.5,
                          child: Center(
                            child: Text(
                              StringConstants.processWaitingMsg.localized(),
                              softWrap: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: AppSizes.spacingMedium,
                        ),
                      ],
                    ),
                  ),
                );
              });
          addReviewBloc?.add(AddReviewFetchEvent(
              productId: int.parse(widget.productId ?? ''),
              rating: rating,
              title: titleController.text,
              comment: commentController.text,
              name: "",
              reviewId: reviewId, // 🟢 PASS ID
              attachments: images));
          Future.delayed(const Duration(seconds: 3)).then((value) {
            Navigator.pop(context);
            Navigator.pop(context);
          });
        } else {
          ShowMessage.showNotification(
              StringConstants.warning.localized(),
              StringConstants.pleaseAddRating.localized(),
              Colors.yellow,
              const Icon(Icons.warning_amber));
        }
      // } else {
      //   ShowMessage.showNotification(
      //       StringConstants.warning.localized(),
      //       StringConstants.addReviewImage.localized(),
      //       Colors.yellow,
      //       const Icon(Icons.warning_amber));
      // }
    }
  }
}
