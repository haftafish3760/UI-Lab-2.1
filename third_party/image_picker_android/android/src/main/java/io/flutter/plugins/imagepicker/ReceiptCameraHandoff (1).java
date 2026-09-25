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

  public ReceiptCameraHandoff(Context context) throws IOException {
    this(context, new DurableMediaResultJournal(context));
  }

  // Package-local injection keeps JVM filesystem substitution out of the app API.
  ReceiptCameraHandoff(Context context, DurableMediaResultJournal journal) throws IOException {
    this.journal = journal;
    captureRoot = new File(context.getFilesDir().getCanonicalFile(), "receipt_camera");
  }

  public List<String> retain(String requestKey, List<String> originals)
      throws IOException, JSONException {
    if (requestKey == null || !requestKey.equals(journal.activeKey())) {
      throw new IllegalStateException("Receipt capture request is no longer active");
    }
    if (originals.isEmpty() || originals.size() > 8) {
      throw new IllegalArgumentException("Invalid receipt capture count");
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
