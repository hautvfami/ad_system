/// Defines the different types of ads available in the system.
enum AdType {
  /// No ad shown (for premium users or ad-free sessions)
  none,

  /// Standard banner ad displayed at the top or bottom of the screen
  banner,

  /// Native ad that matches the look and feel of the app
  native,

  /// Full-screen interstitial ad shown at natural breaks
  interstitial,

  /// Full-screen video ad that rewards users for watching
  rewarded,

  /// Full-screen ad shown when the app is opened
  appOpen
}
