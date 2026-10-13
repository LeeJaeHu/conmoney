package com.leejaehu.conmoney

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * 등록한 카드사 알림만 원문으로 저장한다(Spec F1 필터 규칙, F2 처리 순서 1).
 * 그 외 앱은 본문을 읽지 않고 패키지명만 센다.
 */
class PaymentNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val store = RawNotificationStore.get(this)
        val pkg = sbn.packageName
        store.markSeen(pkg, sbn.postTime)

        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        if (!SourceFilter.accepts(pkg, title)) return

        store.insert(
            RawNotification(
                packageName = pkg,
                key = sbn.key,
                title = title,
                text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString(),
                subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString(),
                postedAt = sbn.postTime,
            )
        )
    }
}

/** 결제 알림 출처(Spec F1 카드 카탈로그). 패키지명은 실제 폰에서 seen_packages로 확인해 고친다. */
object SourceFilter {
    private const val KAKAO = "com.kakao.talk"

    val paymentPackages = setOf(
        "com.hyundaicard.appcard", // 현대카드 [확인 필요]
        "viva.republica.toss",     // 토스
        KAKAO,                     // 롯데카드 알림톡
    )

    fun accepts(pkg: String, title: String?): Boolean = when (pkg) {
        // 카카오톡은 일반 대화가 섞이므로 롯데카드 알림톡만 받는다
        KAKAO -> title?.contains("롯데카드") == true
        else -> pkg in paymentPackages
    }
}
