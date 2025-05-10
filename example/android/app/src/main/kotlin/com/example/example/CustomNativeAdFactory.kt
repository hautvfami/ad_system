package com.example.example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class CustomNativeAdFactory(private val context: Context) : NativeAdFactory {
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
            .inflate(R.layout.custom_native_ad, null) as NativeAdView

        // Set up the headline
        val headlineView = nativeAdView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd?.headline
        nativeAdView.headlineView = headlineView

        // Set up the body
        val bodyView = nativeAdView.findViewById<TextView>(R.id.ad_body)
        bodyView.text = nativeAd?.body
        nativeAdView.bodyView = bodyView

        // Set up the call to action
        val callToActionView = nativeAdView.findViewById<Button>(R.id.ad_call_to_action)
        callToActionView.text = nativeAd?.callToAction
        nativeAdView.callToActionView = callToActionView

        // Set up media view
        val mediaView = nativeAdView.findViewById<MediaView>(R.id.ad_media)
        nativeAdView.mediaView = mediaView

        // Set up the icon
        val iconView = nativeAdView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd?.icon != null) {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        nativeAdView.iconView = iconView

        // Apply additional customizations from options if provided
        customOptions?.let {
            if (it.containsKey("backgroundColor")) {
                val backgroundColor = it["backgroundColor"] as? String
                backgroundColor?.let { color ->
                    try {
                        nativeAdView.setBackgroundColor(android.graphics.Color.parseColor(color))
                    } catch (e: IllegalArgumentException) {
                        // Invalid color format
                    }
                }
            }
        }

        // This registers the view that will track clicks and impressions
        nativeAd?.let { 
            nativeAdView.setNativeAd(it)
        }

        return nativeAdView
    }
}
