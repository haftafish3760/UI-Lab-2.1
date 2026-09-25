package io.flutter.plugins.imagepicker;

import android.database.sqlite.SQLiteDatabase;

/** Retains acknowledged manifests. Acknowledgement never authorizes file deletion. */
final class NativeMediaCleanup {
  private NativeMediaCleanup() {}

  static void createTable(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE media_cleanup (request_key TEXT PRIMARY KEY NOT NULL, paths TEXT NOT NULL)");
  }

}

