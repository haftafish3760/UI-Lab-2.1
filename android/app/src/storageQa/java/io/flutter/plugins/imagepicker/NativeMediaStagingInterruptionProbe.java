package io.flutter.plugins.imagepicker;

import android.app.Instrumentation;
import android.content.Context;
import android.database.Cursor;
import android.os.Bundle;
import android.os.Process;
import android.system.Os;
import android.system.OsConstants;
import java.io.File;
import java.io.FileDescriptor;
import java.nio.file.Files;
import java.util.Arrays;
import java.util.List;

/** Compiled only into STORAGE_QA debug APKs. Never opens normal app storage. */
public final class NativeMediaStagingInterruptionProbe extends Instrumentation {
  private Bundle arguments;
  @Override public void onCreate(Bundle arguments) {
    super.onCreate(arguments);
    this.arguments = arguments;
    start();
  }
  @Override public void onStart() {
    Bundle result = new Bundle();
    try {
      Context context = getTargetContext();
      require(context.getPackageName().equals("com.maintainiac.ui_lab_2_1.storageqa"),
          "Requires isolated QA package");
      String run = arguments.getString("run", "");
      require(run.matches("[A-Za-z0-9_-]{8,64}"), "Invalid run identity");
      String phase = arguments.getString("phase", "");
      require(phase.equals("write") || phase.equals("read"), "Invalid phase");
      String key = "staging-" + run;
      File marker = new File(context.getFilesDir(), run + ".started");
      File source = new File(context.getCacheDir(), run + ".jpg");
      byte[] original = new byte[] {2, 4, 6, 8};
      if (phase.equals("write")) {
        require(marker.createNewFile(), "Writer fixture already exists");
        Files.write(source.toPath(), original);
        try (DurableMediaResultJournal journal = new DurableMediaResultJournal(context, directory -> {
          FileDescriptor descriptor = null;
          try {
            descriptor = Os.open(directory.getPath(), OsConstants.O_RDONLY, 0);
            Os.fsync(descriptor);
          } catch (android.system.ErrnoException error) {
            throw new java.io.IOException(error);
          } finally {
            if (descriptor != null) {
              try { Os.close(descriptor); }
              catch (android.system.ErrnoException error) { throw new java.io.IOException(error); }
            }
          }
          android.util.Log.i("UILAB_STAGING_QA", "KILL_BEFORE_PUBLICATION " + run + " pid=" + Process.myPid());
          Process.killProcess(Process.myPid());
          throw new AssertionError("Process termination did not occur");
        })) {
          journal.begin(key);
          journal.storeResults(key, List.of(source.getPath()));
        }
        throw new AssertionError("Writer unexpectedly returned");
      }
      require(marker.exists() && source.isFile(), "Reader fixture missing");
      try (DurableMediaResultJournal journal = new DurableMediaResultJournal(context)) {
        File abandoned;
        try (Cursor rows = journal.getReadableDatabase().rawQuery("SELECT path FROM media_staging", null)) {
          require(rows.getCount() == 1 && rows.moveToFirst(), "Expected exactly one staged copy");
          abandoned = new File(rows.getString(0));
        }
        require(abandoned.isFile(), "Staged copy did not survive process termination");
        require(journal.read(key).isEmpty(), "Unpublished copy became ready");
        journal.begin(key);
        require(!abandoned.exists(), "Previous-process copy was not cleaned");
        require(android.database.DatabaseUtils.longForQuery(journal.getReadableDatabase(),
            "SELECT COUNT(*) FROM media_staging", null) == 0, "Staging ownership remains");
        require(Arrays.equals(original, Files.readAllBytes(source.toPath())), "Source changed");
        List<String> retry = journal.storeResults(key, List.of(source.getPath()));
        require(retry.equals(journal.read(key)), "Retry is not replayable");
        require(Arrays.equals(original, Files.readAllBytes(new File(retry.get(0)).toPath())), "Retry bytes changed");
        journal.acknowledge(key);
        require(!new File(retry.get(0)).exists(), "Acknowledged copy remains");
      }
      result.putString("result", "STAGING_INTERRUPTION_VERIFIED " + run);
      result.putInt("pid", Process.myPid());
      finish(-1, result);
    } catch (Throwable error) {
      result.putString("failure", error.toString());
      finish(0, result);
    }
  }
  private static void require(boolean condition, String message) {
    if (!condition) throw new AssertionError(message);
  }
}
