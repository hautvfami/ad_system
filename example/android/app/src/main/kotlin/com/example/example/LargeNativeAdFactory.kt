package com.example.example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import java.util.Map

class LargeNativeAdFactory(private val context: Context) : NativeAdFactory {
    /**
     * Creates a custom native ad view.
     *
     * @param nativeAd The native ad to be displayed.
     * @param customOptions Additional options for customization.
     * @return A [NativeAdView] that displays the native ad.
     */
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.large_native_ad, null) as NativeAdView

        // Set up the headline
        val headlineView = nativeAdView.findViewById<TextView>(R.id.ad_headline)
        if (nativeAd != null) {
            headlineView.text = nativeAd.headline
        }
        nativeAdView.headlineView = headlineView

        // Set up the body
        val bodyView = nativeAdView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd != null) {
            bodyView.text = nativeAd.body
        }
        nativeAdView.bodyView = bodyView

        // Set up the call to action
        val callToActionView = nativeAdView.findViewById<Button>(R.id.ad_call_to_action)
        if (nativeAd != null) {
            callToActionView.text = nativeAd.callToAction
        }
        nativeAdView.callToActionView = callToActionView

        // Set up the media view
        val mediaView = nativeAdView.findViewById<MediaView>(R.id.ad_media)
        nativeAdView.mediaView = mediaView

        // Set up the icon
        val iconView = nativeAdView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd != null) {
            if (nativeAd.icon != null) {
                iconView.setImageDrawable(nativeAd.icon!!.drawable)
                iconView.visibility = View.VISIBLE
            } else {
                iconView.visibility = View.GONE
            }
        }
        nativeAdView.iconView = iconView

        // Set up the star rating
        val starRatingView = nativeAdView.findViewById<RatingBar>(R.id.ad_stars)
        if (nativeAd != null) {
            if (nativeAd.starRating != null) {
                starRatingView.rating = nativeAd.starRating!!.toFloat()
                starRatingView.visibility = View.VISIBLE
            } else {
                starRatingView.visibility = View.GONE
            }
        }
        nativeAdView.starRatingView = starRatingView

        // Set up price
        val priceView = nativeAdView.findViewById<TextView>(R.id.ad_price)
        if (nativeAd != null) {
            if (nativeAd.price != null) {
                priceView.text = nativeAd.price
                priceView.visibility = View.VISIBLE
            } else {
                priceView.visibility = View.GONE
            }
        }
        nativeAdView.priceView = priceView

        // Set up store
        val storeView = nativeAdView.findViewById<TextView>(R.id.ad_store)
        if (nativeAd?.store != null) {
            storeView.text = nativeAd.store
            storeView.visibility = View.VISIBLE
        } else {
            storeView.visibility = View.GONE
        }
        nativeAdView.storeView = storeView

        // Set up advertiser
        val advertiserView = nativeAdView.findViewById<TextView>(R.id.ad_advertiser)
        if (nativeAd != null) {
            if (nativeAd.advertiser != null) {
                advertiserView.text = nativeAd.advertiser
                advertiserView.visibility = View.VISIBLE
            } else {
                advertiserView.visibility = View.GONE
            }
        }
        nativeAdView.advertiserView = advertiserView

        // This registers the view that will track clicks and impressions
        if (nativeAd != null) {
            nativeAdView.setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}
