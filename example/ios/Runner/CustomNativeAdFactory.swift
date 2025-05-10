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
        
        // Make background transparent by default
        let containerView = nativeAdView.subviews.first
        containerView?.backgroundColor = .clear
        
        // Apply any custom styling from options
        if let customOptions = customOptions {
            // Background
            if let backgroundColor = customOptions["backgroundColor"] as? String {
                // Apply custom background color
                containerView?.backgroundColor = colorFromHexString(backgroundColor)
            }
            
            // Headline styling
            let headlineLabel = nativeAdView.headlineView as! UILabel
            if let headlineTextColor = customOptions["headlineTextColor"] as? String {
                headlineLabel.textColor = colorFromHexString(headlineTextColor)
            }
            if let headlineTextSize = customOptions["headlineTextSize"] as? CGFloat {
                headlineLabel.font = .systemFont(ofSize: headlineTextSize, weight: .bold)
            }
            
            // Body styling
            let bodyLabel = nativeAdView.bodyView as! UILabel
            if let bodyTextColor = customOptions["bodyTextColor"] as? String {
                bodyLabel.textColor = colorFromHexString(bodyTextColor)
            }
            if let bodyTextSize = customOptions["bodyTextSize"] as? CGFloat {
                bodyLabel.font = .systemFont(ofSize: bodyTextSize)
            }
            
            // Button styling
            let actionButton = nativeAdView.callToActionView as! UIButton
            if let buttonBackgroundColor = customOptions["buttonBackgroundColor"] as? String {
                actionButton.backgroundColor = colorFromHexString(buttonBackgroundColor)
            }
            if let buttonTextColor = customOptions["buttonTextColor"] as? String {
                actionButton.setTitleColor(colorFromHexString(buttonTextColor), for: .normal)
            }
            if let buttonTextSize = customOptions["buttonTextSize"] as? CGFloat {
                actionButton.titleLabel?.font = .systemFont(ofSize: buttonTextSize, weight: .medium)
            }
            if let buttonCornerRadius = customOptions["buttonCornerRadius"] as? CGFloat {
                actionButton.layer.cornerRadius = buttonCornerRadius
                actionButton.clipsToBounds = true
            } else {
                // Default corner radius
                actionButton.layer.cornerRadius = 8.0
                actionButton.clipsToBounds = true
            }
            
            // Sponsored label customization
            if let sponsoredLabel = nativeAdView.viewWithTag(100) as? UILabel {
                if let sponsoredTextColor = customOptions["sponsoredLabelColor"] as? String {
                    sponsoredLabel.textColor = colorFromHexString(sponsoredTextColor)
                }
                if let sponsoredBgColor = customOptions["sponsoredLabelBackgroundColor"] as? String {
                    sponsoredLabel.backgroundColor = colorFromHexString(sponsoredBgColor)
                }
            }
            
            // Media view corner radius
            if let mediaCornerRadius = customOptions["mediaCornerRadius"] as? CGFloat {
                nativeAdView.mediaView?.layer.cornerRadius = mediaCornerRadius
                nativeAdView.mediaView?.clipsToBounds = true
            }
            
            // Overall corner radius
            if let containerCornerRadius = customOptions["containerCornerRadius"] as? CGFloat {
                containerView?.layer.cornerRadius = containerCornerRadius
                containerView?.clipsToBounds = true
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
