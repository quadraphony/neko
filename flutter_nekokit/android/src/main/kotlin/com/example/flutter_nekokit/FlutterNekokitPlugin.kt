package com.example.flutter_nekokit

import android.content.ComponentName
import android.content.Context
import androidx.annotation.NonNull
import android.content.Intent
import android.content.ServiceConnection
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.util.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterNekokitPlugin */
class FlutterNekokitPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var applicationContext: Context
  private var vpnService: ISagerNetService? = null
  private var serviceConnection: ServiceConnection? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_nekokit")
    channel.setMethodCallHandler(this)
    bindVpnService()
  }

  private fun bindVpnService() {
      val intent = Intent(applicationContext, NekoVpnService::class.java)
      serviceConnection = object : ServiceConnection {
          override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
              vpnService = ISagerNetService.Stub.asInterface(service)
              Log.d("FlutterNekokitPlugin", "VPN Service Connected")
          }

          override fun onServiceDisconnected(name: ComponentName?) {
              vpnService = null
              Log.d("FlutterNekokitPlugin", "VPN Service Disconnected")
          }
      }
      applicationContext.bindService(intent, serviceConnection as ServiceConnection, Context.BIND_AUTO_CREATE)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (vpnService == null) {
        result.error("SERVICE_NOT_CONNECTED", "VPN Service not connected", null)
        return
    }

    when (call.method) {
      "initNekoBox" -> {
        // Initialization is handled by VpnService lifecycle
        result.success(null)
      }
      "startProxy" -> {
        val config = call.argument<String>("config")
        val enableKillSwitch = call.argument<Boolean>("enableKillSwitch") ?: false

        val vpnIntent = VpnService.prepare(applicationContext)
        if (vpnIntent != null) {
            result.error("VPN_PERMISSION_REQUIRED", "VPN permission is required", null)
            return
        }

        vpnService?.startVpn(config, enableKillSwitch)
        result.success(null)
      }
      "stopProxy" -> {
        vpnService?.stopVpn()
        result.success(null)
      }
      "getProxyStatus" -> {
        result.success(vpnService?.getVpnStatus())
      }
      "getConnectionStats" -> {
        result.success(vpnService?.getConnectionStats())
      }
      "getVersion" -> {
        result.success(vpnService?.getVersion())
      }
      "updateConfig" -> {
        val config = call.argument<String>("config")
        vpnService?.updateVpnConfig(config)
        result.success(null)
      }
      "enableKillSwitch" -> {
        vpnService?.enableKillSwitch()
        result.success(true)
      }
      "disableKillSwitch" -> {
        vpnService?.disableKillSwitch()
        result.success(true)
      }
      "isKillSwitchEnabled" -> {
        result.success(vpnService?.isKillSwitchEnabled())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    serviceConnection?.let { applicationContext.unbindService(it) }
    vpnService = null
    serviceConnection = null
  }
}
