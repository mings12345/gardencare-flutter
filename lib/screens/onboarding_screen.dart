import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';

final pages = [
  const PageData(
    icon: Icons.local_florist,
    title: "Discover Plants",
    bgColor: Color(0xff4caf50),
    textColor: Colors.white,
  ),
  const PageData(
    icon: Icons.grass,
    title: "Learn Gardening Tips",
    bgColor: Color(0xff8bc34a),
    textColor: Colors.white,
  ),
  const PageData(
    icon: Icons.eco,
    title: "Grow Your Garden",
    bgColor: Color(0xffcddc39),
    textColor: Colors.white,
  ),
  const PageData(
    icon: Icons.check,
    title: "Get Started",
    bgColor: Color(0xff8bc34a),
    textColor: Colors.white,
  ),
];

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.bgColor).toList(),
        radius: screenWidth * 0.1,
        nextButtonBuilder: (context) => Padding(
          padding: const EdgeInsets.only(left: 3), // visual center
          child: Icon(
            Icons.navigate_next,
            size: screenWidth * 0.08,
          ),
        ),
        // enable itemcount to disable infinite scroll
        // itemCount: pages.length,
        // opacityFactor: 2.0,
        scaleFactor: 2,
        // verticalPosition: 0.7,
        // direction: Axis.vertical,
        // itemCount: pages.length,
        // physics: NeverScrollableScrollPhysics(),
        itemBuilder: (index) {
          final page = pages[index % pages.length];
          return SafeArea(
            child: _Page(page: page),
          );
        },
      ),
    );
  }
}

class PageData {
  final String? title;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.title,
    this.icon,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class _Page extends StatelessWidget {
  final PageData page;

  const _Page({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: page.textColor),
          child: Icon(
            page.icon,
            size: screenHeight * 0.1,
            color: page.bgColor,
          ),
        ),
        Text(
          page.title ?? "",
          style: TextStyle(
              color: page.textColor,
              fontSize: screenHeight * 0.035,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (page.title == "Get Started")
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text("Get Started"),
          ),
      ],
    );
  }
} 