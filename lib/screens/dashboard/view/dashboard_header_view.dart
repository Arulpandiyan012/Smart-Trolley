import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bagisto_app_demo/screens/dashboard/utils/index.dart';

class DashboardHeaderView extends StatefulWidget {
  const DashboardHeaderView({Key? key}) : super(key: key);

  @override
  State<DashboardHeaderView> createState() => _DashboardHeaderViewState();
}

class _DashboardHeaderViewState extends State<DashboardHeaderView> {
  String? name;
  String? customerEmail;
  String? customerPhone;
  String? image;

  @override
  void initState() {
    _fetchUserData();
    super.initState();
  }

  void _fetchUserData() {
    name = appStoragePref.getCustomerName();
    customerEmail = appStoragePref.getCustomerEmail();
    customerPhone = appStoragePref.getCustomerPhone();
    image = appStoragePref.getCustomerImage();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      // 🟢 Compact Padding: Reduces overall height to ~20% of screen
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        children: [
          // 🟢 1. Centered Content (Profile + Info)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Takes minimal height
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image (Reduced to 60px)
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))
                    ]
                  ),
                  child: ClipOval(
                    child: (image != null && image!.isNotEmpty)
                        ? CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: image!,
                            placeholder: (context, url) =>
                                Image.asset(AssetConstants.customerProfilePlaceholder),
                            errorWidget: (context, url, error) =>
                                Image.asset(AssetConstants.customerProfilePlaceholder),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(AssetConstants.customerProfilePlaceholder),
                          ),
                  ),
                ),
                
                const SizedBox(height: 10), // Reduced spacing

                // Name
                Text(
                  (name ?? "Guest User").toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16, // Smaller Font
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                
                const SizedBox(height: 4),

                // Email
                if (customerEmail != null && customerEmail!.isNotEmpty)
                  Text(
                    customerEmail!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500), // Smaller Font
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Phone
                if (customerPhone != null && customerPhone!.isNotEmpty)
                  Text(
                    customerPhone!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500), // Smaller Font
                  ),
              ],
            ),
          ),

          // 🟢 2. Edit Icon (Top Right Corner)
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(accountInfo).then((value) {
                  setState(() {
                    _fetchUserData();
                  });
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), // Light Grey Circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined, // Clean Edit Icon
                  size: 20, 
                  color: Color(0xFF2E7D32), // Green
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}