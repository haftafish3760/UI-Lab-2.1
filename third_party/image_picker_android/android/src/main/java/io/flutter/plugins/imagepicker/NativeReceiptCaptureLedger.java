package io.flutter.plugins.imagepicker;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.List;

/** Associates the destination with its request BEFORE CameraX starts writing.
 * Incomplete captures remain discoverable, but never masquerade as completed
 * media. No recovery operation deletes or rewrites an original.
 */
final class NativeReceiptCaptureLedger {
  static void createTable(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE receipt_captures (path TEXT PRIMARY KEY NOT NULL, "
        + "request_key TEXT NOT NULL, length INTEGER, sha256 TEXT)");
    db.execSQL("CREATE INDEX receipt_capture_request ON receipt_captures(request_key)");
  }

  static File validate(Context context, String path) throws IOException {
    File file = new File(path);
    File root = new File(context.getFilesDir().getCanonicalFile(), "receipt_camera");
    if (!file.isAbsolute() || !file.getCanonicalFile().equals(file.getAbsoluteFile())
        || !root.equals(file.getParentFile())) {
      throw new IOException("Receipt capture is outside its owned directory");
    }
    return file;
  }

  static void plan(SQLiteDatabase db, Context context, String key, String path)
      throws IOException {
    File file = validate(context, path);
    if (file.exists()) throw new IOException("Capture destination already exists");
    ContentValues values = new ContentValues();
    values.put("path", path);
    values.put("request_key", key);
    db.insertOrThrow("receipt_captures", null, values);
  }

  static void complete(SQLiteDatabase db, Context context, String key, String path)
      throws IOException {
    File file = validate(context, path);
    try (Cursor row = db.rawQuery(
        "SELECT request_key,length,sha256 FROM receipt_captures WHERE path=?",
        new String[] {path})) {
      if (!row.moveToFirst() || !key.equals(row.getString(0))) {
        throw new IOException("Capture request ownership is unavailable");
      }
      if (!file.isFile() || file.length() == 0) throw new IOException("Capture is incomplete");
      long length = file.length();
      String digest = DurableMediaResultJournal.digest(file);
      if (!row.isNull(1)) {
        if (length != row.getLong(1) || !digest.equals(row.getString(2))) {
          throw new IOException("Completed capture was changed");
        }
        return;
      }
      try (RandomAccessFile bytes = new RandomAccessFile(file, "rw")) {
        bytes.getFD().sync();
      }
      if (file.length() != length || !digest.equals(DurableMediaResultJournal.digest(file))) {
        throw new IOException("Capture changed while checkpointing");
      }
      ContentValues values = new ContentValues();
      values.put("length", length);
      values.put("sha256", digest);
      db.update("receipt_captures", values, "path=? AND request_key=?",
          new String[] {path, key});
    }
  }

  static boolean hasRequest(SQLiteDatabase db, String key) {
    try (Cursor row = db.rawQuery("SELECT 1 FROM receipt_captures WHERE request_key=? LIMIT 1",
        new String[] {key})) { return row.moveToFirst(); }
  }

  static List<String> completed(SQLiteDatabase db, Context context, String key)
      throws IOException {
    List<String> paths = new ArrayList<>();
    try (Cursor rows = db.rawQuery(
        "SELECT path,length,sha256 FROM receipt_captures WHERE request_key=? ORDER BY rowid",
        new String[] {key})) {
      while (rows.moveToNext()) {
        if (rows.isNull(1)) continue;
        File file = validate(context, rows.getString(0));
        if (!file.isFile() || file.length() != rows.getLong(1)
            || !DurableMediaResultJournal.digest(file).equals(rows.getString(2))) {
          throw new IOException("Saved camera capture is missing or changed");
        }
        paths.add(file.getAbsolutePath());
      }
    }
    return paths;
  }
}
