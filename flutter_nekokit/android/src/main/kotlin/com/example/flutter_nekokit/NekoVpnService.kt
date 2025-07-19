package com.example.flutter_nekokit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import moe.matsuri.nb4a.NativeInterface
import libcore.Libcore

class NekoVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null
    private var currentConfig: String? = null

    companion object {
        private const val TAG = "NekoVpnService"
        var isRunning = false
        var killSwitchEnabled = false
        var vpnStatus = "disconnected"
        var connectionStats = "{\"upload\": 0, \"download\": 0}"
        var coreVersion = "Unknown"

        const val NOTIFICATION_CHANNEL_ID = "nekobox_vpn_service"
        const val NOTIFICATION_ID = 1
    }

    private val binder = object : ISagerNetService.Stub() {
        override fun startVpn(config: String?, enableKillSwitch: Boolean) {
            this@NekoVpnService.currentConfig = config
            this@NekoVpnService.killSwitchEnabled = enableKillSwitch
            this@NekoVpnService.startVpn(config)
        }

        override fun stopVpn() {
            this@NekoVpnService.stopVpn()
        }

        override fun getVpnStatus(): String {
            return vpnStatus
        }

        override fun getConnectionStats(): String {
            // In a real implementation, you'd get this from libcore.aar
            return connectionStats
        }

        override fun getVersion(): String {
            // In a real implementation, you'd get this from libcore.aar
            return coreVersion
        }

        override fun updateVpnConfig(config: String?) {
            this@NekoVpnService.currentConfig = config
            // In a real implementation, you'd call libcore.Libcore.updateConfig(config)
            Log.d(TAG, "Updating VPN config: $config")
        }

        override fun enableKillSwitch() {
            this@NekoVpnService.killSwitchEnabled = true
            Log.d(TAG, "Kill switch enabled via AIDL: ${this@NekoVpnService.killSwitchEnabled}")
            // Reconfigure VPN if running to apply kill switch rules
            // This might involve restarting the VPN or updating its configuration
        }

        override fun disableKillSwitch() {
            this@NekoVpnService.killSwitchEnabled = false
            Log.d(TAG, "Kill switch disabled via AIDL: ${this@NekoVpnService.killSwitchEnabled}")
            // Reconfigure VPN if running to remove kill switch rules
        }

        override fun isKillSwitchEnabled(): Boolean {
            return this@NekoVpnService.killSwitchEnabled
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "NekoVpnService started")
        isRunning = true

        when (intent?.action) {
            "start" -> {
                val config = intent.getStringExtra("config")
                val enableKillSwitch = intent.getBooleanExtra("enableKillSwitch", false)
                this.currentConfig = config
                this.killSwitchEnabled = enableKillSwitch
                startVpn(config)
            }
            "stop" -> {
                stopVpn()
            }
            "enable_kill_switch" -> {
                killSwitchEnabled = true
                Log.d(TAG, "Kill switch enabled: $killSwitchEnabled")
            }
            "disable_kill_switch" -> {
                killSwitchEnabled = false
                Log.d(TAG, "Kill switch enabled: $killSwitchEnabled")
            }
            "update_config" -> {
                val config = intent.getStringExtra("config")
                this.currentConfig = config
                // Libcore.updateConfig(config)
                Log.d(TAG, "Updating VPN config from intent: $config")
            }
        }

        return START_STICKY
    }

    private fun startVpn(config: String?) {
        if (vpnInterface != null) {
            stopVpn()
        }

        try {
            val builder = Builder()
                .setSession("NekoBoxVPN")
                .addAddress("10.0.0.2", 32) // Example VPN IP
                .addRoute("0.0.0.0", 0) // Route all traffic through VPN
                .addDnsServer("8.8.8.8") // Example DNS server

            if (killSwitchEnabled) {
                builder.setBlocking(true) // Block traffic if VPN is not connected
            }

            // Prepare notification for foreground service
            createNotificationChannel()
            val notificationIntent = Intent(this, Class.forName("io.nekohasekai.sagernet.ui.MainActivity")) // Replace with your main activity
            val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("NekoBox VPN")
                .setContentText("VPN is connecting...")
                .setSmallIcon(android.R.drawable.ic_dialog_info) // Replace with your app icon
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()

            startForeground(NOTIFICATION_ID, notification)

            vpnInterface = builder.establish()

            if (vpnInterface != null) {
                Log.d(TAG, "VPN interface established.")
                vpnStatus = "connecting"

                // Initialize Libcore (assuming it's a singleton and needs context)
                Libcore.initCore(
                    applicationContext.packageName, // process name
                    applicationContext.cacheDir.absolutePath + "/", // cachePath
                    applicationContext.filesDir.absolutePath + "/", // internalAssets
                    applicationContext.getExternalFilesDir(null)?.absolutePath + "/", // externalAssets
                    50, // maxLogSizeKb (example value)
                    true, // logEnable (example value)
                    NativeInterface(), // NB4AInterface implementation
                    NativeInterface() // BoxPlatformInterface implementation
                )

                // Start the native sing-box core with the provided config
                Libcore.start(config) // Assuming Libcore.start takes only config
                coreVersion = Libcore.getVersion() // Assuming Libcore.getVersion() exists

                vpnThread = Thread { 
                    Log.d(TAG, "VPN thread started.")
                    // In a real implementation, you'd read from vpnInterface.fileDescriptor
                    // and write to it, passing data to/from the sing-box core.
                    // This is where the actual VPN tunnel data flow happens.
                    // Example: Libcore.run(vpnInterface.fileDescriptor)
                    while (isRunning) {
                        try {
                            // Update connection stats periodically
                            connectionStats = Libcore.getStats() // Assuming Libcore.getStats() exists
                            vpnStatus = Libcore.getStatus() // Assuming Libcore.getStatus() exists
                            Thread.sleep(1000) // Update every second
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                            break
                        }
                    }
                    Log.d(TAG, "VPN thread stopped.")
                }
                vpnThread?.start()

                vpnStatus = "connected"
                updateNotification("NekoBox VPN", "VPN Connected")

            } else {
                Log.e(TAG, "Failed to establish VPN interface.")
                vpnStatus = "disconnected"
                updateNotification("NekoBox VPN", "VPN Disconnected")
                stopSelf()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN: ", e)
            vpnStatus = "disconnected"
            updateNotification("NekoBox VPN", "VPN Disconnected")
            stopSelf()
        }
    }

    private fun stopVpn() {
        Log.d(TAG, "NekoVpnService stopping")
        isRunning = false
        vpnThread?.interrupt()
        vpnThread = null

        try {
            vpnInterface?.close()
            vpnInterface = null
            // Stop the native sing-box core
            Libcore.stop() // Assuming Libcore.stop() exists
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN: ", e)
        }
        vpnStatus = "disconnected"
        updateNotification("NekoBox VPN", "VPN Disconnected")
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "NekoVpnService destroyed")
        stopVpn()
    }

    override fun onRevoke() {
        super.onRevoke()
        Log.d(TAG, "VPN permission revoked.")
        stopVpn()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return binder
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "NekoBox VPN Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun updateNotification(title: String, text: String) {
        val notificationIntent = Intent(this, Class.forName("io.nekohasekai.sagernet.ui.MainActivity")) // Replace with your main activity
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
