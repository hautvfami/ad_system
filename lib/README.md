# Hệ thống quảng cáo (Ad System)

Hệ thống quảng cáo được thiết kế để tối ưu hóa doanh thu quảng cáo trong khi vẫn duy trì trải nghiệm người dùng tốt nhất. Module này có thể dễ dàng tích hợp vào ứng dụng Flutter và cung cấp các công cụ để quản lý quảng cáo một cách thông minh.

## Cấu trúc thư mục

```
lib/ad_system/
├── ads_manager.dart           # Facade chính cho hệ thống quảng cáo
├── ads_manual.md              # Tài liệu hướng dẫn chi tiết và chiến lược
├── controllers/
│   └── ad_controller.dart     # Quản lý trạng thái và quyết định hiển thị quảng cáo
├── models/
│   ├── ad_types.dart          # Định nghĩa các loại quảng cáo
│   └── user_segment.dart      # Phân nhóm người dùng
├── services/
│   ├── ad_service.dart        # Tương tác với SDK quảng cáo
│   └── analytics_service.dart # Theo dõi sự kiện quảng cáo
├── utils/
│   └── ad_colors.dart         # Hằng số màu sắc cho UI quảng cáo
├── widgets/
│   ├── ad_skeleton_loader.dart # Skeleton loader cho quảng cáo đang tải
│   ├── glass_ad_panel.dart    # Container với hiệu ứng kính
│   ├── rewarded_ad_button.dart # Nút hiển thị quảng cáo có thưởng
│   ├── smart_banner_ad.dart   # Widget banner thông minh
│   └── smart_native_ad.dart   # Widget native ad thông minh
```

## Cách sử dụng

### 1. Khởi tạo

Khởi tạo hệ thống quảng cáo trong `main.dart` hoặc khi bootstrap ứng dụng:

```dart
await AdsManager.instance.initialize();
```

### 2. Hiển thị banner ad

```dart
// Trong widget tree
SmartBannerAd(
  useGlassEffect: true,
  fallbackContent: YourCustomWidget(),
)
```

### 3. Hiển thị native ad

```dart
// Trong widget tree
SmartNativeAd(
  height: 280,
  useGlassEffect: true,
  loadingWidget: AdSkeletonLoader(height: 280),
)
```

### 4. Hiển thị interstitial ad

```dart
// Khi hoàn thành một hành động lớn
final bool shown = await AdsManager.instance.showInterstitialAd();
// Tiếp tục logic của bạn bất kể quảng cáo có hiển thị hay không
```

### 5. Hiển thị rewarded ad

#### Cách 1: Sử dụng widget RewardedAdButton

```dart
RewardedAdButton(
  label: 'Xem quảng cáo',
  rewardAmount: 50,
  rewardType: 'xu',
  onRewardEarned: (amount, type) {
    // Xử lý khi người dùng nhận thưởng
    userCoins.value += amount;
    Get.snackbar('Thành công', 'Bạn đã nhận được $amount $type');
  },
)
```

#### Cách 2: Gọi trực tiếp

```dart
AdsManager.instance.showRewardedAd(
  onRewarded: (type, amount) {
    // Xử lý khi người dùng nhận thưởng
    userCoins.value += amount;
  },
);
```

### 6. Xử lý người dùng premium

Để tắt quảng cáo cho người dùng premium:

```dart
AdsManager.instance.setPremiumUser(true);
```

Để tạo phiên không có quảng cáo (ví dụ: sau khi mua hàng):

```dart
AdsManager.instance.setAdFreeSession(true);
```

## Cài đặt phụ thuộc

Thêm các phụ thuộc sau vào `pubspec.yaml`:

```yaml
dependencies:
  google_mobile_ads: ^4.0.0  # Hoặc phiên bản mới nhất
  get: ^4.6.5               # Cho state management
  shimmer: ^3.0.0           # Cho skeleton loading effect
```

## A/B Testing

Hệ thống hỗ trợ A/B testing thông qua nhóm người dùng:

```dart
// Đặt nhóm A/B cho người dùng
AdsManager.instance.setAbTestGroup('A');

// Cập nhật cài đặt cho nhóm
AdsManager.instance.updateAdSettings(
  maxInterstitialPerSession: 2,
  minSecondsBetweenInterstitials: 180, // 3 phút
);
```

## Nâng cao: Tùy chỉnh thiết kế quảng cáo

### Sử dụng Glass Effect Container

```dart
GlassAdPanel(
  borderRadius: 20,
  blurIntensity: 16,
  opacity: 0.1,
  child: YourContent(),
)
```

### Sử dụng Skeleton Loader

```dart
AdSkeletonLoader(
  height: 280,
  borderRadius: 20,
  baseColor: Colors.grey.shade300,
  highlightColor: Colors.white,
)
```

## Tài liệu liên quan

Để biết thêm thông tin chi tiết về chiến lược tối ưu hóa quảng cáo, xem file [ads_manual.md](ads_manual.md).

## Đóng góp

Nếu bạn phát hiện lỗi hoặc có đề xuất cải tiến, vui lòng tạo issue hoặc pull request.
