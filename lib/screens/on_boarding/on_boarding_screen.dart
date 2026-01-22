import 'package:bagisto_app_demo/utils/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Premium Quality Products\nHandpicked For You",
      "image": "assets/images/onboard1.jpeg"
    },
    {
      "title": "Grocery Shopping With\nMaximum Savings",
      "image": "assets/images/onboard2.png"
    },
    {
      "title": "Fastest Delivery\nGuaranteed!",
      "image": "assets/images/onboard3.png"
    },
  ];

  _completeOnboarding() {
    GetStorage().write('hasSeenOnboarding', true);
    Navigator.pushReplacementNamed(context, home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Back button could go here if needed, but usually empty on first screen
                   const SizedBox(),
                   if (_currentPage != _onboardingData.length - 1)
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                   if (_currentPage == _onboardingData.length - 1)
                     GestureDetector(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Skip", // Kept consistency, though usually hidden on last step
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ), 
                ]
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: _onboardingData[index]["title"] ?? "",
                  image: _onboardingData[index]["image"] ?? "",
                ),
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => buildDot(index: index),
              ),
            ),
            const SizedBox(height: 30),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107), // Yellow color from design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        _currentPage == _onboardingData.length - 1 ? "Get Started" : "Next",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 16,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 4,
      width: _currentPage == index ? 25 : 15,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.black : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, image;
  const OnboardingContent({
    Key? key,
    required this.title,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 1),
        // Image Placeholder Area
        Container(
           margin: const EdgeInsets.symmetric(horizontal: 20),
           height: 300,
           width: double.infinity,
           decoration: const BoxDecoration(
             // color: Color(0xFFF5F5F5), // Light background for image area
             shape: BoxShape.circle, // Or rounded rect depending on asset
           ),
           child: Center(
             child: Image.asset(
               image,
               height: 280,
               width: 280,
               fit: BoxFit.contain,
               errorBuilder: (context, error, stackTrace) {
                 return const Center(child: Icon(Icons.error, color: Colors.red));
               },
             ),
           ),
        ),
        const Spacer(flex: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600, // Semi-bold
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

