package com.haneenkids.haneen_kids_vod

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Child lock. Everything here is local to the phone and uses only normal
 * Android APIs (screen pinning, optional launcher alias, optional device owner).
 * No Accessibility service, no overlay permission, no network.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "haneen/kidlock"
    private val handler = Handler(Looper.getMainLooper())
    private var lockWanted = false
    private var watchdogOn = false

    private val admin: ComponentName by lazy { ComponentName(this, HaneenAdminReceiver::class.java) }
    private val dpm: DevicePolicyManager by lazy { getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Country hints for the dialect and country setup. Local only, no permission,
        // no GPS. Returns two-letter codes read from the SIM and the network.
        // Opens the mail app with a prefilled message (feedback button).
        // Support info: SHA-1 of the certificate(s) this install is signed with.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "haneen/diag").setMethodCallHandler { call, result ->
            if (call.method == "signing") {
                try {
                    fun sha1(b: ByteArray): String =
                        java.security.MessageDigest.getInstance("SHA-1").digest(b)
                            .joinToString(":") { "%02X".format(it) }
                    val out = ArrayList<String>()
                    if (Build.VERSION.SDK_INT >= 28) {
                        val pi = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                        val si = pi.signingInfo
                        if (si != null) {
                            for (sg in si.apkContentsSigners) out.add("current=" + sha1(sg.toByteArray()))
                            if (si.hasPastSigningCertificates()) {
                                for (sg in (si.signingCertificateHistory ?: emptyArray())) out.add("history=" + sha1(sg.toByteArray()))
                            }
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        val pi = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                        @Suppress("DEPRECATION")
                        for (sg in (pi.signatures ?: emptyArray())) out.add("current=" + sha1(sg.toByteArray()))
                    }
                    out.add("package=" + packageName)
                    out.add("installer=" + (try { packageManager.getInstallerPackageName(packageName) } catch (e: Exception) { null }))
                    result.success(out.joinToString("; "))
                } catch (e: Exception) {
                    result.success("signing info error: " + e.message)
                }
            } else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "haneen/mail").setMethodCallHandler { call, result ->
            if (call.method == "compose") {
                try {
                    val to = call.argument<String>("to") ?: ""
                    val uri = android.net.Uri.parse("mailto:" + android.net.Uri.encode(to) +
                        "?subject=" + android.net.Uri.encode(call.argument<String>("subject") ?: "") +
                        "&body=" + android.net.Uri.encode(call.argument<String>("body") ?: ""))
                    val i = Intent(Intent.ACTION_SENDTO, uri)
                    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(i)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "haneen/region").setMethodCallHandler { call, result ->
            if (call.method == "countryHints") {
                try {
                    val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    result.success(mapOf("sim" to (tm.simCountryIso ?: ""), "network" to (tm.networkCountryIso ?: "")))
                } catch (e: Exception) {
                    result.success(mapOf("sim" to "", "network" to ""))
                }
            } else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(status())
                    "enter" -> {
                        lockWanted = true
                        watchdogOn = call.argument<Boolean>("watchdog") ?: true
                        applyDeviceOwnerPolicies(true)
                        try { startLockTask() } catch (e: Exception) { /* not allowed right now */ }
                        result.success(status())
                    }
                    "exit" -> {
                        lockWanted = false
                        watchdogOn = false
                        try { stopLockTask() } catch (e: Exception) { }
                        applyDeviceOwnerPolicies(false)
                        setHomeAlias(false)
                        result.success(status())
                    }
                    "setWatchdog" -> {
                        watchdogOn = call.argument<Boolean>("on") ?: false
                        result.success(status())
                    }
                    "setHomeAlias" -> {
                        setHomeAlias(call.argument<Boolean>("on") ?: false)
                        result.success(status())
                    }
                    "openHomeSettings" -> {
                        val i = Intent(Settings.ACTION_HOME_SETTINGS)
                        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try { startActivity(i) } catch (e: Exception) {
                            val h = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                            h.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(h)
                        }
                        result.success(status())
                    }
                    "releaseDeviceOwner" -> {
                        lockWanted = false
                        try { stopLockTask() } catch (e: Exception) { }
                        applyDeviceOwnerPolicies(false)
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            @Suppress("DEPRECATION")
                            dpm.clearDeviceOwnerApp(packageName)
                        }
                        result.success(status())
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("kidlock", e.message, null)
            }
        }
    }

    private fun isPinned(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
    }

    private fun isDefaultHome(): Boolean {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val ri = packageManager.resolveActivity(i, PackageManager.MATCH_DEFAULT_ONLY)
        return ri?.activityInfo?.packageName == packageName
    }

    private fun homeAliasEnabled(): Boolean {
        val c = ComponentName(this, "com.haneenkids.haneen_kids_vod.KidHome")
        return packageManager.getComponentEnabledSetting(c) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
    }

    private fun status(): Map<String, Any> = mapOf(
        "pinned" to isPinned(),
        "deviceOwner" to dpm.isDeviceOwnerApp(packageName),
        "defaultHome" to isDefaultHome(),
        "homeAlias" to homeAliasEnabled(),
        "watchdog" to watchdogOn,
        "sdk" to Build.VERSION.SDK_INT
    )

    /** The launcher alias is off by default so Haneen never shows up as a launcher unless the parent asks. */
    private fun setHomeAlias(on: Boolean) {
        val c = ComponentName(this, "com.haneenkids.haneen_kids_vod.KidHome")
        packageManager.setComponentEnabledSetting(
            c,
            if (on) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }

    /** Dedicated-device tier. Only does something when this app is the device owner. */
    private fun applyDeviceOwnerPolicies(on: Boolean) {
        if (!dpm.isDeviceOwnerApp(packageName)) return
        try {
            if (on) {
                dpm.setLockTaskPackages(admin, arrayOf(packageName))
                if (Build.VERSION.SDK_INT >= 28) {
                    // No home, overview, notifications, system info, power menu or keyguard features.
                    dpm.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
                }
                setHomeAlias(true)
                val filter = IntentFilter(Intent.ACTION_MAIN)
                filter.addCategory(Intent.CATEGORY_HOME)
                filter.addCategory(Intent.CATEGORY_DEFAULT)
                dpm.addPersistentPreferredActivity(
                    admin, filter, ComponentName(this, "com.haneenkids.haneen_kids_vod.KidHome")
                )
            } else {
                dpm.clearPackagePersistentPreferredActivities(admin, packageName)
                if (Build.VERSION.SDK_INT >= 28) {
                    dpm.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_HOME or DevicePolicyManager.LOCK_TASK_FEATURE_OVERVIEW)
                }
            }
        } catch (e: Exception) {
            // Keep the app usable if a policy call is refused on this device.
        }
    }

    /**
     * Best-effort watchdog. If the child leaves the app while the lock is on and
     * we are not pinned, try to bring the task back. Android 10+ limits starting
     * activities from the background, so this works on some phones and not on
     * others. Real locking comes from pinning, launcher mode or device owner.
     */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (lockWanted && watchdogOn && !isPinned()) bringBack()
    }

    override fun onStop() {
        super.onStop()
        if (lockWanted && watchdogOn && !isPinned()) bringBack()
    }

    private fun bringBack() {
        val delays = longArrayOf(300, 1200, 3000)
        for (d in delays) {
            handler.postDelayed({
                if (lockWanted && watchdogOn) {
                    try {
                        val i = Intent(this, MainActivity::class.java)
                        i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(i)
                    } catch (e: Exception) { }
                }
            }, d)
        }
    }

    override fun onResume() {
        super.onResume()
        handler.removeCallbacksAndMessages(null)
    }
}
