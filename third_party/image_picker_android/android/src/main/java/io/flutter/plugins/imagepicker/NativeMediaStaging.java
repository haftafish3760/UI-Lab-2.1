package io.flutter.plugins.imagepicker;

import android.content.ContentValues;
import android.database.sqlite.SQLiteDatabase;
import java.io.File;
import java.util.UUID;

/** Pre-publication copy ownership for the app's single Android process. */
final class NativeMediaStaging {
  // Shared by all helper instances in this process. Reopening a helper must not
  // mistake a concurrent live copy for a previous-process orphan.
  private static final String PROCESS = UUID.randomUUID().toString();
  private NativeMediaStaging() {}

  static void createTable(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE media_staging (path TEXT PRIMARY KEY NOT NULL, process_id TEXT NOT NULL)");
  }

  static void register(SQLiteDatabase db, File target) {
    ContentValues values = new ContentValues();
    values.put("path", target.getAbsolutePath());
    values.put("process_id", PROCESS);
    db.insertOrThrow("media_staging", null, values);
  }

}

