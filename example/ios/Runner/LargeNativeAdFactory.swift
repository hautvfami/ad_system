import GoogleMobileAds
import Flutter

class LargeNativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        // Create and place ad in view hierarchy
        let nibView = Bundle.main.loadNibNamed("LargeNativeAdView", owner: nil, options: nil)!.first
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
        
        // Add the advertiser name
        if let advertiser = nativeAd.advertiser {
            (nativeAdView.advertiserView as! UILabel).text = advertiser
            nativeAdView.advertiserView!.isHidden = false
        } else {
            nativeAdView.advertiserView?.isHidden = true
        }
        
        // Add the ad icon
        if let icon = nativeAd.icon?.image {
            (nativeAdView.iconView as! UIImageView).image = icon
            nativeAdView.iconView!.isHidden = false
        } else {
            nativeAdView.iconView!.isHidden = true
        }
        
        // Add price info
        if let price = nativeAd.price {
            (nativeAdView.priceView as! UILabel).text = price
            nativeAdView.priceView!.isHidden = false
        } else {
            nativeAdView.priceView?.isHidden = true
        }
        
        // Add store information
        if let store = nativeAd.store {
            (nativeAdView.storeView as! UILabel).text = store
            nativeAdView.storeView!.isHidden = false
        } else {
            nativeAdView.storeView?.isHidden = true
        }
        
        // Add star rating
        if let starRating = nativeAd.starRating {
            (nativeAdView.starRatingView as! UIImageView).isHidden = false
            // Set star rating image based on the rating value
            let starRatingValue = starRating.doubleValue
            if starRatingValue >= 5.0 {
                (nativeAdView.starRatingView as! UIImageView).image = UIImage(named: "stars_5")
            } else if starRatingValue >= 4.5 {
                (nativeAdView.starRatingView as! UIImageView).image = UIImage(named: "stars_4.5")
            } else if starRatingValue >= 4.0 {
                (nativeAdView.starRatingView as! UIImageView).image = UIImage(named: "stars_4")
            } else if starRatingValue >= 3.5 {
                (nativeAdView.starRatingView as! UIImageView).image = UIImage(named: "stars_3.5")
            } else {
                (nativeAdView.starRatingView as! UIImageView).image = UIImage(named: "stars_3")
            }
        } else {
            nativeAdView.starRatingView?.isHidden = true
        }
        
        // Add media view
        if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            mediaView.mediaContent = nativeAd.mediaContent
        }
        
        // Show call to action
        (nativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView!.isUserInteractionEnabled = false
        
        // Finalize native ad
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
}
