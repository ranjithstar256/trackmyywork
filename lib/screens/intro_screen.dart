import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';


void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const IntroScreen()
  ));
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) async {
    // Save that the user has seen the intro
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    // Navigate to the home screen
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Widget _buildSvgImage(String svgString, [double width = 250]) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: SvgPicture.string(
        svgString,
        width: width,
        height: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      fontSize: 18.0, 
      color: Theme.of(context).colorScheme.onBackground,
      height: 1.5,
    );
    
    final titleStyle = TextStyle(
      fontSize: 26.0, 
      fontWeight: FontWeight.w700, 
      color: Theme.of(context).colorScheme.primary,
      height: 1.4,
    );
    
    final pageDecoration = PageDecoration(
      titleTextStyle: titleStyle,
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      imagePadding: const EdgeInsets.only(top: 40.0),
      contentMargin: const EdgeInsets.symmetric(horizontal: 16.0),
      titlePadding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
      bodyAlignment: Alignment.center,
      imageAlignment: Alignment.center,
    );

    // Simple SVG strings for placeholders
    final clockSvg = '''
<svg width="200" height="200" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="100" cy="100" r="90" stroke="${Theme.of(context).colorScheme.primary.toHex()}" stroke-width="10" fill="none"/>
  <line x1="100" y1="100" x2="100" y2="50" stroke="${Theme.of(context).colorScheme.primary.toHex()}" stroke-width="8" stroke-linecap="round"/>
  <line x1="100" y1="100" x2="140" y2="120" stroke="${Theme.of(context).colorScheme.primary.toHex()}" stroke-width="6" stroke-linecap="round"/>
</svg>
''';

    final chartSvg = '''
<svg width="200" height="200" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="20" y="140" width="30" height="40" fill="${Theme.of(context).colorScheme.primary.toHex()}" />
  <rect x="60" y="100" width="30" height="80" fill="${Theme.of(context).colorScheme.primary.toHex()}" />
  <rect x="100" y="60" width="30" height="120" fill="${Theme.of(context).colorScheme.primary.toHex()}" />
  <rect x="140" y="80" width="30" height="100" fill="${Theme.of(context).colorScheme.primary.toHex()}" />
</svg>
''';

    final categoriesSvg = '''
<svg width="200" height="200" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="30" fill="${Theme.of(context).colorScheme.primary.toHex()}" />
  <circle cx="150" cy="50" r="30" fill="${Theme.of(context).colorScheme.secondary.toHex()}" />
  <circle cx="50" cy="150" r="30" fill="${Theme.of(context).colorScheme.tertiary?.toHex() ?? Theme.of(context).colorScheme.primary.toHex()}" />
  <circle cx="150" cy="150" r="30" fill="${Theme.of(context).colorScheme.error.toHex()}" />
</svg>
''';

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: IntroductionScreen(
            key: introKey,
            globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
            allowImplicitScrolling: true,
            autoScrollDuration: 3000,
            infiniteAutoScroll: false,
            globalHeader: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'TrackMyWork',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            pages: [
              PageViewModel(
                title: "Welcome to TrackMyWork",
                body: "Track your time efficiently and boost your productivity with our simple and intuitive app.",
                image: _buildSvgImage(clockSvg),
                decoration: pageDecoration,
              ),
              PageViewModel(
                title: "Track Your Activities",
                body: "Create activities and track how much time you spend on each one with just a tap.",
                image: _buildSvgImage(categoriesSvg),
                decoration: pageDecoration,
              ),
              PageViewModel(
                title: "Analyze Your Time",
                body: "Get detailed reports and visualizations to understand how you spend your time.",
                image: _buildSvgImage(chartSvg),
                decoration: pageDecoration,
              ),
              PageViewModel(
                title: "Privacy First",
                body: "All your data is stored locally on your device. We don't collect any personal information.",
                image: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Icon(
                    Icons.security,
                    size: 150.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                decoration: pageDecoration,
              ),
            ],
            onDone: () => _onIntroEnd(context),
            onSkip: () => _onIntroEnd(context),
            showSkipButton: true,
            skipOrBackFlex: 0,
            nextFlex: 0,
            showBackButton: false,
            back: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
            skip: Text(
              'Skip', 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: Theme.of(context).colorScheme.primary
              )
            ),
            next: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
            done: Text(
              'Done', 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: Theme.of(context).colorScheme.primary
              )
            ),
            curve: Curves.fastLinearToSlowEaseIn,
            controlsMargin: const EdgeInsets.all(16),
            controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
            dotsDecorator: DotsDecorator(
              size: const Size(10.0, 10.0),
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
              activeSize: const Size(22.0, 10.0),
              activeShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            dotsContainerDecorator: ShapeDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to convert Color to hex string for SVG
extension ColorExtension on Color {
  String toHex() => '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
