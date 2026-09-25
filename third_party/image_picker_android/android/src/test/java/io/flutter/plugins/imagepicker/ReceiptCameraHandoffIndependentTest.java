package io.flutter.plugins.imagepicker;

import static org.junit.Assert.*;
import android.content.Context;
import androidx.test.core.app.ApplicationProvider;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.List;
import org.junit.Before;
import org.junit.After;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/** New acceptance cases: expected bytes and request ownership are declared here,
 * not imported from legacy fixtures or camera implementation diagnostics. */
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public class ReceiptCameraHandoffIndependentTest {
  private Context context;
  private DurableMediaResultJournal journal;
  private ReceiptCameraHandoff camera;
  private File photo;
  private final byte[] evidence = new byte[] {11, 23, 47, 89};

  @Before public void setup() throws Exception {
    context = ApplicationProvider.getApplicationContext();
    context.deleteDatabase("maintainiac_native_media.sqlite");
    journal = new DurableMediaResultJournal(context, directory -> {});
    camera = new ReceiptCameraHandoff(context, journal);
    File root = new File(context.getFilesDir(), "receipt_camera");
    assertTrue(root.isDirectory() || root.mkdirs());
    photo = new File(root, "independent.jpg");
    Files.write(photo.toPath(), evidence);
    journal.begin("receipt_expected");
  }

  @After public void close() { camera.close(); }

  @Test public void wrongRequestCannotClaimPhotoOrPublishResult() throws Exception {
    assertThrows(IllegalStateException.class,
        () -> camera.retain("receipt_different", List.of(photo.getPath())));
    assertTrue(journal.read("receipt_expected").isEmpty());
    assertArrayEquals(evidence, Files.readAllBytes(photo.toPath()));
  }

  @Test public void completedCaptureRecoversWithoutAnActivityResult() throws Exception {
    File planned = new File(photo.getParentFile(), "restart-" + java.util.UUID.randomUUID() + ".jpg");
    camera.plan("receipt_expected", planned.getPath());
    Files.write(planned.toPath(), evidence);
    camera.complete("receipt_expected", planned.getPath());
    camera.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    camera = new ReceiptCameraHandoff(context, journal);
    java.util.Map<String, Object> recovery = journal.prepareRecovery("receipt_expected");
    assertEquals(false, recovery.get("needsLegacyRecovery"));
    List<?> paths = (List<?>) recovery.get("paths");
    assertEquals(1, paths.size());
    assertArrayEquals(evidence, Files.readAllBytes(new File((String) paths.get(0)).toPath()));
    assertArrayEquals(evidence, Files.readAllBytes(planned.toPath()));
  }

  @Test public void partialCaptureCannotBePublishedOrConsumeLegacyPickerResult() throws Exception {
    File planned = new File(photo.getParentFile(), "partial-" + java.util.UUID.randomUUID() + ".jpg");
    camera.plan("receipt_expected", planned.getPath());
    Files.write(planned.toPath(), new byte[] {7});
    camera.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    camera = new ReceiptCameraHandoff(context, journal);
    java.util.Map<String, Object> recovery = journal.prepareRecovery("receipt_expected");
    assertEquals(false, recovery.get("needsLegacyRecovery"));
    assertTrue(((List<?>) recovery.get("paths")).isEmpty());
    assertArrayEquals(new byte[] {7}, Files.readAllBytes(planned.toPath()));
    assertEquals("receipt_expected", journal.activeKey());
  }

  @Test public void changedCompletedCaptureIsRejectedWithoutRewritingEvidence() throws Exception {
    File planned = new File(photo.getParentFile(), "changed-" + java.util.UUID.randomUUID() + ".jpg");
    camera.plan("receipt_expected", planned.getPath());
    Files.write(planned.toPath(), evidence);
    camera.complete("receipt_expected", planned.getPath());
    Files.write(planned.toPath(), new byte[] {99});
    assertThrows(IOException.class, () -> journal.prepareRecovery("receipt_expected"));
    assertThrows(IOException.class, () -> camera.complete("receipt_expected", planned.getPath()));
    assertTrue(journal.read("receipt_expected").isEmpty());
    assertArrayEquals(new byte[] {99}, Files.readAllBytes(planned.toPath()));
  }

  @Test public void duplicatePathNotRepeatedContent()
      throws Exception {
    assertThrows(IllegalArgumentException.class,
        () -> camera.retain("receipt_expected", List.of(photo.getPath(), photo.getPath())));
    File other = new File(photo.getParentFile(), "other-" + java.util.UUID.randomUUID() + ".jpg");
    Files.write(other.toPath(), evidence);
    assertEquals(2, camera.retain("receipt_expected", List.of(photo.getPath(), other.getPath())).size());
  }

  @Test public void publishedRequestCannotStartNewCapture() throws Exception {
    camera.retain("receipt_expected", List.of(photo.getPath()));
    File next = new File(photo.getParentFile(), "next-" + java.util.UUID.randomUUID() + ".jpg");
    assertThrows(IllegalStateException.class, () -> camera.plan("receipt_expected", next.getPath()));
    assertFalse(next.exists());
    assertEquals(1, journal.read("receipt_expected").size());
  }

  @Test public void versionFourUpgradePreservesPendingRequest() throws Exception {
    camera.close();
    assertTrue(context.deleteDatabase("maintainiac_native_media.sqlite"));
    android.database.sqlite.SQLiteDatabase old = context.openOrCreateDatabase(
        "maintainiac_native_media.sqlite", 0, null);
    old.execSQL("CREATE TABLE handoff (slot INTEGER PRIMARY KEY, request_key TEXT, state TEXT, paths TEXT)");
    old.execSQL("CREATE TABLE acknowledgements (request_key TEXT PRIMARY KEY NOT NULL)");
    old.execSQL("CREATE TABLE media_cleanup (request_key TEXT PRIMARY KEY NOT NULL, paths TEXT NOT NULL)");
    old.execSQL("CREATE TABLE media_staging (path TEXT PRIMARY KEY NOT NULL, process_id TEXT NOT NULL)");
    old.execSQL("INSERT INTO handoff VALUES(1,'receipt_expected','pending',NULL)");
    old.setVersion(4);
    old.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    camera = new ReceiptCameraHandoff(context, journal);
    assertEquals(5, journal.getReadableDatabase().getVersion());
    assertEquals("receipt_expected", journal.activeKey());
    File next = new File(photo.getParentFile(), "migrated-" + java.util.UUID.randomUUID() + ".jpg");
    camera.plan("receipt_expected", next.getPath());
    Files.write(next.toPath(), evidence);
    camera.complete("receipt_expected", next.getPath());
    assertEquals(1, ((List<?>) journal.prepareRecovery("receipt_expected").get("paths")).size());
  }

  @Test public void unrelatedPrivateFileAndTraversalAreRejected() throws Exception {
    File unrelated = new File(context.getFilesDir(), "unrelated.jpg");
    Files.write(unrelated.toPath(), evidence);
    assertThrows(IOException.class,
        () -> camera.retain("receipt_expected", List.of(unrelated.getPath())));
    File traversal = new File(photo.getParentFile(), "../unrelated.jpg");
    assertThrows(IOException.class,
        () -> camera.retain("receipt_expected", List.of(traversal.getPath())));
    assertTrue(journal.read("receipt_expected").isEmpty());
    assertArrayEquals(evidence, Files.readAllBytes(unrelated.toPath()));
  }

  @Test public void deliveredBytesSurviveReopenAndAcknowledgement() throws Exception {
    List<String> returned = camera.retain("receipt_expected", List.of(photo.getPath()));
    assertEquals(1, returned.size());
    assertNotEquals(photo.getPath(), returned.get(0));
    camera.close();
    journal = new DurableMediaResultJournal(context, directory -> {});
    camera = new ReceiptCameraHandoff(context, journal);
    assertEquals(returned, journal.read("receipt_expected"));
    assertArrayEquals(evidence, Files.readAllBytes(new File(returned.get(0)).toPath()));
    journal.acknowledge("receipt_expected");
    journal.begin("receipt_next");
    assertArrayEquals(evidence, Files.readAllBytes(photo.toPath()));
    assertArrayEquals(evidence, Files.readAllBytes(new File(returned.get(0)).toPath()));
    assertTrue(journal.read("receipt_expected").isEmpty());
    assertEquals("receipt_next", journal.activeKey());
  }

  @Test public void failedPublicationRetainsOriginalAndPartialCopy() throws Exception {
    camera.close();
    journal = new DurableMediaResultJournal(context, directory -> {
      throw new IOException("independent injected flush failure");
    });
    camera = new ReceiptCameraHandoff(context, journal);
    File root = new File(context.getFilesDir(), "native_media_handoff");
    int before = root.list() == null ? 0 : root.list().length;
    assertThrows(IOException.class,
        () -> camera.retain("receipt_expected", List.of(photo.getPath())));
    assertTrue(journal.read("receipt_expected").isEmpty());
    assertEquals(before + 1, root.list().length);
    assertArrayEquals(evidence, Files.readAllBytes(photo.toPath()));
  }
}
