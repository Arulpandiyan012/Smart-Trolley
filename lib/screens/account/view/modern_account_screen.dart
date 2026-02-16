import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagisto_app_demo/utils/index.dart';
import 'package:bagisto_app_demo/widgets/image_view.dart';
import 'package:bagisto_app_demo/screens/account/utils/index.dart';
import 'package:bagisto_app_demo/screens/drawer/utils/index.dart' show LogoutButton;
import 'package:bagisto_app_demo/data_model/app_route_arguments.dart';
import 'package:bagisto_app_demo/utils/assets_constants.dart';
import 'package:provider/provider.dart';
import 'package:bagisto_app_demo/utils/theme_provider.dart';
import 'package:share_plus/share_plus.dart';

class ModernAccountScreen extends StatefulWidget {
  const ModernAccountScreen({super.key});

  @override
  State<ModernAccountScreen> createState() => _ModernAccountScreenState();
}

class _ModernAccountScreenState extends State<ModernAccountScreen> {
  String? name;
  String? email;
  String? phone;
  String? image;
  String? dob;
  bool isLoggedIn = false;
  StreamSubscription? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    _profileSubscription = GlobalData.profileUpdateStream.listen((data) {
      if (!mounted) return;
      setState(() {
        if (data.containsKey('name')) name = data['name'];
        if (data.containsKey('image')) image = data['image'];
        if (data.containsKey('email')) email = data['email'];
        if (data.containsKey('dob')) dob = data['dob'];
        isLoggedIn = appStoragePref.getCustomerLoggedIn();
      });
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _fetchUserData() {
    isLoggedIn = appStoragePref.getCustomerLoggedIn();
    if (isLoggedIn) {
      name = appStoragePref.getCustomerName();
      email = appStoragePref.getCustomerEmail();
      phone = appStoragePref.getCustomerPhone();
      image = appStoragePref.getCustomerImage();
      dob = appStoragePref.getCustomerDob();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildBirthdayBanner(),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 16),
                  _buildAppearanceCard(),
                  const SizedBox(height: 12),
                  _buildSensitiveItemsCard(),
                  const SizedBox(height: 20),
                  _buildSectionGroup(
                    "Your information",
                    [
                      _buildListTile(Icons.book_outlined, "Address book", () => Navigator.pushNamed(context, addressListScreen)),
                      _buildListTile(Icons.dashboard_outlined, "Dashboard", () => Navigator.pushNamed(context, dashboardScreen)),
                      _buildListTile(Icons.reviews_outlined, "Your reviews", () => Navigator.pushNamed(context, reviewList)),
                      _buildListTile(Icons.favorite_outline, "Your wishlist", () => Navigator.pushNamed(context, wishlistScreen)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionGroup(
                    "Settings & Information",
                    [
                      _buildListTile(Icons.language_outlined, "Language", () => Navigator.pushNamed(context, languageScreen)),
                      _buildListTile(Icons.currency_exchange_outlined, "Currency", () => Navigator.pushNamed(context, currencyScreen)),
                      _buildListTile(Icons.payment_outlined, "Payment settings", () => Navigator.pushNamed(context, paymentSettings)),
                      _buildListTile(Icons.share_outlined, "Share the app", () => _shareApp()),
                      _buildListTile(Icons.info_outline, "About us", () => Navigator.pushNamed(context, cmsScreen, arguments: CmsDataContent(title: "About Us", id: 1, index: 0))),
                      _buildListTile(Icons.contact_support_outlined, "Contact us", () => Navigator.pushNamed(context, contactUsScreen)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoggedIn)
                    _buildSectionGroup(
                      "Account Actions",
                      [
                        _buildListTile(Icons.lock_outline, "Account privacy", () {}),
                        _buildListTile(Icons.notifications_none_outlined, "Notification preferences", () {}),
                        _buildListTile(Icons.power_settings_new_outlined, "Log out", () => _showLogoutDialog()),
                      ],
                    ),
                  const SizedBox(height: 40),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDark == "true";

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark ? Colors.black : const Color(0xFFFFF9C4),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                    ? [Colors.black, Colors.grey[900]!] 
                    : [const Color(0xFFFFF9C4), Theme.of(context).scaffoldBackgroundColor],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Theme.of(context).cardColor, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)
                      ],
                    ),
                    child: ClipOval(
                      child: ImageView(
                        url: image,
                        fit: BoxFit.cover,
                        placeHolder: AssetConstants.customerProfilePlaceholder,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isLoggedIn ? (name ?? "User") : "Welcome to Smart Trolley",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w800, 
                      color: Theme.of(context).textTheme.titleLarge?.color
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoggedIn && (phone?.isNotEmpty == true || email?.isNotEmpty == true))
                    Text(
                      phone ?? email ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Theme.of(context).textTheme.bodySmall?.color, 
                        fontWeight: FontWeight.w500
                      ),
                    )
                  else if (!isLoggedIn)
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, signIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("LOGIN / SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                ],
              ),
            ),
            if (isLoggedIn)
              Positioned(
                right: 20,
                top: 100,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, accountInfo),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                      ],
                    ),
                    child: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayBanner() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isBirthdaySet = dob != null && dob!.isNotEmpty;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, accountInfo),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : const Color(0xFFFFF9E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Theme.of(context).dividerColor : const Color(0xFFFFE082).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBirthdaySet ? "Your birthday" : "Add your birthday",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleMedium?.color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isBirthdaySet ? dob! : "Enter details", 
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      if (!isBirthdaySet) Icon(Icons.play_arrow, size: 12, color: Theme.of(context).primaryColor),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isBirthdaySet ? Icons.cake_outlined : Icons.cake, 
              size: 48, 
              color: isBirthdaySet ? Theme.of(context).primaryColor.withOpacity(0.7) : const Color(0xFFFFAB40)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        _buildGridItem(Icons.shopping_basket_outlined, "Your orders", () => Navigator.pushNamed(context, orderListScreen)),
        const SizedBox(width: 12),
        _buildGridItem(Icons.account_balance_wallet_outlined, "Wallet", () {}),
        const SizedBox(width: 12),
        _buildGridItem(Icons.chat_bubble_outline, "Need help?", () {}),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).iconTheme.color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.labelSmall?.color
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDark == "true";

    return InkWell(
      onTap: () => _showAppearancePicker(themeProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined, size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text("Appearance", style: TextStyle(fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(isDark ? "DARK" : "LIGHT", 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearancePicker(ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose Appearance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildThemeOption(ctx, "Light Mode", Icons.wb_sunny_outlined, provider.isDark == "false", () {
              provider.isDark = "false";
              Navigator.pop(ctx);
            }),
            _buildThemeOption(ctx, "Dark Mode", Icons.nightlight_round, provider.isDark == "true", () {
              provider.isDark = "true";
              Navigator.pop(ctx);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext ctx, String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
      onTap: onTap,
    );
  }

  Widget _buildSensitiveItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hide sensitive items", style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleSmall?.color
                )),
                const SizedBox(height: 4),
                Text(
                  "Sexual wellness, nicotine products and other sensitive items will be hidden",
                  style: TextStyle(
                    fontSize: 11, 
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: false,
            onChanged: (v) {},
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w800, 
              color: Theme.of(context).textTheme.titleLarge?.color
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        if (!isLoggedIn && (label.contains("Address") || label.contains("Dashboard") || label.contains("reviews") || label.contains("wishlist") || label.contains("orders"))) {
           ShowMessage.warningNotification("Please login to access $label", context);
           Navigator.pushNamed(context, signIn);
        } else {
           onTap();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500, 
                  color: Theme.of(context).textTheme.bodyLarge?.color
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Theme.of(context).iconTheme.color?.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Image.asset(AssetConstants.placeHolder, height: 40, color: Theme.of(context).dividerColor), // Blinkit grey logo
        const SizedBox(height: 8),
        Text(
          "v1.0.0",
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    appStoragePref.setCustomerLoggedIn(false);
    appStoragePref.onUserLogout();
    GlobalData.profileUpdateStream.add({});
    GlobalData.optimisticClearCart();
    Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }

  void _shareApp() {
    const String appLink = "https://play.google.com/store/apps/details?id=com.thesmartedgetech.smarttrolley"; // Replace with your actual app link
    Share.share(
      "Check out Smart Trolley for amazing deals on groceries and more! Download here: $appLink",
      subject: "Download Smart Trolley App",
    );
  }
}
