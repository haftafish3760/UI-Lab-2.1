package io.flutter.plugins.imagepicker;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONException;

/** Deletes only durably acknowledged manifests, never directory-scan candidates. */
final class NativeMediaCleanup {
  private NativeMediaCleanup() {}

  static void createTable(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE media_cleanup (request_key TEXT PRIMARY KEY NOT NULL, paths TEXT NOT NULL)");
  }

  static boolean collect(SQLiteDatabase db, Context context,
      DurableMediaResultJournal.DirectorySync sync) {
    // Cleanup is opportunistic. A failed deletion/flush retains its durable row
    // and must not turn an already committed acknowledgement into a failed save.
    try {
      File root = new File(context.getFilesDir().getCanonicalFile(), "native_media_handoff");
      if (!root.getCanonicalFile().equals(root.getAbsoluteFile())) return false;
      List<String[]> pending = new ArrayList<>();
      try (Cursor rows = db.rawQuery("SELECT c.request_key,c.paths FROM media_cleanup c "
          + "JOIN acknowledgements a ON a.request_key=c.request_key "
          + "WHERE NOT EXISTS (SELECT 1 FROM handoff h WHERE h.request_key=c.request_key "
          + "AND h.state!='acknowledged')", null)) {
        while (rows.moveToNext()) pending.add(new String[] {rows.getString(0), rows.getString(1)});
      }
      for (String[] entry : pending) {
        JSONArray manifest = new JSONArray(entry[1]);
        List<File> files = new ArrayList<>();
        // Validate the entire manifest before removing any of its entries.
        for (int i = 0; i < manifest.length(); i++) {
          File file = new File(manifest.getJSONObject(i).getString("path"));
          if (!file.getCanonicalFile().equals(file.getAbsoluteFile())
              || !root.equals(file.getParentFile())
              || (file.exists() && !file.isFile())) return false;
          files.add(file);
        }
        for (File file : files) {
          if (file.exists() && !file.delete()) return false;
        }
        // Repeating after a crash is safe: missing files count as removed.
        if (root.exists()) sync.flush(root);
        db.delete("media_cleanup", "request_key=?", new String[] {entry[0]});
      }
      return true;
    } catch (IOException | JSONException | RuntimeException failure) {
      return false;
    }
  }
}
