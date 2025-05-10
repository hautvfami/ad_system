import GoogleMobileAds
import Flutter

class SmallNativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        // Create and place ad in view hierarchy
        let nibView = Bundle.main.loadNibNamed("SmallNativeAdView", owner: nil, options: nil)!.first
        let nativeAdView = nibView as! GADNativeAdView

        // Set the ad headline
        (nativeAdView.headlineView as! UILabel).text = nativeAd.headline
        
        // Add the ad icon
        if let icon = nativeAd.icon?.image {
            (nativeAdView.iconView as! UIImageView).image = icon
            nativeAdView.iconView!.isHidden = false
        } else {
            nativeAdView.iconView!.isHidden = true
        }
        
        // Show call to action
        (nativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView!.isUserInteractionEnabled = false
        
        // Finalize native ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
}
