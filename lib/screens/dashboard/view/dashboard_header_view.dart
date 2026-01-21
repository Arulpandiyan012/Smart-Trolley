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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🟢 1. Single Row Profile Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(AssetConstants.customerProfilePlaceholder),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),

              // Details Column (Name, Email/Phone) in Single Row Flow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (name ?? "Guest User").toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                     // Email or Phone 
                    if (customerEmail != null && customerEmail!.isNotEmpty)
                      Text(
                        customerEmail!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]), 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (customerPhone != null && customerPhone!.isNotEmpty)
                       Text(
                        customerPhone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]), 
                      ),
                  ],
                ),
              ),
            ],
          ),

          // 🟢 2. Edit Icon (Aligned Right)
          Positioned(
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
                  color: const Color(0xFFF3F4F6), 
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_outlined, 
                  size: 18, 
                  color: Color(0xFF2E7D32), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}