package io.flutter.plugins.imagepicker;

import android.content.Context;
import java.io.Closeable;
import java.io.File;
import java.io.IOException;
import java.util.List;
import org.json.JSONException;

/** Narrow native-camera adapter to the same request-keyed SQLite media journal.
 * The Flutter coordinator must persist and begin the request before launch.
 * Camera results are copied and verified before Android delivers them to Dart.
 */
public final class ReceiptCameraHandoff implements Closeable {
  private final DurableMediaResultJournal journal;
  private final File captureRoot;
  private final Context context;

  public ReceiptCameraHandoff(Context context) throws IOException {
    this(context, new DurableMediaResultJournal(context));
  }

  // Package-local injection keeps JVM filesystem substitution out of the app API.
  ReceiptCameraHandoff(Context context, DurableMediaResultJournal journal) throws IOException {
    this.journal = journal;
    this.context = context.getApplicationContext();
    captureRoot = new File(context.getFilesDir().getCanonicalFile(), "receipt_camera");
  }

  public void plan(String requestKey, String path) throws IOException {
    android.database.sqlite.SQLiteDatabase db = journal.getWritableDatabase();
    db.beginTransaction();
    try {
      requireActive(requestKey);
      try (android.database.Cursor state = db.rawQuery(
          "SELECT state FROM handoff WHERE slot=1 AND request_key=?", new String[] {requestKey})) {
        if (!state.moveToFirst() || !"pending".equals(state.getString(0))) {
          throw new IllegalStateException("Capture result has already been published");
        }
      }
      NativeReceiptCaptureLedger.plan(db, context, requestKey, path);
      db.setTransactionSuccessful();
    } finally { db.endTransaction(); }
  }

  public void complete(String requestKey, String path) throws IOException {
    File file = NativeReceiptCaptureLedger.validate(context, path);
    journal.flushCaptureDirectory(file);
    android.database.sqlite.SQLiteDatabase db = journal.getWritableDatabase();
    db.beginTransaction();
    try {
      requireActive(requestKey);
      NativeReceiptCaptureLedger.complete(db, context, requestKey, path);
      db.setTransactionSuccessful();
    } finally { db.endTransaction(); }
  }

  private void requireActive(String requestKey) {
    if (requestKey == null || !requestKey.equals(journal.activeKey())) {
      throw new IllegalStateException("Receipt capture request is no longer active");
    }
  }

  public java.util.Map<String, Object> recover(String requestKey) throws IOException, JSONException {
    requireActive(requestKey);
    java.util.Map<String, Object> result = journal.prepareRecovery(requestKey);
    result.put("hasCameraCapture", NativeReceiptCaptureLedger.hasRequest(
        journal.getReadableDatabase(), requestKey));
    return result;
  }

  public List<String> retain(String requestKey, List<String> originals)
      throws IOException, JSONException {
    requireActive(requestKey);
    if (originals.isEmpty() || originals.size() > 8) {
      throw new IllegalArgumentException("Invalid receipt capture count");
    }
    if (new java.util.HashSet<>(originals).size() != originals.size()) {
      throw new IllegalArgumentException("The same capture was supplied more than once");
    }
    for (String path : originals) {
      File file = new File(path);
      if (!file.isAbsolute() || !file.getCanonicalFile().equals(file.getAbsoluteFile())
          || !captureRoot.equals(file.getParentFile())) {
        throw new IOException("Receipt capture is outside its owned directory");
      }
    }
    return journal.storeResults(requestKey, originals);
  }

  @Override public void close() { journal.close(); }
}
