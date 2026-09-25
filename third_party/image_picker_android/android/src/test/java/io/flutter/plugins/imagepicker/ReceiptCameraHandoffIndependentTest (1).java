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
