// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:ad_system/ad_system.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'native_ads_list_demo.dart';
import 'themed_native_ad_example.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
  // Best practice: Khởi tạo biến để theo dõi trạng thái tải của quảng cáo
  final RxBool _isInitialized = false.obs;
  final RxBool _isLoading = false.obs;
  final RxString _lastAdResult = ''.obs;
  final RxBool _isTestMode = false.obs;

  @override
  void initState() {
    super.initState();
    _initializeAds();
  }

  // Best practice: Khởi tạo ads system ở initState và hiển thị trạng thái
  Future<void> _initializeAds() async {
    _isLoading.value = true;
    try {
      await AdsManager.instance.initialize();
      _isInitialized.value = true;
      _lastAdResult.value = 'Ads đã được khởi tạo thành công';
      // Best practice: Preload ads sau khi khởi tạo
      _preloadInterstitialAd();
    } catch (e) {
      _lastAdResult.value = 'Lỗi khởi tạo: $e';
    }
    _isLoading.value = false;
  }

  // Best practice: Tải trước quảng cáo xen kẽ để sẵn sàng hiển thị
  void _preloadInterstitialAd() {
    try {
      AdsManager.instance.loadInterstitialAd(
        placementName: 'default',
        onAdLoaded: () {
          _lastAdResult.value = 'Interstitial Ad đã được tải sẵn';
          setState(() {}); // Refresh UI để cập nhật trạng thái nút
        },
        onAdFailedToLoad: (error) {
          _lastAdResult.value = 'Không thể tải Interstitial Ad: $error';
        },
      );
    } catch (e) {
      _lastAdResult.value = 'Lỗi khi tải trước quảng cáo: $e';
    }
  }

  // Best practice: Kiểm tra trạng thái trước khi hiển thị quảng cáo
  void _showInterstitialAd() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    // In thông tin debug trước khi hiển thị quảng cáo
    _logAdLimits(AdType.interstitial);

    if (AdsManager.instance.isInterstitialAdLoaded) {
      _lastAdResult.value = 'Đang hiển thị Interstitial Ad...';

      AdsManager.instance.showInterstitialAd(
        placementName: 'default',
        onAdDismissed: () {
          _lastAdResult.value = 'Interstitial Ad đã đóng';
          // Best practice: Tải lại quảng cáo mới sau khi hiển thị
          _preloadInterstitialAd();
        },
        onAdFailedToShow: (error) {
          _lastAdResult.value = 'Không thể hiển thị Interstitial Ad: $error';
          // Best practice: Tải lại quảng cáo khi gặp lỗi
          _preloadInterstitialAd();
        },
      );
    } else {
      _lastAdResult.value = 'Interstitial Ad chưa được tải. Đang tải lại...';
      _preloadInterstitialAd();
    }
  }

  // Hiển thị log chi tiết về các giới hạn quảng cáo
  void _logAdLimits(AdType adType) {
    print('\n===== AD LIMITS DEBUG INFO =====');
    print('Ad Type: ${adType.toString()}');

    try {
      // 1. Kiểm tra trạng thái tải
      if (adType == AdType.interstitial) {
        print(
          'Is Interstitial Ad loaded: ${AdsManager.instance.isInterstitialAdLoaded}',
        );
      }

      // 2. Kiểm tra giới hạn và phân đoạn người dùng
      print('Can show this ad type: ${AdsManager.instance.canShowAd(adType)}');

      // 3. In thông tin chi tiết về các giới hạn (gọi hàm printAdDebugInfo trong AdsManager)
      AdsManager.instance.printAdDebugInfo(adType);
    } catch (e) {
      print('Error getting ad limits: $e');
    }
    print('================================\n');
  }

  // Best practice: Xử lý phần thưởng và theo dõi lỗi khi hiển thị rewarded ad
  void _showRewardedAd() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    _logAdLimits(AdType.rewarded);
    _lastAdResult.value = 'Đang hiển thị Rewarded Ad...';

    AdsManager.instance.showRewardedAd(
      placementName: 'default',
      onRewarded: (amount, type) {
        _lastAdResult.value = 'Phần thưởng nhận được: $amount $type';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phần thưởng nhận được: $amount $type')),
        );
      },
      onAdDismissed: () {
        debugPrint('Rewarded Ad đã đóng');
      },
      onAdFailedToShow: (error) {
        _lastAdResult.value = 'Không thể hiển thị Rewarded Ad: $error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $error')));
      },
    );
  }

  // Best practice: Hiển thị Native Ad và xử lý các trạng thái khác nhau
  void _loadAndShowNativeAd() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    _logAdLimits(AdType.native);
    _lastAdResult.value = 'Đang tải Native Ad...';
    _isLoading.value = true;

    AdsManager.instance.loadNativeAd(
      placementName: 'home_native',
      template: 'medium',
      onAdLoaded: (ad) {
        _lastAdResult.value = 'Native Ad đã được tải thành công';
        _isLoading.value = false;

        // Hiển thị quảng cáo trong một dialog để người dùng có thể thấy
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Native Ad Example',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      width: double.maxFinite,
                      height: 300,
                      child: AdWidget(ad: ad),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Đóng'),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
        );
      },
      onAdFailedToLoad: (error) {
        _lastAdResult.value = 'Không thể tải Native Ad: $error';
        _isLoading.value = false;
      },
    );
  }

  // Best practice: Quản lý hiển thị quảng cáo khi vào app
  void _showAppOpenAd() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    _logAdLimits(AdType.appOpen);
    _lastAdResult.value = 'Đang hiển thị App Open Ad...';

    AdsManager.instance
        .showAppOpenAd()
        .then((shown) {
          if (shown) {
            _lastAdResult.value = 'App Open Ad đã được hiển thị';
          } else {
            _lastAdResult.value = 'App Open Ad không thể hiển thị';
          }
        })
        .catchError((error) {
          _lastAdResult.value = 'Lỗi khi hiển thị App Open Ad: $error';
        });
  }

  // Chuyển đổi giữa chế độ thường và chế độ test
  void _toggleTestMode() {
    _isTestMode.value = !_isTestMode.value;
    _lastAdResult.value =
        _isTestMode.value
            ? 'Đã bật chế độ Test Mode'
            : 'Đã tắt chế độ Test Mode';
  }

  // TEST MODE: Tăng số phiên người dùng
  void _incrementUserSessions() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    try {
      AdsManager.instance.incrementUserSessions();
      _lastAdResult.value = 'Đã tăng số phiên người dùng';
      _logAdLimits(AdType.interstitial);
    } catch (e) {
      _lastAdResult.value = 'Lỗi khi tăng số phiên: $e';
    }
  }

  // TEST MODE: Chuyển đổi phân đoạn người dùng
  void _changeUserSegment(UserSegment segment) {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    try {
      AdsManager.instance.setUserSegment(segment);
      _lastAdResult.value =
          'Đã chuyển người dùng sang phân đoạn: ${segment.toString().split('.').last}';
      _logAdLimits(AdType.interstitial);
    } catch (e) {
      _lastAdResult.value = 'Lỗi khi thay đổi phân đoạn người dùng: $e';
    }
  }

  // Best practice: Chuyển đổi người dùng sang trạng thái premium (không hiển thị quảng cáo)
  void _togglePremiumUser() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    // Giả định: checkIsPremium là một phương thức kiểm tra trạng thái premium hiện tại
    bool isPremium =
        AdsManager.instance.canShowAd(AdType.interstitial) == false;
    AdsManager.instance.setPremiumUser(!isPremium);

    _lastAdResult.value =
        !isPremium
            ? 'Đã chuyển sang chế độ Premium (không hiển thị quảng cáo)'
            : 'Đã chuyển sang chế độ thường (có hiển thị quảng cáo)';

    _logAdLimits(AdType.interstitial);
  }

  // Best practice: Chuyển đến trang demo danh sách với quảng cáo xen kẽ
  void _showNativeAdsInListView() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    _logAdLimits(AdType.native);
    _lastAdResult.value =
        'Đang chuẩn bị hiển thị danh sách với quảng cáo xen kẽ...';

    // Hiển thị trang mới với ListView có quảng cáo xen kẽ
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NativeAdsListViewDemo()),
    );
  }

  // Hiển thị trang demo quảng cáo native theo chủ đề
  void _showThemedNativeAdExample() {
    if (!_isInitialized.value) {
      _lastAdResult.value = 'Ads chưa được khởi tạo. Vui lòng đợi...';
      return;
    }

    _logAdLimits(AdType.native);
    _lastAdResult.value =
        'Đang chuẩn bị hiển thị quảng cáo native theo chủ đề...';

    // Hiển thị trang mới với quảng cáo native theo chủ đề
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ThemedNativeAdExample()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad System Demo'),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                _isTestMode.value
                    ? Icons.admin_panel_settings
                    : Icons.admin_panel_settings_outlined,
                color: _isTestMode.value ? Colors.orange : null,
              ),
              onPressed: _toggleTestMode,
              tooltip: 'Chế độ Test',
            ),
          ),
        ],
      ),
      body: Obx(
        () =>
            _isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Ad System Demo',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () =>
                                _isTestMode.value
                                    ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'TEST MODE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          'Trạng thái: ${_isInitialized.value ? 'Đã khởi tạo' : 'Chưa khởi tạo'}',
                          style: TextStyle(
                            color:
                                _isInitialized.value
                                    ? Colors.green
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Kết quả gần nhất: ${_lastAdResult.value}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildSection(
                              title: 'Khởi tạo',
                              children: [
                                _buildAdButton(
                                  title: 'Khởi tạo Ads System',
                                  onPressed: _initializeAds,
                                  icon: Icons.play_circle_outline,
                                ),
                              ],
                            ),

                            _buildSection(
                              title: 'Quảng cáo Xen kẽ (Interstitial)',
                              children: [
                                _buildAdButton(
                                  title: 'Tải trước Interstitial Ad',
                                  onPressed: _preloadInterstitialAd,
                                  icon: Icons.download,
                                ),
                                _buildAdButton(
                                  title: 'Hiển thị Interstitial Ad',
                                  onPressed: _showInterstitialAd,
                                  icon: Icons.fullscreen,
                                ),
                              ],
                            ),

                            _buildSection(
                              title: 'Quảng cáo Có thưởng (Rewarded)',
                              children: [
                                _buildAdButton(
                                  title: 'Hiển thị Rewarded Ad',
                                  onPressed: _showRewardedAd,
                                  icon: Icons.card_giftcard,
                                ),
                              ],
                            ),

                            _buildSection(
                              title: 'Quảng cáo Native',
                              children: [
                                _buildAdButton(
                                  title: 'Tải và hiển thị Native Ad',
                                  onPressed: _loadAndShowNativeAd,
                                  icon: Icons.snippet_folder,
                                ),
                                _buildAdButton(
                                  title: 'Native Ads xen kẽ trong ListView',
                                  onPressed: _showNativeAdsInListView,
                                  icon: Icons.list_alt,
                                ),
                                _buildAdButton(
                                  title: 'Quảng cáo Native theo chủ đề',
                                  onPressed: _showThemedNativeAdExample,
                                  icon: Icons.color_lens,
                                ),
                              ],
                            ),

                            _buildSection(
                              title: 'Quảng cáo App Open',
                              children: [
                                _buildAdButton(
                                  title: 'Hiển thị App Open Ad',
                                  onPressed: _showAppOpenAd,
                                  icon: Icons.open_in_new,
                                ),
                              ],
                            ),

                            _buildSection(
                              title: 'Điều khiển Quảng cáo',
                              children: [
                                _buildAdButton(
                                  title: 'Chuyển đổi Premium/Regular',
                                  onPressed: _togglePremiumUser,
                                  icon: Icons.star,
                                ),
                              ],
                            ),

                            // Các điều khiển chỉ hiển thị trong chế độ test
                            Obx(
                              () =>
                                  _isTestMode.value
                                      ? _buildSection(
                                        title: 'Công cụ Test',
                                        children: [
                                          _buildAdButton(
                                            title: 'Tăng số phiên người dùng',
                                            onPressed: _incrementUserSessions,
                                            icon: Icons.add_circle,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Chọn phân đoạn người dùng:',
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildUserSegmentButton(
                                                  segment: UserSegment.newbie,
                                                  icon: Icons.person_outline,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: _buildUserSegmentButton(
                                                  segment: UserSegment.normal,
                                                  icon: Icons.person,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildUserSegmentButton(
                                                  segment:
                                                      UserSegment.highValue,
                                                  icon: Icons.person_2,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: _buildUserSegmentButton(
                                                  segment: UserSegment.premium,
                                                  icon: Icons.person_2_outlined,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                      : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const Text('Banner Ad Example:'),
                      const SizedBox(height: 10),
                      const SmartBannerAd(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdButton({
    required String title,
    required VoidCallback onPressed,
    required IconData icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildUserSegmentButton({
    required UserSegment segment,
    required IconData icon,
  }) {
    final String label = segment.toString().split('.').last;

    return ElevatedButton.icon(
      onPressed: () => _changeUserSegment(segment),
      icon: Icon(icon, size: 16),
      label: Text(label.substring(0, 1).toUpperCase() + label.substring(1)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
