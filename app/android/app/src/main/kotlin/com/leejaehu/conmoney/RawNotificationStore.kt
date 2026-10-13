package com.leejaehu.conmoney

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * 결제 알림 원문을 앱 프로세스가 죽어 있어도 받아 두는 네이티브 저장소(Spec 1장, 2.1 raw_notifications).
 * Flutter 쪽은 MethodChannel로 이 표를 읽어 간다.
 *
 * seen_packages에는 알림을 보낸 앱의 패키지명과 횟수만 남긴다(본문 없음).
 * 현대카드 앱처럼 패키지명을 아직 모르는 카드사 앱을 찾기 위한 용도다.
 */
class RawNotificationStore(context: Context) :
    SQLiteOpenHelper(context, "raw_notifications.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE raw_notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                package TEXT NOT NULL,
                notif_key TEXT NOT NULL,
                title TEXT,
                text TEXT,
                big_text TEXT,
                sub_text TEXT,
                posted_at INTEGER NOT NULL,
                content_hash TEXT NOT NULL,
                UNIQUE(notif_key, content_hash)
            )
            """.trimIndent()
        )
        db.execSQL(
            """
            CREATE TABLE seen_packages (
                package TEXT PRIMARY KEY,
                count INTEGER NOT NULL,
                last_seen INTEGER NOT NULL
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    /** 같은 알림의 재게시(같은 key + 같은 본문)는 무시한다(Spec F2 처리 순서 2). */
    fun insert(raw: RawNotification): Boolean {
        val values = ContentValues().apply {
            put("package", raw.packageName)
            put("notif_key", raw.key)
            put("title", raw.title)
            put("text", raw.text)
            put("big_text", raw.bigText)
            put("sub_text", raw.subText)
            put("posted_at", raw.postedAt)
            put("content_hash", raw.contentHash())
        }
        return writableDatabase.insertWithOnConflict(
            "raw_notifications", null, values, SQLiteDatabase.CONFLICT_IGNORE
        ) != -1L
    }

    // UPSERT 문법은 Android 11 미만의 SQLite에 없어서 UPDATE 후 없으면 INSERT 한다
    fun markSeen(packageName: String, at: Long) {
        val db = writableDatabase
        db.execSQL(
            "UPDATE seen_packages SET count = count + 1, last_seen = ? WHERE package = ?",
            arrayOf<Any>(at, packageName)
        )
        db.execSQL(
            "INSERT OR IGNORE INTO seen_packages(package, count, last_seen) VALUES(?, 1, ?)",
            arrayOf<Any>(packageName, at)
        )
    }

    fun fetchSince(afterId: Long, limit: Int): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        readableDatabase.rawQuery(
            "SELECT id, package, notif_key, title, text, big_text, sub_text, posted_at " +
                "FROM raw_notifications WHERE id > ? ORDER BY id LIMIT ?",
            arrayOf(afterId.toString(), limit.toString())
        ).use { c ->
            while (c.moveToNext()) {
                rows.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "package" to c.getString(1),
                        "notifKey" to c.getString(2),
                        "title" to c.getString(3),
                        "text" to c.getString(4),
                        "bigText" to c.getString(5),
                        "subText" to c.getString(6),
                        "postedAt" to c.getLong(7),
                    )
                )
            }
        }
        return rows
    }

    fun seenPackages(): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        readableDatabase.rawQuery(
            "SELECT package, count, last_seen FROM seen_packages ORDER BY last_seen DESC", null
        ).use { c ->
            while (c.moveToNext()) {
                rows.add(mapOf("package" to c.getString(0), "count" to c.getLong(1), "lastSeen" to c.getLong(2)))
            }
        }
        return rows
    }

    companion object {
        @Volatile
        private var instance: RawNotificationStore? = null

        fun get(context: Context): RawNotificationStore =
            instance ?: synchronized(this) {
                instance ?: RawNotificationStore(context.applicationContext).also { instance = it }
            }
    }
}

data class RawNotification(
    val packageName: String,
    val key: String,
    val title: String?,
    val text: String?,
    val bigText: String?,
    val subText: String?,
    val postedAt: Long,
) {
    fun contentHash(): String = listOf(title, text, bigText, subText).joinToString("\u0001").hashCode().toString()
}
