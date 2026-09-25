package io.flutter.plugins.imagepicker;

import android.system.Os;
import android.system.OsConstants;
import android.system.ErrnoException;
import java.io.FileDescriptor;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/** App-private replay journal. Native result delivery must follow storeResults;
 * Dart acknowledges only after its own retained-file transaction commits.
 * No record, widget, employee or SQL schema from the Flutter app is referenced. */
final class DurableMediaResultJournal extends SQLiteOpenHelper {
  private final Context context;
  interface DirectorySync { void flush(File directory) throws IOException; }
  private final DirectorySync directorySync;

  DurableMediaResultJournal(Context context) {
    this(context, DurableMediaResultJournal::syncDirectory);
  }

  // Native directory sync is injected only by JVM tests whose filesystem model
  // cannot open directories. Production always uses the strict OS implementation.
  DurableMediaResultJournal(Context context, DirectorySync directorySync) {
    super(context, "maintainiac_native_media.sqlite", null, 5);
    this.context = context.getApplicationContext();
    this.directorySync = directorySync;
  }

  @Override public void onConfigure(SQLiteDatabase db) {
    db.execSQL("PRAGMA synchronous=FULL");
  }

  @Override public void onCreate(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE handoff (slot INTEGER PRIMARY KEY CHECK(slot=1), "
        + "request_key TEXT NOT NULL, state TEXT NOT NULL, paths TEXT)");
    createAcknowledgements(db);
    NativeMediaCleanup.createTable(db);
    NativeMediaStaging.createTable(db);
    NativeReceiptCaptureLedger.createTable(db);
  }

  private static void createAcknowledgements(SQLiteDatabase db) {
    db.execSQL("CREATE TABLE acknowledgements (request_key TEXT PRIMARY KEY NOT NULL)");
  }

  @Override public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
    if (oldVersion < 1 || oldVersion > 4 || newVersion != 5) {
      throw new IllegalStateException("Unsupported native media journal version");
    }
    if (oldVersion == 1) {
      createAcknowledgements(db);
      db.execSQL("INSERT INTO acknowledgements SELECT request_key FROM handoff WHERE state='acknowledged'");
    }
    if (oldVersion < 3) NativeMediaCleanup.createTable(db);
    if (oldVersion < 4) NativeMediaStaging.createTable(db);
    NativeReceiptCaptureLedger.createTable(db);
  }

  synchronized void begin(String key) {
    if (key == null || !key.matches("[A-Za-z0-9_-]{8,160}")) {
      throw new IllegalArgumentException("Invalid media request identity");
    }
    cleanAcknowledgedCopies();
    SQLiteDatabase db = getWritableDatabase();
    // Preserve prior-process staging until explicit user-confirmed deletion.
    db.beginTransaction();
    try {
      if (isAcknowledged(db, key)) throw new IllegalStateException("Media request already acknowledged");
      try (Cursor row = db.rawQuery("SELECT request_key,state FROM handoff WHERE slot=1", null)) {
        if (row.moveToFirst() && !row.getString(1).equals("acknowledged")) {
          if (!row.getString(0).equals(key)) {
            throw new IllegalStateException("Another media result remains unacknowledged");
          }
          db.setTransactionSuccessful();
          return;
        }
      }
      ContentValues values = new ContentValues();
      values.put("slot", 1);
      values.put("request_key", key);
      values.put("state", "pending");
      values.putNull("paths");
      db.insertWithOnConflict("handoff", null, values, SQLiteDatabase.CONFLICT_REPLACE);
      db.setTransactionSuccessful();
    } finally { db.endTransaction(); }
  }

  synchronized String activeKey() {
    try (Cursor row = getReadableDatabase().rawQuery(
        "SELECT request_key FROM handoff WHERE slot=1 AND state!='acknowledged'", null)) {
      return row.moveToFirst() ? row.getString(0) : null;
    }
  }

  synchronized java.util.Map<String, Object> prepareRecovery(String key)
      throws IOException, JSONException {
    java.util.Map<String, Object> result = new java.util.HashMap<>();
    boolean acknowledged = isAcknowledged(getReadableDatabase(), key);
    if (!acknowledged) begin(key);
    List<String> paths = read(key);
    boolean cameraCapture = !acknowledged
        && NativeReceiptCaptureLedger.hasRequest(getReadableDatabase(), key);
    if (cameraCapture && paths.isEmpty()) {
      List<String> completed = NativeReceiptCaptureLedger.completed(
          getReadableDatabase(), context, key);
      if (!completed.isEmpty()) paths = storeResults(key, completed);
    }
    result.put("paths", paths);
    result.put("needsLegacyRecovery", !acknowledged && paths.isEmpty() && !cameraCapture);
    return result;
  }

  synchronized List<String> read(String key) throws JSONException, IOException {
    if (isAcknowledged(getReadableDatabase(), key)) return new ArrayList<>();
    try (Cursor row = getReadableDatabase().rawQuery(
        "SELECT request_key,state,paths FROM handoff WHERE slot=1", null)) {
      if (!row.moveToFirst()) return new ArrayList<>();
      requireKey(row.getString(0), key);
      if (!row.getString(1).equals("ready")) return new ArrayList<>();
      JSONArray paths = new JSONArray(row.getString(2));
      List<String> result = new ArrayList<>();
      File root = new File(context.getFilesDir().getCanonicalFile(), "native_media_handoff");
      for (int i = 0; i < paths.length(); i++) {
        JSONObject entry = paths.getJSONObject(i);
        File retained = new File(entry.getString("path"));
        if (!retained.getCanonicalFile().equals(retained.getAbsoluteFile())
            || !root.equals(retained.getParentFile())
            || !retained.isFile()
            || retained.length() != entry.getLong("length")
            || !digest(retained).equals(entry.getString("sha256"))) {
          throw new IOException("Retained native media is missing, changed or redirected");
        }
        result.add(retained.getAbsolutePath());
      }
      return result;
    }
  }

  synchronized List<String> storeResults(String key, List<String> sources)
      throws IOException, JSONException {
    SQLiteDatabase db = getWritableDatabase();
    requirePendingKey(db, key);
    List<String> existing = read(key);
    if (!existing.isEmpty()) return existing;
    File root = new File(context.getFilesDir().getCanonicalFile(), "native_media_handoff");
    if (!root.isDirectory() && !root.mkdirs()) throw new IOException("Cannot create media journal");
    if (!root.getCanonicalFile().equals(root.getAbsoluteFile())) {
      throw new IOException("Media journal location is redirected");
    }
    List<String> retained = new ArrayList<>();
    JSONArray manifest = new JSONArray();
    List<File> provisional = new ArrayList<>();
    try {
      for (String path : sources) {
        File source = new File(path).getCanonicalFile();
        String cache = context.getCacheDir().getCanonicalPath() + File.separator;
        String files = context.getFilesDir().getCanonicalPath() + File.separator;
        if (!source.getPath().startsWith(cache) && !source.getPath().startsWith(files)) {
          throw new IOException("Media source is outside application storage");
        }
        if (!source.isFile() || source.length() == 0) throw new IOException("Media source unavailable");
        long expectedLength = source.length();
        if (root.getUsableSpace() - expectedLength < 100L * 1024 * 1024) {
          throw new IOException("Not enough storage to retain native media safely");
        }
        String expectedDigest = digest(source);
        String name = source.getName();
        int dot = name.lastIndexOf('.');
        String extension = dot < 0 ? ".image" : name.substring(dot).toLowerCase(java.util.Locale.ROOT);
        if (!extension.matches("\\.(jpg|jpeg|png|webp|heic|heif|gif|bmp)")) extension = ".image";
        File target = new File(root, UUID.randomUUID() + extension);
        NativeMediaStaging.register(db, target);
        provisional.add(target);
        try (FileInputStream input = new FileInputStream(source);
             FileOutputStream output = new FileOutputStream(target)) {
          byte[] buffer = new byte[65536];
          int count;
          while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
          output.getFD().sync();
        }
        if (target.length() != expectedLength || source.length() != expectedLength
            || !digest(target).equals(expectedDigest) || !digest(source).equals(expectedDigest)) {
          throw new IOException("Native media changed during retention");
        }
        manifest.put(new JSONObject().put("path", target.getAbsolutePath())
            .put("length", expectedLength).put("sha256", expectedDigest));
        retained.add(target.getAbsolutePath());
      }
      directorySync.flush(root);
      directorySync.flush(root.getParentFile());
    } catch (IOException | JSONException | RuntimeException failure) {
      // Keep provisional files and their staging rows. App ownership does not
      // authorize automatic deletion, even when publication failed.
      throw failure;
    }
    db.beginTransaction();
    try {
      requirePendingKey(db, key);
      // Another helper can publish while this helper copies bytes. Recheck under
      // the database write transaction, not only this instance's Java monitor.
      // Losing provisional files remain in staging for crash-safe reclamation.
      List<String> published = read(key);
      if (!published.isEmpty()) {
        db.setTransactionSuccessful();
        return published;
      }
      ContentValues values = new ContentValues();
      values.put("state", "ready");
      values.put("paths", manifest.toString());
      for (File file : provisional) {
        db.delete("media_staging", "path=?", new String[] {file.getAbsolutePath()});
      }
      db.update("handoff", values, "slot=1 AND request_key=?", new String[] {key});
      db.setTransactionSuccessful();
    } finally { db.endTransaction(); }
    return retained;
  }

  synchronized void acknowledge(String key) {
    finish(key, false);
    cleanAcknowledgedCopies();
  }
  synchronized void abandon(String key) {
    finish(key, true);
    cleanAcknowledgedCopies();
  }

  synchronized boolean cleanAcknowledgedCopies() {
    // Acknowledgement ends replay, not ownership or retention. The manifest
    // remains in media_cleanup for a future explicit, confirmed removal flow.
    return true;
  }

  void flushCaptureDirectory(File file) throws IOException {
    directorySync.flush(file.getParentFile());
    directorySync.flush(file.getParentFile().getParentFile());
  }

  private void finish(String key, boolean allowPending) {
    if (key == null || !key.matches("[A-Za-z0-9_-]{8,160}")) {
      throw new IllegalArgumentException("Invalid media request identity");
    }
    SQLiteDatabase db = getWritableDatabase();
    db.beginTransaction();
    try {
      if (isAcknowledged(db, key)) {
        db.setTransactionSuccessful();
        return;
      }
      try (Cursor row = db.rawQuery("SELECT request_key,state FROM handoff WHERE slot=1", null)) {
        if (!row.moveToFirst()) {
          if (!allowPending) throw new IllegalStateException("Media request unavailable");
        } else {
          requireKey(row.getString(0), key);
          if (!allowPending && row.getString(1).equals("pending")) {
            throw new IllegalStateException("No delivered media result to acknowledge");
          }
        }
      }
      // Preserve deletion ownership atomically before clearing replay paths.
      db.execSQL("INSERT OR IGNORE INTO media_cleanup(request_key,paths) "
          + "SELECT request_key,paths FROM handoff WHERE slot=1 AND request_key=? AND paths IS NOT NULL",
          new Object[] {key});
      ContentValues values = new ContentValues();
      values.put("state", "acknowledged");
      values.putNull("paths");
      db.update("handoff", values, "slot=1 AND request_key=?", new String[] {key});
      ContentValues receipt = new ContentValues();
      receipt.put("request_key", key);
      db.insertOrThrow("acknowledgements", null, receipt);
      db.setTransactionSuccessful();
    } finally { db.endTransaction(); }
  }

  private static boolean isAcknowledged(SQLiteDatabase db, String key) {
    try (Cursor row = db.rawQuery(
        "SELECT 1 FROM acknowledgements WHERE request_key=?", new String[] {key})) {
      return row.moveToFirst();
    }
  }

  private static void requirePendingKey(SQLiteDatabase db, String key) {
    try (Cursor row = db.rawQuery("SELECT request_key,state FROM handoff WHERE slot=1", null)) {
      if (!row.moveToFirst() || row.getString(1).equals("acknowledged")) {
        throw new IllegalStateException("Media request is not pending");
      }
      requireKey(row.getString(0), key);
    }
  }

  private static void syncDirectory(File directory) throws IOException {
    FileDescriptor descriptor = null;
    try {
      descriptor = Os.open(directory.getPath(), OsConstants.O_RDONLY, 0);
      if (!OsConstants.S_ISDIR(Os.fstat(descriptor).st_mode)) {
        throw new IOException("Media journal path is not a directory");
      }
      Os.fsync(descriptor);
    } catch (ErrnoException error) {
      throw new IOException("Cannot flush media journal directory", error);
    } finally {
      if (descriptor != null) {
        try { Os.close(descriptor); }
        catch (ErrnoException error) { throw new IOException("Cannot close media journal directory", error); }
      }
    }
  }

  static String digest(File file) throws IOException {
    try {
      MessageDigest hash = MessageDigest.getInstance("SHA-256");
      try (FileInputStream input = new FileInputStream(file)) {
        byte[] buffer = new byte[65536];
        int count;
        while ((count = input.read(buffer)) != -1) hash.update(buffer, 0, count);
      }
      StringBuilder hex = new StringBuilder();
      for (byte value : hash.digest()) hex.append(String.format("%02x", value & 255));
      return hex.toString();
    } catch (NoSuchAlgorithmException error) {
      throw new IOException("SHA-256 is unavailable", error);
    }
  }

  private static void requireKey(String actual, String expected) {
    if (!actual.equals(expected)) throw new IllegalStateException("Media request identity changed");
  }
}
