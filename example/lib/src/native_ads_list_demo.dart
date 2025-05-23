import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ad_system/ad_system.dart';
import 'package:get/get.dart';

/// Một lớp demo để hiển thị cách hiển thị quảng cáo native xen kẽ trong một ListView
class NativeAdsListViewDemo extends StatefulWidget {
  const NativeAdsListViewDemo({Key? key}) : super(key: key);

  @override
  State<NativeAdsListViewDemo> createState() => _NativeAdsListViewDemoState();
}

class _NativeAdsListViewDemoState extends State<NativeAdsListViewDemo> {
  // Danh sách các mục dữ liệu (có thể là bài viết, tin tức, sản phẩm, v.v.)
  final List<String> _items = List.generate(30, (index) => 'Mục số $index');

  // Danh sách ads đã được tải
  final Map<int, NativeAd> _loadedAds = {};

  // Lưu thông tin kích thước cho mỗi quảng cáo
  final Map<int, double> _adHeights = {};

  // Danh sách các template có sẵn
  final List<String> _availableTemplates = ['small', 'medium', 'large'];

  // Template hiện tại đang được sử dụng
  final Rx<String> _currentTemplate = 'medium'.obs;

  // Vị trí các quảng cáo trong danh sách (cứ mỗi 5 mục sẽ có 1 quảng cáo)
  final int _adInterval = 5;

  // Đang tải quảng cáo
  final _isLoading = false.obs;

  // Kết quả gần nhất
  final _lastResult = ''.obs;

  @override
  void initState() {
    super.initState();
    // Tải trước một số quảng cáo
    _preloadAds();
  }

  @override
  void dispose() {
    // Giải phóng quảng cáo khi không còn sử dụng
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    super.dispose();
  }

  // Best practice: Tải trước một số quảng cáo để sẵn sàng hiển thị
  void _preloadAds() {
    _isLoading.value = true;

    // Tính toán có bao nhiêu quảng cáo cần tải
    int totalAdsNeeded = (_items.length / _adInterval).floor();

    // Giới hạn số lượng quảng cáo tải trước (để tiết kiệm tài nguyên)
    int preloadCount = totalAdsNeeded > 3 ? 3 : totalAdsNeeded;

    _lastResult.value = 'Đang tải trước $preloadCount quảng cáo...';

    // Tải trước các quảng cáo
    for (int i = 0; i < preloadCount; i++) {
      _loadAd(i);
    }

    _isLoading.value = false;
  }

  // Tải một quảng cáo cho vị trí nhất định trong ListView.builder
  void _loadAd(int adIndex) {
    // Chuyển đổi adIndex thành vị trí hiển thị thực tế trong ListView
    final int listViewIndex = _getListViewIndexFromAdIndex(adIndex);

    debugPrint(
      'Đang tải quảng cáo cho adIndex=$adIndex, vị trí trong ListView: $listViewIndex',
    );

    if (_loadedAds.containsKey(listViewIndex)) {
      debugPrint('Quảng cáo cho vị trí $listViewIndex đã được tải rồi!');
      return; // Đã tải quảng cáo này rồi
    }

    // Thêm phần debug để xem trạng thái hiện tại của map
    _debugAdsStatus();

    AdsManager.instance.loadNativeAd(
      placementName: 'list_native_$adIndex',
      template: _currentTemplate.value,
      onAdLoaded: (ad) {
        debugPrint(
          '✅ Quảng cáo cho vị trí ListView $listViewIndex (adIndex=$adIndex) đã tải THÀNH CÔNG',
        );
        // Lưu quảng cáo với key chính là vị trí trong ListView
        _loadedAds[listViewIndex] = ad;
        _lastResult.value = 'Đã tải quảng cáo cho vị trí $listViewIndex';

        // Hiển thị thông tin debug
        _debugAdsStatus();

        setState(() {}); // Cập nhật UI
      },
      onAdFailedToLoad: (error) {
        debugPrint('❌ Lỗi tải quảng cáo cho vị trí $listViewIndex: $error');
        _lastResult.value = 'Lỗi tải quảng cáo ở vị trí $listViewIndex: $error';
      },
    );
  }

  // Debug: Kiểm tra trạng thái của tất cả quảng cáo đã tải
  void _debugAdsStatus() {
    debugPrint('\n==== DEBUG ADS STATUS ====');
    debugPrint('Tổng số quảng cáo đã tải: ${_loadedAds.length}');
    _loadedAds.forEach((position, ad) {
      debugPrint('Quảng cáo tại vị trí $position: ${ad.responseInfo}');
    });
    debugPrint('========================\n');
  }

  // Kiểm tra xem một vị trí có phải là vị trí quảng cáo không
  bool _isAdPosition(int index) {
    // Cứ mỗi _adInterval mục sẽ có 1 quảng cáo
    // Ví dụ: với _adInterval = 5, vị trí 5, 11, 17, 23 ... sẽ là quảng cáo
    bool isAd = index > 0 && index % (_adInterval + 1) == _adInterval;
    if (isAd) {
      debugPrint('🔍 Vị trí $index là vị trí quảng cáo');
    }
    return isAd;
  }

  // Tính toán vị trí thực của mục dữ liệu, không tính quảng cáo
  int _getItemIndex(int position) {
    // Số lượng quảng cáo trước vị trí hiện tại
    int adCountBeforePosition = (position / (_adInterval + 1)).floor();
    // Vị trí thực trong danh sách gốc
    return position - adCountBeforePosition;
  }

  // Tổng số mục hiển thị (bao gồm cả nội dung và quảng cáo)
  int get _totalItems {
    // Số lượng quảng cáo sẽ hiển thị
    int adCount = (_items.length / _adInterval).floor();
    // Tổng số mục = số lượng nội dung + số lượng quảng cáo
    int total = _items.length + adCount;
    debugPrint(
      'Tổng số mục: $total (${_items.length} nội dung + $adCount quảng cáo)',
    );
    return total;
  }

  // Chuyển đổi từ adIndex sang vị trí thực trong ListView
  int _getListViewIndexFromAdIndex(int adIndex) {
    return (adIndex + 1) * (_adInterval + 1) - 1;
  }

  // Lấy adIndex từ vị trí ListView
  int _getAdIndexFromListViewIndex(int listViewIndex) {
    return listViewIndex ~/ (_adInterval + 1);
  }

  // Lấy chiều cao phù hợp cho quảng cáo dựa trên template
  double _getAdHeight(String template) {
    switch (template) {
      case 'small':
        return 120.0;
      case 'large':
        return 280.0;
      case 'medium':
      default:
        return 200.0;
    }
  }

  // Chọn template quảng cáo khác
  void _changeAdTemplate(String template) {
    if (_currentTemplate.value != template) {
      _currentTemplate.value = template;

      // Reload quảng cáo với template mới
      _reloadVisibleAds();

      _lastResult.value = 'Đã đổi template quảng cáo sang "$template"';
    }
  }

  // Tải lại quảng cáo hiện đang hiển thị
  void _reloadVisibleAds() {
    debugPrint(
      'Đang tải lại quảng cáo với template ${_currentTemplate.value}...',
    );
    _isLoading.value = true;

    // Xóa quảng cáo đã tải
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    _loadedAds.clear();
    _adHeights.clear(); // Xóa thông tin chiều cao cũ

    // Tải lại quảng cáo
    _preloadAds();

    // Hiện thông báo
    _lastResult.value =
        'Đã tải lại quảng cáo với kích thước "${_currentTemplate.value}"';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Ads trong ListView'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug quảng cáo',
            onPressed: () {
              _debugAdsStatus();
              _reloadVisibleAds();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hiển thị trạng thái
          Obx(
            () => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _isLoading.value
                          ? 'Đang tải quảng cáo...'
                          : 'Kết quả: ${_lastResult.value}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    if (_loadedAds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          children: [
                            Text(
                              'Đã tải ${_loadedAds.length} quảng cáo ở vị trí: ${_loadedAds.keys.join(", ")}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Thêm chọn template để thay đổi kích thước quảng cáo
                            Text(
                              'Chọn kích thước quảng cáo:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Template selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ..._availableTemplates
                                    .map(
                                      (template) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: FilterChip(
                                          label: Text(template.toUpperCase()),
                                          selected:
                                              _currentTemplate.value ==
                                              template,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _changeAdTemplate(template);
                                            }
                                          },
                                          labelStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                _currentTemplate.value ==
                                                        template
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),

                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Tải lại tất cả quảng cáo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              onPressed: _reloadVisibleAds,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Danh sách với quảng cáo xen kẽ
          Expanded(
            child: ListView.builder(
              itemCount: _totalItems,
              itemBuilder: (context, index) {
                // Kiểm tra xem vị trí này có phải là vị trí quảng cáo
                if (_isAdPosition(index)) {
                  debugPrint('Đang hiển thị vị trí quảng cáo $index');
                  // Kiểm tra xem quảng cáo đã được tải chưa
                  // Hiển thị debug info về quảng cáo đã tải
                  debugPrint(
                    'Kiểm tra quảng cáo cho vị trí $index. Ads đã tải: ${_loadedAds.keys.toList()}',
                  );

                  if (_loadedAds.containsKey(index)) {
                    debugPrint(
                      'Đã tìm thấy quảng cáo đã tải cho vị trí $index!',
                    );
                    // Hiển thị quảng cáo đã được tải với kích thước phù hợp với template
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      clipBehavior:
                          Clip.antiAlias, // Cắt nội dung theo hình dạng của card
                      child: Container(
                        height: _getAdHeight(_currentTemplate.value),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          // Thêm gradient nhẹ để tạo hiệu ứng hài hòa với UI
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.92),
                            ],
                          ),
                        ),
                        child: AdWidget(ad: _loadedAds[index]!),
                      ),
                    );
                  } else {
                    // Tải quảng cáo cho vị trí này nếu chưa được tải
                    // Tính vị trí quảng cáo dựa trên thứ tự đúng
                    int adIndex = _getAdIndexFromListViewIndex(index);
                    debugPrint(
                      'Chưa tìm thấy quảng cáo cho vị trí $index. Tính adIndex: $adIndex',
                    );
                    _loadAd(adIndex);

                    // Hiển thị placeholder với kích thước phù hợp với template
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        height: _getAdHeight(_currentTemplate.value),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.grey.shade100, Colors.grey.shade50],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(height: 8),
                            Text(
                              'Đang tải quảng cáo ${_currentTemplate.value} cho vị trí $index...',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Thử lại'),
                              style: TextButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                int adIndex = _getAdIndexFromListViewIndex(
                                  index,
                                );
                                debugPrint(
                                  'Thử tải lại quảng cáo cho adIndex: $adIndex, vị trí: $index',
                                );
                                _loadAd(adIndex);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                // Lấy vị trí thực trong danh sách dữ liệu gốc
                final itemIndex = _getItemIndex(index);

                // Hiển thị mục nội dung
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text('${itemIndex + 1}'),
                    ),
                    title: Text(_items[itemIndex]),
                    subtitle: Text('Đây là mô tả cho mục ${itemIndex + 1}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
