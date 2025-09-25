import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/server_configuration.dart';
import 'package:bagisto_app_demo/screens/sign_in/utils/index.dart';

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
  String? verificationId;

  // Country code state
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971'];
  String _countryCode = '+91';

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔼 Fullscreen gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4CAF50), // green
                  Color(0xFFFFF176), // yellowish
                ],
              ),
            ),
          ),

          // 🔽 Bottom sheet (input area)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0x80FFFFFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔼 Centered Logo + Tagline
                      Center(
                        child: Image.asset(
                          'assets/images/SmartTrolley.png', // update path if needed
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Smart deals. Daily essentials. Delivery fast.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1b5E20),
                          fontFamily: 'Roboto',
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        otpSent ? "Enter OTP" : "Enter Mobile Number",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ==========================
                      // 📱 Mobile / OTP Input Area
                      // ==========================
                      if (!otpSent)
                        _MobileNumberField(
                          countryCodes: _countryCodes,
                          selectedCode: _countryCode,
                          onCodeChanged: (code) => setState(() => _countryCode = code),
                          controller: phoneController,
                        )
                      else
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter OTP',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black26),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length != 6) {
                              return 'Enter a valid 6-digit OTP';
                            }
                            return null;
                          },
                        ),

                      const SizedBox(height: 16),

                      // 🔘 Send OTP / Verify (Orange, rounded, with bounce)
                      BounceButton(
                        onPressed: _onSubmit,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange, // bright orange
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14), // soft rounded
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              elevation: 2,
                            ),
                            onPressed: _onSubmit,
                            child: Text(otpSent ? 'Verify OTP' : 'Send OTP'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider "OR"
                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1, color: Colors.black26)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("OR"),
                          ),
                          Expanded(child: Divider(thickness: 1, color: Colors.black26)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🔘 SSO Buttons (Brand colors, side-by-side)
                      Row(
                        children: [
                          // Google
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                elevation: 0,
                              ),
                              icon: Image.asset('assets/images/google.png', height: 20),
                              label: const Text("Google"),
                              onPressed: () {
                                // TODO: Add Google sign-in logic
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Apple
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                              label: const Text("Apple"),
                              onPressed: () {
                                // TODO: Add Apple sign-in logic
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Thin line after SSO
                      const Divider(thickness: 0.5, color: Colors.black26),
                      const SizedBox(height: 8),

                      // 🔽 Terms & Privacy (soft, small, green links)
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          children: [
                            const TextSpan(text: "By signing in, you agree to SmartTrolley’s "),
                            TextSpan(
                              text: "Terms",
                              style: const TextStyle(
                                color: Colors.green,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/terms');
                                },
                            ),
                            const TextSpan(text: " & "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: Colors.green,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/privacy');
                                },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!otpSent) {
      final cleanNumber = phoneController.text.trim();
      if (cleanNumber.length != 10) {
        ShowMessage.errorNotification('Enter a valid 10-digit number', context);
        return;
      }

      final phone = '$_countryCode$cleanNumber';
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _goToHome();
        },
        verificationFailed: (e) {
          ShowMessage.errorNotification(e.message ?? 'Verification failed', context);
        },
        codeSent: (verId, _) {
          setState(() {
            verificationId = verId;
            otpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (verId) {
          verificationId = verId;
        },
      );
    } else {
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: otpController.text.trim(),
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        _goToHome();
      } catch (e) {
        ShowMessage.errorNotification('Invalid OTP', context);
      }
    }
  }

  void _goToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }
}

/// ===============================================
///  📦 Mobile Number Field with Country Code
/// ===============================================
class _MobileNumberField extends StatelessWidget {
  final List<String> countryCodes;
  final String selectedCode;
  final ValueChanged<String> onCodeChanged;
  final TextEditingController controller;

  const _MobileNumberField({
    Key? key,
    required this.countryCodes,
    required this.selectedCode,
    required this.onCodeChanged,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Country code dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              items: countryCodes
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onCodeChanged(v);
              },
            ),
          ),
          const VerticalDivider(width: 8, thickness: 1, color: Colors.black12),
          // Number input
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Enter mobile number',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================
///  🎯 Bounce micro-animation wrapper
/// ===============================================
class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const BounceButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> {
  double _scale = 1.0;

  void _tapDown(_) => setState(() => _scale = 0.96);
  void _tapUp(_) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    }
}
