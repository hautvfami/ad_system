package com.example.example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import java.util.Map

class SmallNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.small_native_ad, null) as NativeAdView

        if(nativeAd == null) {
            return nativeAdView
        }
        // Set up the headline
        val headlineView = nativeAdView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        nativeAdView.headlineView = headlineView

        // Set up the call to action
        val callToActionView = nativeAdView.findViewById<Button>(R.id.ad_call_to_action)
        callToActionView.text = nativeAd.callToAction
        nativeAdView.callToActionView = callToActionView

        // Set up the icon
        val iconView = nativeAdView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon!!.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        nativeAdView.iconView = iconView

        // This registers the view that will track clicks and impressions
        nativeAdView.setNativeAd(nativeAd)

        return nativeAdView
    }
}
