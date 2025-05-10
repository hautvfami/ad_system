# Theme-Aware Native Ads Integration

This guide explains how to use the theme-aware native ad features in the ad_system package, which allows native ads to adopt your Flutter app's theme styling for a more integrated look and feel.

## Overview

The theme-aware native ad integration allows:
- Transparent backgrounds so Flutter UI shows through
- Adoption of Flutter's text styling (colors, sizes)
- Consistent corner radius with Flutter UI elements
- Automatic light/dark mode adaptation

## Quick Usage Examples

### Using the SmartNativeAd widget (easiest)

```dart
SmartNativeAd(
  height: 280,
  useThemeAwareStyling: true, // Enable theme-aware styling
  placementName: 'my_native_ad',
  template: 'medium', // Options: small, medium, large
  borderRadius: 16,
  useGlassEffect: true, // Optional glass background effect
  fallbackContent: Center(child: Text('No ad available')),
)
```

### Using AdsManager extensions

```dart
// Load a native ad with theme styling
final ad = await AdsManager.instance.loadThemedNativeAd(
  context: context,
  placementName: 'themed_ad',
  template: 'medium',
  onAdLoaded: (ad) {
    // Ad loaded successfully
  },
);

// Display in a themed container
if (ad != null) {
  return AdsManager.instance.createThemedNativeAdContainer(
    context: context,
    nativeAd: ad,
    borderRadius: BorderRadius.circular(16),
  );
}
```

### Custom Theme Options

To override specific theme aspects:

```dart
// Create custom theme options
final customOptions = ThemeExtractor.createCustomNativeAdTheme(
  backgroundColor: Colors.transparent,
  headlineTextColor: Colors.blue,
  bodyTextColor: Colors.black87,
  buttonBackgroundColor: Colors.green,
  buttonTextColor: Colors.white,
  buttonCornerRadius: 8.0,
);

// Load ad with custom options
final ad = await AdsManager.instance.loadNativeAd(
  placementName: 'custom_themed_ad',
  template: 'medium',
  customOptions: customOptions,
);
```

## Theme Properties

These are the theme properties you can customize:

| Property | Description | Default |
|----------|-------------|---------|
| backgroundColor | Background color of native ad | Transparent |
| headlineTextColor | Color of the headline text | From theme |
| headlineTextSize | Size of headline text | From theme |
| bodyTextColor | Color of body text | From theme |
| bodyTextSize | Size of body text | From theme |
| buttonBackgroundColor | Background color of CTA button | Primary color |
| buttonTextColor | Text color of CTA button | On primary color |
| buttonTextSize | Size of button text | From theme |
| buttonCornerRadius | Corner radius of button | 8.0 |
| containerCornerRadius | Corner radius of ad container | 12.0 |
| sponsoredLabelColor | Color of "Sponsored" label | From theme |
| sponsoredLabelBackgroundColor | Background of "Sponsored" badge | From theme |
| mediaCornerRadius | Corner radius of media content | 8.0 |

## Implementation Details

The theme integration works by:

1. Extracting theme properties from your Flutter app's current theme
2. Converting these properties to format native platforms can understand
3. Passing these styles via the `customOptions` parameter to native ad factories
4. Applying styles to native elements on both Android and iOS

Both Android and iOS platforms have customized native ad factories that know how to interpret
these style properties and apply them to the native ad elements.

## Handling Theme Changes

The SmartNativeAd widget automatically reloads when the theme changes. If you're manually managing 
ads, you should reload them when the theme changes by monitoring:

```dart
didChangeDependencies() {
  super.didChangeDependencies();
  // Check if theme changed and reload ads if needed
}
```
