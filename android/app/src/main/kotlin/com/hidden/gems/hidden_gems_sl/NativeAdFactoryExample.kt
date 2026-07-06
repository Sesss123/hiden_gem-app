package com.hidden.gems.hidden_gems_sl

import android.view.LayoutInflater
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

class NativeAdFactoryExample(private val layoutInflater: LayoutInflater) : NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.native_ad_layout, null) as NativeAdView
        
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        bodyView.text = nativeAd.body
        adView.bodyView = bodyView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
