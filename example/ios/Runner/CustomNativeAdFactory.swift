import GoogleMobileAds
import Flutter

class CustomNativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        // Create and place ad in view hierarchy
        let nibView = Bundle.main.loadNibNamed("CustomNativeAdView", owner: nil, options: nil)!.first
        let nativeAdView = nibView as! GADNativeAdView
        
        // Set the ad headline
        (nativeAdView.headlineView as! UILabel).text = nativeAd.headline
        
        // Set the ad body
        if let body = nativeAd.body {
            (nativeAdView.bodyView as! UILabel).text = body
            nativeAdView.bodyView!.isHidden = false
        } else {
            nativeAdView.bodyView!.isHidden = true
        }
        
        // Add the ad icon
        if let icon = nativeAd.icon?.image {
            (nativeAdView.iconView as! UIImageView).image = icon
            nativeAdView.iconView!.isHidden = false
        } else {
            nativeAdView.iconView!.isHidden = true
        }
        
        // Add media view
        if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            mediaView.mediaContent = nativeAd.mediaContent
        }
        
        // Show call to action
        (nativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView!.isUserInteractionEnabled = false
        
        // Apply any custom styling from options
        if let customOptions = customOptions {
            if let backgroundColor = customOptions["backgroundColor"] as? String {
                // Apply custom background color
                let containerView = nativeAdView.subviews.first
                containerView?.backgroundColor = colorFromHexString(backgroundColor)
            }
            
            if let textColor = customOptions["textColor"] as? String {
                // Apply custom text color to headline and body
                (nativeAdView.headlineView as! UILabel).textColor = colorFromHexString(textColor)
                (nativeAdView.bodyView as! UILabel).textColor = colorFromHexString(textColor)
            }
            
            if let buttonColor = customOptions["buttonColor"] as? String {
                // Apply custom button color
                (nativeAdView.callToActionView as! UIButton).backgroundColor = colorFromHexString(buttonColor)
            }
        }
        
        // Finalize native ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
    
    // Helper function to convert hex string to UIColor
    private func colorFromHexString(_ hexString: String) -> UIColor {
        var colorString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if colorString.hasPrefix("#") {
            colorString.remove(at: colorString.startIndex)
        }
        
        if colorString.count != 6 {
            return .clear
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: colorString).scanHexInt64(&rgbValue)
        
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                       blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                       alpha: 1.0)
    }
}
