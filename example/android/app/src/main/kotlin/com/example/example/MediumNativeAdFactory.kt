package com.example.example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import java.util.Map

class MediumNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.medium_native_ad, null) as NativeAdView

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

        // This registers the view that will track clicks and impressions
        if (nativeAd != null) {
            nativeAdView.setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}
