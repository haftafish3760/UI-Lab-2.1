package io.flutter.plugins.imagepicker;

import static org.junit.Assert.*;
import android.content.Context;
import androidx.test.core.app.ApplicationProvider;
import java.io.File;
import java.nio.file.Files;
import java.util.List;
import java.util.UUID;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public class NativeMediaStagingTest {
  private Context context;
  private DurableMediaResultJournal journal;
  @Before public void setUp() {
    context = ApplicationProvider.getApplicationContext();
    context.deleteDatabase("maintainiac_native_media.sqlite");
    journal = new DurableMediaResultJournal(context, directory -> {});
    journal.begin("request_one");
  }
  @After public void tearDown() {
    journal.close();
    context.deleteDatabase("maintainiac_native_media.sqlite");
  }
  private File partial() throws Exception {
    File root = new File(context.getFilesDir().getCanonicalFile(), "native_media_handoff");
    root.mkdirs();
    File file = new File(root, UUID.randomUUID() + ".jpg");
    NativeMediaStaging.register(journal.getWritableDatabase(), file);
    Files.write(file.toPath(), new byte[] {1});
    return file;
  }
  private long count() {
    return android.database.DatabaseUtils.longForQuery(journal.getReadableDatabase(),
        "SELECT COUNT(*) FROM media_staging", null);
  }
  private void markPreviousProcess() {
    // Models persisted ownership from a terminated process, not actual OS death.
    journal.getWritableDatabase().execSQL("UPDATE media_staging SET process_id='previous-process'");
  }
  @Test public void currentProcessCopySurvivesHelperReopen() throws Exception {
    File file = partial();
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    journal.begin("request_one");
    assertTrue(file.exists());
    assertEquals(1, count());
  }
  @Test public void previousProcessPartialRemainsRecoverable() throws Exception {
    File file = partial();
    markPreviousProcess();
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    journal.begin("request_one");
    assertArrayEquals(new byte[] {1}, Files.readAllBytes(file.toPath()));
    assertEquals(1, count());
    assertEquals("request_one", journal.activeKey());
    assertTrue(journal.read("request_one").isEmpty());
  }
  @Test public void reopeningPreservesPartialBytesAndOwnership() throws Exception {
    File file = partial();
    markPreviousProcess();
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> { fail("Reopen must not flush or delete photos"); });
    assertArrayEquals(new byte[] {1}, Files.readAllBytes(file.toPath()));
    assertEquals(1, count());
    journal.begin("request_one");
    assertEquals(1, count());
  }
  @Test public void publicationAndStagingRemovalAreAtomic() throws Exception {
    File source = new File(context.getCacheDir(), UUID.randomUUID() + ".jpg");
    Files.write(source.toPath(), new byte[] {2, 4, 6});
    journal.getWritableDatabase().execSQL("CREATE TRIGGER fail_ready BEFORE UPDATE ON handoff "
        + "WHEN NEW.state='ready' BEGIN SELECT RAISE(ABORT,'injected publication failure'); END");
    assertThrows(android.database.SQLException.class,
        () -> journal.storeResults("request_one", List.of(source.getPath())));
    assertEquals(1, count());
    assertTrue(journal.read("request_one").isEmpty());
    journal.getWritableDatabase().execSQL("DROP TRIGGER fail_ready");
    markPreviousProcess();
    journal.begin("request_one");
    assertEquals(1, count());
    List<String> copies = journal.storeResults("request_one", List.of(source.getPath()));
    assertEquals(1, count());
    assertEquals(copies, journal.read("request_one"));
    assertTrue(new File(copies.get(0)).exists());
  }

  @Test public void versionThreeUpgradePreservesReadyMedia() throws Exception {
    File source = new File(context.getCacheDir(), UUID.randomUUID() + ".jpg");
    Files.write(source.toPath(), new byte[] {5, 7, 9});
    List<String> copies = journal.storeResults("request_one", List.of(source.getPath()));
    journal.close();
    android.database.sqlite.SQLiteDatabase old = context.openOrCreateDatabase(
        "maintainiac_native_media.sqlite", 0, null);
    old.execSQL("DROP TABLE media_staging");
    old.execSQL("DROP TABLE receipt_captures");
    old.setVersion(3);
    old.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    journal.begin("request_one");
    assertEquals(5, journal.getReadableDatabase().getVersion());
    assertEquals(copies, journal.read("request_one"));
    assertEquals(0, count());
  }
}


