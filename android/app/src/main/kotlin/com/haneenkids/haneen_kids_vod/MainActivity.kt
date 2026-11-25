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
