package com.example.flutter_nekokit

import android.content.Context
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// IMPORTANT: You will need to manually integrate the NekoBoxForAndroid's sing-box core (libcore)
// by compiling it into an AAR and adding it as a dependency in your build.gradle.
// The following imports are placeholders and assume the NativeInterface exists in the compiled AAR.
// Example: import moe.matsuri.nb4a.NativeInterface
// Example: import moe.matsuri.nb4a.SingBoxOptions

/** FlutterNekokitPlugin */
class FlutterNekokitPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_nekokit")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initNekoBox" -> {
        // Placeholder: Call the actual NekoBox/sing-box initialization method here.
        // This assumes a method like `NativeInterface.init(applicationContext)` exists
        // in the integrated NekoBoxForAndroid core AAR.
        // NativeInterface.init(applicationContext)
        result.success(null)
      }
      "startProxy" -> {
        val config = call.argument<String>("config")
        // Placeholder: Call the actual NekoBox/sing-box start method with the config.
        // This assumes a method like `NativeInterface.start(config)` exists.
        // if (config != null) {
        //   NativeInterface.start(config)
        // }
        result.success(null)
      }
      "stopProxy" -> {
        // Placeholder: Call the actual NekoBox/sing-box stop method.
        // NativeInterface.stop()
        result.success(null)
      }
      "getProxyStatus" -> {
        // Placeholder: Call the actual NekoBox/sing-box status method.
        // result.success(NativeInterface.getStatus())
        result.success("Android: Proxy status not implemented (requires NekoBox core integration)")
      }
      "getConnectionStats" -> {
        // Placeholder: Call the actual NekoBox/sing-box connection stats method.
        // result.success(NativeInterface.getStats())
        result.success("Android: Connection stats not implemented (requires NekoBox core integration)")
      }
      "getVersion" -> {
        // Placeholder: Call the actual NekoBox/sing-box version method.
        // result.success(NativeInterface.getVersion())
        result.success("Android: Version not implemented (requires NekoBox core integration)")
      }
      "updateConfig" -> {
        val config = call.argument<String>("config")
        // Placeholder: Call the actual NekoBox/sing-box update config method.
        // if (config != null) {
        //   NativeInterface.updateConfig(config)
        // }
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}


