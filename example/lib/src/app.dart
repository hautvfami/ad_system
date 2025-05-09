import 'package:flutter/material.dart';
import 'package:ad_system/ad_system.dart';

import 'home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad System Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AdDemoPage(),
    );
  }
}

class AdDemoPage extends StatefulWidget {
  const AdDemoPage({super.key});

  @override
  State<AdDemoPage> createState() => _AdDemoPageState();
}

class _AdDemoPageState extends State<AdDemoPage> {
  @override
  void initState() {
    super.initState();
    // _initializeAds();
  }

  // Future<void> _initializeAds() async {
  //   await AdsManager.instance.initialize();
  // }

  void _showInterstitialAd() {
    if (AdsManager.instance.isInterstitialAdLoaded) {
      AdsManager.instance.showInterstitialAd();
    } else {
      print('Interstitial Ad is not loaded yet.');
    }
  }

  void _showRewardedAd() {
    AdsManager.instance.showRewardedAd(
      onRewarded: (amount, type) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reward earned: $amount $type')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ad System Demo')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Welcome to the Ad System Demo!'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showInterstitialAd,
            child: const Text('Show Interstitial Ad'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showRewardedAd,
            child: const Text('Show Rewarded Ad'),
          ),
          const Spacer(),
          const SmartBannerAd(),
        ],
      ),
    );
  }
}
