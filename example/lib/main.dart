// ignore_for_file: depend_on_referenced_packages

import 'package:ad_system/ad_system.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    MobileAds.instance.initialize(),
  ]);
  await AdsManager.instance.initialize();

  // thing to add
  RequestConfiguration configuration = RequestConfiguration(
    testDeviceIds: ["4C13A3763C9D392AFEA9F572992AA43F"],
  );
  MobileAds.instance.updateRequestConfiguration(configuration);

  runApp(const MyApp());
}
