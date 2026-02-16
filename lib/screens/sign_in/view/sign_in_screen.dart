/*
 * Webkul Software.
 * @package Mobikul Application Code.
 * @Category Mobikul
 */


import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bagisto_app_demo/screens/sign_in/utils/index.dart';
import 'package:bagisto_app_demo/screens/vendor/vendor_login/view/vendor_login_screen.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  
  bool otpSent = false;
  bool isLoggingIn = false; 
  String? verificationId;
  String _countryCode = '+91';
  bool isButtonPressed = false; 

  // --- IMAGE ASSETS FOR 4 ROWS ---
  
  // Row 1: Essentials
  final List<String> row1Images = [
    'assets/images/milk_carton.png',
    'assets/images/bread_packet.png',
    'assets/images/eggs_carton.png',
    'assets/images/butter_block.webp',
    'assets/images/curd_cup.png',
  ];

  // Row 2: Veggies
  final List<String> row4Images = [
    'assets/images/banana_bunch.png',
    'assets/images/tomato_fresh.png',
    'assets/images/onion_red.png',
    'assets/images/potato_fresh.jpg',
    'assets/images/coriander_bunch.png',
  ];

  // Row 3: Snacks
  final List<String> row3Images = [
    'assets/images/chips_blue.png',
    'assets/images/chips_red.png',
    'assets/images/coke_can.png',
    'assets/images/chocolate_bar.png',
    'assets/images/biscuits_pack.jpeg',
  ];

  // 🟢 NEW Row 4: Household
  final List<String> row2Images = [
    'assets/images/detergent_pack.jpeg',
    'assets/images/soap_bar.jpg',
    'assets/images/toothpaste_tube.png',
    'assets/images/shampoo_bottle.png',
    'assets/images/tissue_box.png',
  ];

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get total screen height
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. BACKGROUND IMAGES (FILLS TOP 70%)
          // ---------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.70, // 70% Height
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor, 
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40), 
                      
                      // Row 1
                      Expanded(
                        child: AutoScrollingRow(
                          children: _buildProductCards(row1Images, const Color(0xFFFFF8E1)), 
                          duration: const Duration(seconds: 40),
                          reverse: false,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Row 2
                      Expanded(
                        child: AutoScrollingRow(
                          children: _buildProductCards(row2Images, const Color(0xFFE8F5E9)), 
                          duration: const Duration(seconds: 45),
                          reverse: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Row 3
                      Expanded(
                        child: AutoScrollingRow(
                          children: _buildProductCards(row3Images, const Color(0xFFE3F2FD)), 
                          duration: const Duration(seconds: 42),
                          reverse: false,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🟢 NEW Row 4
                      Expanded(
                        child: AutoScrollingRow(
                          children: _buildProductCards(row4Images, const Color(0xFFF3E5F5)), 
                          duration: const Duration(seconds: 38),
                          reverse: true,
                        ),
                      ),
                      
                      const SizedBox(height: 40), 
                    ],
                  ),
                  
                  // Gradient Overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                            Theme.of(context).scaffoldBackgroundColor, 
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. BACK BUTTON
          // ---------------------------------------------------------
          Positioned(
            top: 50, 
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                  ]
                ),
                child: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color, size: 24),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 3. BOTTOM FORM
          // ---------------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Theme.of(context).scaffoldBackgroundColor, blurRadius: 30, spreadRadius: 20, offset: const Offset(0, -20))],
              ),
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 10),
              child: SafeArea(
                top: false, 
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    
                    // 1. LOGO with LIGHT BG
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12), 
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Image.asset(
                          'assets/images/SmartTrolley.png', 
                          height: 40, 
                          width: 40,
                          fit: BoxFit.contain,filterQuality: FilterQuality.high, // 🟢 FIX: Removes scaling artifacts/lines
                          isAntiAlias: true, // 🟢 FIX: Smooths edges
                          // color: const Color(0xFF27C16B), // Dark Brand Green
                          errorBuilder: (c, o, s) => const Icon(Icons.shopping_cart, size: 30, color: Color(0xFF27C16B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 2. HEADLINE
                    Text(
                      otpSent ? "Verification Code" : "Log in or Sign up",
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.titleSmall?.color, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),

                    // 3. INPUT
                    if (!otpSent)
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor), 
                        ),
                        child: Row(
                          children: [
                            Text("+91", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(width: 12),
                            Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Enter mobile number",
                                  contentPadding: EdgeInsets.only(bottom: 2), 
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 50,
                        child: TextField(
                          controller: otpController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "- - - - - -",
                            filled: true,
                            fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 4. TRENDY BUTTON
                    GestureDetector(
                      onTapDown: (_) => setState(() => isButtonPressed = true),
                      onTapUp: (_) => setState(() => isButtonPressed = false),
                      onTapCancel: () => setState(() => isButtonPressed = false),
                      onTap: isLoggingIn ? null : _onSubmit,
                      child: AnimatedScale(
                        scale: isButtonPressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF27C16B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
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
                          child: Center(
                            child: isLoggingIn 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                              : Text(
                                  otpSent ? "Verify & Login" : "Continue", 
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                                ),
                          ),
                        ),
                      ),
                    ),
                    
                    
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, otpExplanation);
                      },
                      child: Text(
                        StringConstants.whatIsOtp.localized(),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    
                    // 5. TERMS
                    Text(
                      "By continuing, you agree to our Terms of Service & Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                    ),
                    
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorLoginScreen()));
                      },
                      child: Text("Are you a Vendor? Login here", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD PRODUCT CARDS (Uses actual images) ---
  List<Widget> _buildProductCards(List<String> images, Color bgColor) {
    // Repeat to allow infinite scrolling
    final displayList = [...images, ...images, ...images];

    return displayList.map((imagePath) {
      return Container(
        width: 100, // Fixed Width
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? Color.alphaBlend(bgColor.withOpacity(0.1), const Color(0xFF1A1A1A)) 
            : bgColor, 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) => Icon(Icons.broken_image, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4, width: 40, 
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
            )
          ],
        ),
      );
    }).toList();
  }

  // --- LOGIC SECTION ---
  Future<void> _onSubmit() async {
    if (isLoggingIn) return; 
    setState(() => isLoggingIn = true);

    try {
      if (!otpSent) {
        if (phoneController.text.length != 10) {
           setState(() => isLoggingIn = false);
           ShowMessage.errorNotification("Enter valid mobile number", context);
           return;
        }

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: '$_countryCode${phoneController.text.trim()}',
          verificationCompleted: (credential) async {
             UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
             if (userCred.user != null) await _authenticateWithBackend(userCred.user!);
          },
          verificationFailed: (e) {
            setState(() => isLoggingIn = false);
            ShowMessage.errorNotification(e.message ?? "Error", context);
          },
          codeSent: (verId, _) {
            setState(() { verificationId = verId; otpSent = true; isLoggingIn = false; });
          },
          codeAutoRetrievalTimeout: (verId) => verificationId = verId,
        );
      } else {
        if (otpController.text.length != 6) {
           setState(() => isLoggingIn = false);
           return; 
        }
        final credential = PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: otpController.text.trim());
        UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCred.user != null) await _authenticateWithBackend(userCred.user!);
      }
    } catch (e) {
      setState(() => isLoggingIn = false);
      print(e);
    }
  }

  Future<void> _authenticateWithBackend(User user) async {
    try {
      String? idToken = await user.getIdToken();
      String phone = user.phoneNumber ?? "";
      var result = await ApiClient().firebaseOtpLogin(idToken!, phone);
      if (result != null && result.status == true) {
        appStoragePref.setCustomerPhone(phone);
        if(mounted) Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
      } else {
        setState(() => isLoggingIn = false);
        ShowMessage.errorNotification("Login Failed", context);
      }
    } catch(e) {
      setState(() => isLoggingIn = false);
    }
  }
}

// --- MARQUEE WIDGET ---
class AutoScrollingRow extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final bool reverse;

  const AutoScrollingRow({
    Key? key,
    required this.children,
    this.duration = const Duration(seconds: 10),
    this.reverse = false,
  }) : super(key: key);

  @override
  State<AutoScrollingRow> createState() => _AutoScrollingRowState();
}

class _AutoScrollingRowState extends State<AutoScrollingRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
    _controller.addListener(() {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double offset = _controller.value * maxScroll;
        if (widget.reverse) offset = maxScroll - offset;
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), 
      children: [
        ...widget.children,
        ...widget.children, 
        ...widget.children,
      ],
    );
  }
}