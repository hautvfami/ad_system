package com.example.example

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
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

        // Set background to transparent by default
        nativeAdView.setBackgroundColor(android.graphics.Color.TRANSPARENT)

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

        // Get sponsored label to customize
        val sponsoredLabel = nativeAdView.findViewById<TextView>(R.id.ad_sponsored)
        
        // Apply additional customizations from options if provided
        customOptions?.let {
            // Apply background color (transparent by default)
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

            // Apply headline text styles
            if (it.containsKey("headlineTextColor")) {
                val textColor = it["headlineTextColor"] as? String
                textColor?.let { color ->
                    try {
                        headlineView.setTextColor(android.graphics.Color.parseColor(color))
                    } catch (e: IllegalArgumentException) {
                        // Invalid color format
                    }
                }
            }
            
            if (it.containsKey("headlineTextSize")) {
                val textSize = it["headlineTextSize"] as? Float
                textSize?.let { size ->
                    headlineView.textSize = size
                }
            }

            // Apply body text styles
            if (it.containsKey("bodyTextColor")) {
                val textColor = it["bodyTextColor"] as? String
                textColor?.let { color ->
                    try {
                        bodyView.setTextColor(android.graphics.Color.parseColor(color))
                    } catch (e: IllegalArgumentException) {
                        // Invalid color format
                    }
                }
            }
            
            if (it.containsKey("bodyTextSize")) {
                val textSize = it["bodyTextSize"] as? Float
                textSize?.let { size ->
                    bodyView.textSize = size
                }
            }

            // Apply button styles
            if (it.containsKey("buttonBackgroundColor")) {
                try {
                    val btnBgColor = it["buttonBackgroundColor"] as? String
                    if (btnBgColor != null) {
                        // Create new drawable with custom color
                        val gd = android.graphics.drawable.GradientDrawable()
                        gd.setColor(android.graphics.Color.parseColor(btnBgColor))
                        
                        // Use existing corner radius or default
                        val cornerRadius = it["buttonCornerRadius"] as? Float ?: 8f
                        gd.cornerRadius = cornerRadius
                        
                        callToActionView.background = gd
                    }
                } catch (e: IllegalArgumentException) {
                    // Invalid color format
                }
            }
            
            if (it.containsKey("buttonTextColor")) {
                try {
                    val btnTextColor = it["buttonTextColor"] as? String
                    if (btnTextColor != null) {
                        callToActionView.setTextColor(android.graphics.Color.parseColor(btnTextColor))
                    }
                } catch (e: IllegalArgumentException) {
                    // Invalid color format
                }
            }
            
            if (it.containsKey("buttonTextSize")) {
                val textSize = it["buttonTextSize"] as? Float
                textSize?.let { size ->
                    callToActionView.textSize = size
                }
            }
            
            // Customize sponsored label
            if (it.containsKey("sponsoredLabelColor")) {
                try {
                    val labelColor = it["sponsoredLabelColor"] as? String
                    if (labelColor != null) {
                        sponsoredLabel.setTextColor(android.graphics.Color.parseColor(labelColor))
                    }
                } catch (e: IllegalArgumentException) {
                    // Invalid color format
                }
            }
            
            if (it.containsKey("sponsoredLabelBackgroundColor")) {
                try {
                    val bgColor = it["sponsoredLabelBackgroundColor"] as? String
                    if (bgColor != null) {
                        sponsoredLabel.setBackgroundColor(android.graphics.Color.parseColor(bgColor))
                    }
                } catch (e: IllegalArgumentException) {
                    // Invalid color format
                }
            }
            
            // Add padding to main container if specified
            if (it.containsKey("padding")) {
                val padding = it["padding"] as? Int
                padding?.let { p ->
                    val mainContainer = nativeAdView.findViewById<LinearLayout>(android.R.id.content)
                    mainContainer?.setPadding(p, p, p, p)
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
