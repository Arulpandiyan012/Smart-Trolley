/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 * @author Webkul <support@webkul.com>
 * @Copyright (c) Webkul Software Private Limited (https://webkul.com)
 * @license https://store.webkul.com/license.html
 * @link https://store.webkul.com/license.html
 */

import 'package:bagisto_app_demo/screens/account/utils/index.dart';

class ProfileImageView extends StatefulWidget {
  final Function(String? base64string)? callback;

  const ProfileImageView({Key? key, this.callback}) : super(key: key);

  @override
  State<ProfileImageView> createState() => _ProfileImageViewState();
}

class _ProfileImageViewState extends State<ProfileImageView> {
  String profileImageEdit = "";
  String? base64string;
  XFile? image;
  XFile selectedImage = XFile("");

  @override
  void initState() {
    image = null;
    profileImageEdit = appStoragePref.getCustomerImage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // 🟢 1. The Circular Image
          Container(
            padding: const EdgeInsets.all(4), // White border effect
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
              ]
            ),
            child: CircleAvatar(
              radius: 55, // Bigger size
              backgroundColor: Colors.grey[200],
              backgroundImage: (image != null)
                  ? FileImage(File(image!.path))
                  : (profileImageEdit.isNotEmpty)
                      ? NetworkImage('$profileImageEdit?${DateTime.now().millisecondsSinceEpoch.toString()}') as ImageProvider
                      : const AssetImage(AssetConstants.customerProfilePlaceholder),
            ),
          ),

          // 🟢 2. The Floating "Edit" Button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showChoiceBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary, // Brand Green
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showChoiceBottomSheet(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    StringConstants.chooseOption.localized(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.photo_library, color: Colors.orange),
                  ),
                  title: Text(StringConstants.gallery.localized(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _openGallery(context),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: Text(StringConstants.camera.localized(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _openCamera(context),
                )
              ],
            ),
          );
        });
  }

  void _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _processImage(pickedFile);
    }
    if (mounted) Navigator.pop(context);
  }

  void _openGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processImage(pickedFile);
    }
    if (mounted) Navigator.pop(context);
  }

  void _processImage(XFile file) async {
    selectedImage = file;
    Uint8List imageBytes = await selectedImage.readAsBytes();
    base64string = base64.encode(imageBytes);
    widget.callback!(base64string);
    setState(() {
      image = file;
    });
  }
}