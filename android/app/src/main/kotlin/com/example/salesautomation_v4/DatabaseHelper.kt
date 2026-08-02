package com.example.salesautomation_v4

import android.annotation.SuppressLint
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "user_data.db"
        private const val DATABASE_VERSION = 1

        private const val TABLE_USER = "user_data"
        private const val COLUMN_ID = "id"
        private const val COLUMN_USERNAME = "username"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = """
            CREATE TABLE IF NOT EXISTS $TABLE_USER (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_USERNAME TEXT
            )
        """.trimIndent()
        db.execSQL(createTable)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_USER")
        onCreate(db)
    }

    @SuppressLint("Range")
    fun getUsername(): String? {
        val db = this.readableDatabase

        // ✅ Ensure the table exists before querying
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_USER (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_USERNAME TEXT
            )
        """.trimIndent())

        var username: String? = null
        val cursor = db.rawQuery(
            "SELECT $COLUMN_USERNAME FROM $TABLE_USER WHERE $COLUMN_ID = 1",
            null
        )

        if (cursor.moveToFirst()) {
            username = cursor.getString(cursor.getColumnIndex(COLUMN_USERNAME))
        }

        cursor.close()
        db.close()
        return username
    }
}
