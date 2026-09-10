package io.flutter.plugins.imagepicker;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
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

  static boolean collectPreviousProcess(SQLiteDatabase db, Context context,
      DurableMediaResultJournal.DirectorySync sync) {
    try {
      File root = new File(context.getFilesDir().getCanonicalFile(), "native_media_handoff");
      if (!root.getCanonicalFile().equals(root.getAbsoluteFile())) return false;
      List<File> abandoned = new ArrayList<>();
      try (Cursor rows = db.rawQuery("SELECT path FROM media_staging WHERE process_id!=?",
          new String[] {PROCESS})) {
        while (rows.moveToNext()) {
          File file = new File(rows.getString(0));
          if (!file.getCanonicalFile().equals(file.getAbsoluteFile())
              || !root.equals(file.getParentFile())
              || (file.exists() && !file.isFile())) return false;
          abandoned.add(file);
        }
      }
      for (File file : abandoned) {
        if (file.exists() && !file.delete()) return false;
      }
      if (!abandoned.isEmpty() && root.exists()) sync.flush(root);
      for (File file : abandoned) {
        db.delete("media_staging", "path=? AND process_id!=?",
            new String[] {file.getAbsolutePath(), PROCESS});
      }
      return true;
    } catch (IOException | RuntimeException failure) {
      return false;
    }
  }
}
