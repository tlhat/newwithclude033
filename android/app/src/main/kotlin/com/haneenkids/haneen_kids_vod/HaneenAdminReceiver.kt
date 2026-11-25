package com.haneenkids.haneen_kids_vod

import android.app.admin.DeviceAdminReceiver

/**
 * Needed only for the optional "dedicated device" tier. It does nothing until
 * the device owner is set once with adb (see docs/KID_LOCK.md).
 */
class HaneenAdminReceiver : DeviceAdminReceiver()
