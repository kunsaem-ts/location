package com.tsdevel.locationcheck

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyCallback
import android.telephony.TelephonyDisplayInfo
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter 패키지가 노출하지 않는 Android 전용 정보를 MethodChannel로 제공한다.
 * - 3단계(FR-06a): 전화 상태 권한, 데이터 네트워크 종류(LTE/5G)
 * - 5단계(FR-07): 위치 제공자(gps/network/fused)는 이후 추가
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.tsdevel.locationcheck/platform"
    private val phoneStateRequestCode = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** Android 13+는 READ_BASIC_PHONE_STATE로 충분하고, 그 이하는 READ_PHONE_STATE가 필요하다 (PRD 5.1). */
    private val phoneStatePermission: String
        get() = if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_BASIC_PHONE_STATE
        } else {
            Manifest.permission.READ_PHONE_STATE
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPhoneStatePermission" -> result.success(hasPhoneStatePermission())
                    "requestPhoneStatePermission" -> requestPhoneStatePermission(result)
                    "getDataNetworkType" -> result.success(dataNetworkType())
                    "getDisplayOverrideNetworkType" -> displayOverrideNetworkType(result)
                    "getLastLocationProvider" -> result.success(
                        lastLocationProvider(
                            call.argument<Double>("latitude"),
                            call.argument<Double>("longitude"),
                            call.argument<Number>("timeMillis")?.toLong(),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasPhoneStatePermission(): Boolean =
        checkSelfPermission(phoneStatePermission) == PackageManager.PERMISSION_GRANTED

    private fun requestPhoneStatePermission(result: MethodChannel.Result) {
        if (hasPhoneStatePermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("IN_PROGRESS", "permission request already in progress", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(phoneStatePermission), phoneStateRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == phoneStateRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    /**
     * 방금 측정한 좌표의 위치 제공자(gps / network / fused) (FR-07).
     * Flutter 위치 패키지는 제공자를 노출하지 않으므로, 각 제공자의 마지막 위치 중
     * 좌표·시각이 일치하는 것을 찾는다. 일치하는 게 없으면 가장 최신 위치의 제공자를 돌려준다.
     */
    private fun lastLocationProvider(lat: Double?, lng: Double?, timeMillis: Long?): String? {
        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            "fused", // LocationManager.FUSED_PROVIDER는 API 31+
        )
        var newest: Location? = null
        for (name in providers) {
            val loc = try {
                lm.getLastKnownLocation(name)
            } catch (e: Exception) {
                null // 권한 없음(SecurityException) 또는 미지원 제공자(IllegalArgumentException)
            } ?: continue
            val sameFix = lat != null && lng != null && timeMillis != null &&
                loc.latitude == lat && loc.longitude == lng &&
                Math.abs(loc.time - timeMillis) < 1000
            if (sameFix) return loc.provider
            if (newest == null || loc.time > newest.time) newest = loc
        }
        return newest?.provider
    }

    /** TelephonyManager.dataNetworkType. 권한이 없거나 조회 실패면 -1. (LTE=13, NR=20) */
    private fun dataNetworkType(): Int {
        if (!hasPhoneStatePermission()) return -1
        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        return try {
            tm.dataNetworkType
        } catch (e: SecurityException) {
            -1
        }
    }

    /**
     * 국내 5G는 대부분 NSA라서 dataNetworkType이 LTE(13)로 나온다.
     * 이 경우 TelephonyDisplayInfo.overrideNetworkType(NR_NSA=3, NR_NSA_MMWAVE=4, NR_ADVANCED=5)로 5G를 판별한다.
     * API 31 미만이거나 권한이 없거나 2초 안에 콜백이 없으면 -1.
     */
    private fun displayOverrideNetworkType(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 31 || !hasPhoneStatePermission()) {
            result.success(-1)
            return
        }
        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        val handler = Handler(Looper.getMainLooper())
        var delivered = false
        lateinit var callback: TelephonyCallback

        fun deliver(value: Int) {
            if (delivered) return
            delivered = true
            try {
                tm.unregisterTelephonyCallback(callback)
            } catch (_: Exception) {
            }
            result.success(value)
        }

        callback = object : TelephonyCallback(), TelephonyCallback.DisplayInfoListener {
            override fun onDisplayInfoChanged(info: TelephonyDisplayInfo) {
                deliver(info.overrideNetworkType)
            }
        }
        try {
            tm.registerTelephonyCallback(mainExecutor, callback)
            handler.postDelayed({ deliver(-1) }, 2000)
        } catch (e: SecurityException) {
            deliver(-1)
        }
    }
}
