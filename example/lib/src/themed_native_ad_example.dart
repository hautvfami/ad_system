import 'package:flutter/material.dart';
import 'package:ad_system/ad_system.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Example widget demonstrating the use of theme-aware native ads
class ThemedNativeAdExample extends StatefulWidget {
  const ThemedNativeAdExample({super.key});

  @override
  State<ThemedNativeAdExample> createState() => _ThemedNativeAdExampleState();
}

class _ThemedNativeAdExampleState extends State<ThemedNativeAdExample> {
  NativeAd? _nativeAd;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Themed Native Ads'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Themed Native Ad Example',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Using the SmartNativeAd widget with theme awareness
              const SizedBox(
                height: 250,
                child: SmartNativeAd(
                  placementName: 'themed_example',
                  useThemeAwareStyling: true,
                  template: 'medium',
                  fallbackContent: Center(child: Text('No ad available')),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // Demonstrating the load and display approach with theme extension
              ElevatedButton(
                onPressed: () => _loadThemedAd(),
                child: const Text('Load Themed Ad Manually'),
              ),

              const SizedBox(height: 16),
              if (_nativeAd != null)
                SizedBox(
                  height: 250,
                  child: AdsManager.instance.createThemedNativeAdContainer(
                    context: context,
                    nativeAd: _nativeAd!,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadThemedAd() {
    // Dispose the previous ad if it exists
    _nativeAd?.dispose();
    _nativeAd = null;

    setState(() {});

    // Load a new themed ad
    AdsManager.instance.loadThemedNativeAd(
      context: context,
      placementName: 'manual_themed_example',
      template: 'medium',
      onAdLoaded: (ad) {
        setState(() {
          _nativeAd = ad as NativeAd;
        });
      },
      onAdFailedToLoad: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load ad: $error')));
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}
