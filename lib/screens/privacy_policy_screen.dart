import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition on Android
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Stack(
        children: [
          Semantics(
            label: 'Privacy Policy Document',
            hint: 'Displays the app privacy policy',
            child: WebView(
              initialUrl: 'about:blank',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
                _loadHtmlFromAssets();
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              gestureNavigationEnabled: true, // Enable navigation gestures
              // Reduce memory usage by setting these parameters
              initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _loadHtmlFromAssets() async {
    try {
      final String fileText = await rootBundle.loadString('assets/privacy_policy.html');
      final String contentBase64 = Uri.dataFromString(
        fileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')!,
      ).toString();
      await _controller.loadUrl(contentBase64);
    } catch (e) {
      debugPrint('Error loading privacy policy: $e');
      final String fallbackContent = Uri.dataFromString(
        '<html><body><h1>Privacy Policy</h1><p>Unable to load the full privacy policy. Please contact support@trackmywork.app for assistance.</p></body></html>',
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')!,
      ).toString();
      await _controller.loadUrl(fallbackContent);
    }
  }

  @override
  void dispose() {
    // Clean up WebView resources to prevent memory leaks
    if (Platform.isAndroid) {
      _controller.clearCache();
      // Additional cleanup to ensure no memory leaks
      _controller.loadUrl('about:blank');
    }
    // Always call super.dispose() last
    super.dispose();
  }
}
