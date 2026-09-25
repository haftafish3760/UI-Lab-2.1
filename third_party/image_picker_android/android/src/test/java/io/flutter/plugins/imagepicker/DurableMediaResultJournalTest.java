package io.flutter.plugins.imagepicker;

import static org.junit.Assert.*;
import android.content.Context;
import androidx.test.core.app.ApplicationProvider;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public class DurableMediaResultJournalTest {
  private Context context;
  private DurableMediaResultJournal journal;
  private int directoryFlushes;
  @Before public void setUp() {
    context = ApplicationProvider.getApplicationContext();
    context.deleteDatabase("maintainiac_native_media.sqlite");
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
  }
  @After public void tearDown() {
    journal.close();
    context.deleteDatabase("maintainiac_native_media.sqlite");
  }
  @Test public void overlappingHelpersKeepFirstPublishedResult() throws Exception {
    File first = new File(context.getCacheDir(), "first-race.jpg");
    File second = new File(context.getCacheDir(), "second-race.jpg");
    Files.write(first.toPath(), new byte[] {1, 2, 3});
    Files.write(second.toPath(), new byte[] {4, 5, 6});
    java.util.concurrent.atomic.AtomicReference<List<String>> winner =
        new java.util.concurrent.atomic.AtomicReference<>();
    try (DurableMediaResultJournal competing = new DurableMediaResultJournal(context, d -> {})) {
      journal.close();
      journal = new DurableMediaResultJournal(context, directory -> {
        if (winner.get() == null) {
          try {
            winner.set(competing.storeResults("overlapping_request", List.of(second.getPath())));
          } catch (Exception failure) {
            throw new java.io.IOException(failure);
          }
        }
      });
      journal.begin("overlapping_request");
      List<String> returned = journal.storeResults("overlapping_request", List.of(first.getPath()));
      assertEquals(winner.get(), returned);
      assertEquals(winner.get(), competing.read("overlapping_request"));
      assertArrayEquals(new byte[] {4, 5, 6}, Files.readAllBytes(new File(returned.get(0)).toPath()));
    }
  }

  @Test public void retainedResultsReplayAfterReopenAndSourceRemoval() throws Exception {
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "source.jpg");
    try (FileOutputStream output = new FileOutputStream(source)) {
      output.write(new byte[] {2, 4, 8});
      output.getFD().sync();
    }
    List<String> retained = journal.storeResults("request_one", List.of(source.getPath()));
    assertEquals(2, directoryFlushes);
    journal.close();
    assertTrue(source.delete());
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    assertEquals(retained, journal.read("request_one"));
    assertEquals(retained, journal.read("request_one"));
    assertArrayEquals(new byte[] {2, 4, 8}, Files.readAllBytes(new File(retained.get(0)).toPath()));
    journal.acknowledge("request_one");
    assertArrayEquals(new byte[] {2, 4, 8}, Files.readAllBytes(new File(retained.get(0)).toPath()));
    journal.acknowledge("request_one");
    assertTrue(journal.read("request_one").isEmpty());
    journal.begin("request_two");
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    journal.acknowledge("request_one");
    assertTrue(journal.read("request_one").isEmpty());
    assertEquals("request_two", journal.activeKey());
    assertEquals(false, journal.prepareRecovery("request_one").get("needsLegacyRecovery"));
    assertThrows(IllegalStateException.class, () -> journal.begin("request_one"));
    assertTrue(journal.read("request_two").isEmpty());
  }
  @Test public void versionOneUpgradePreservesAcknowledgementAcrossNewRequest() throws Exception {
    journal.close();
    context.deleteDatabase("maintainiac_native_media.sqlite");
    android.database.sqlite.SQLiteDatabase old = context.openOrCreateDatabase(
        "maintainiac_native_media.sqlite", 0, null);
    old.execSQL("CREATE TABLE handoff (slot INTEGER PRIMARY KEY CHECK(slot=1), "
        + "request_key TEXT NOT NULL, state TEXT NOT NULL, paths TEXT)");
    old.execSQL("INSERT INTO handoff VALUES(1,'request_old','acknowledged',NULL)");
    old.setVersion(1);
    old.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    assertEquals(5, journal.getReadableDatabase().getVersion());
    journal.begin("request_new");
    journal.acknowledge("request_old");
    assertEquals("request_new", journal.activeKey());
    assertTrue(journal.read("request_old").isEmpty());
    assertThrows(IllegalStateException.class, () -> journal.acknowledge("request_unknown"));
  }

  @Test public void legacyRecoveryPreparationBindsOnlyTheRequestedIdentity() throws Exception {
    assertEquals(true, journal.prepareRecovery("request_old").get("needsLegacyRecovery"));
    assertEquals("request_old", journal.activeKey());
    assertThrows(IllegalStateException.class, () -> journal.prepareRecovery("request_other"));
    assertEquals("request_old", journal.activeKey());
  }

  @Test public void explicitAbandonRetiresPendingIdentityWithoutTouchingNewRequest() throws Exception {
    journal.begin("request_cancelled");
    journal.abandon("request_cancelled");
    journal.begin("request_new");
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    journal.abandon("request_cancelled");
    assertEquals("request_new", journal.activeKey());
    assertThrows(IllegalStateException.class, () -> journal.abandon("request_wrong"));
    assertEquals("request_new", journal.activeKey());
  }

  @Test public void pendingRequestCannotBeOverwrittenOrAcknowledged() throws Exception {
    journal.begin("request_one");
    journal.begin("request_one");
    assertThrows(IllegalStateException.class, () -> journal.begin("request_two"));
    assertThrows(IllegalStateException.class, () -> journal.read("request_two"));
    assertThrows(IllegalStateException.class, () -> journal.acknowledge("request_one"));
    assertTrue(journal.read("request_one").isEmpty());
  }
  @Test public void sameLengthCorruptionIsRejectedWithoutClearingReplay() throws Exception {
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "integrity.jpg");
    Files.write(source.toPath(), new byte[] {1, 2, 3});
    List<String> retained = journal.storeResults("request_one", List.of(source.getPath()));
    File copy = new File(retained.get(0));
    Files.write(copy.toPath(), new byte[] {9, 9, 9});
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    assertThrows(java.io.IOException.class, () -> journal.read("request_one"));
    // A failed integrity check keeps the original manifest for repair/recovery.
    Files.write(copy.toPath(), new byte[] {1, 2, 3});
    assertEquals(retained, journal.read("request_one"));
  }

  @Test public void directoryFlushFailurePreventsPublication() throws Exception {
    java.util.Set<String> before = handoffFiles();
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> {
      throw new java.io.IOException("injected directory flush failure");
    });
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "flush.jpg");
    Files.write(source.toPath(), new byte[] {1, 2, 3});
    assertThrows(java.io.IOException.class,
        () -> journal.storeResults("request_one", List.of(source.getPath())));
    assertTrue(journal.read("request_one").isEmpty());
    assertThrows(IllegalStateException.class, () -> journal.acknowledge("request_one"));
    assertTrue(handoffFiles().containsAll(before));
    assertEquals(before.size() + 1, handoffFiles().size());
    assertTrue(source.isFile());
  }

  @Test public void laterMissingSourcePreservesUnpublishedCopies() throws Exception {
    java.util.Set<String> before = handoffFiles();
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "first.jpg");
    Files.write(source.toPath(), new byte[] {3, 5, 7});
    File missing = new File(context.getCacheDir(), "absent-second.jpg");
    assertThrows(java.io.IOException.class, () -> journal.storeResults(
        "request_one", List.of(source.getPath(), missing.getPath())));
    assertTrue(handoffFiles().containsAll(before));
    assertEquals(before.size() + 1, handoffFiles().size());
    assertArrayEquals(new byte[] {3, 5, 7}, Files.readAllBytes(source.toPath()));
    assertTrue(journal.read("request_one").isEmpty());
    List<String> retry = journal.storeResults("request_one", List.of(source.getPath()));
    assertEquals(retry, journal.read("request_one"));
  }

  private java.util.Set<String> handoffFiles() {
    String[] names = new File(context.getFilesDir(), "native_media_handoff").list();
    return names == null ? new java.util.HashSet<>()
        : new java.util.HashSet<>(java.util.Arrays.asList(names));
  }

  @Test public void acknowledgedFilesSurviveReopenAndNewRequest() throws Exception {
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "cleanup.jpg");
    Files.write(source.toPath(), new byte[] {7, 8, 9});
    List<String> copies = journal.storeResults("request_one", List.of(source.getPath()));
    assertTrue(journal.cleanAcknowledgedCopies());
    assertTrue(new File(copies.get(0)).exists()); // No acknowledgement yet.
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> {
      throw new java.io.IOException("injected cleanup flush failure");
    });
    journal.acknowledge("request_one");
    assertEquals(1, cleanupCount());
    assertTrue(journal.read("request_one").isEmpty());
    journal.begin("request_two");
    assertEquals(1, cleanupCount());
    journal.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    assertTrue(journal.cleanAcknowledgedCopies());
    assertEquals(1, cleanupCount());
    assertArrayEquals(new byte[] {7, 8, 9}, Files.readAllBytes(new File(copies.get(0)).toPath()));
    assertEquals("request_two", journal.activeKey());
    assertArrayEquals(new byte[] {7, 8, 9}, Files.readAllBytes(source.toPath()));
  }

  @Test public void versionTwoMediaSurvivesUpgradeAndAcknowledgement() throws Exception {
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "upgrade.jpg");
    Files.write(source.toPath(), new byte[] {9, 3, 1});
    List<String> copies = journal.storeResults("request_one", List.of(source.getPath()));
    journal.close();
    android.database.sqlite.SQLiteDatabase old = context.openOrCreateDatabase(
        "maintainiac_native_media.sqlite", 0, null);
    old.execSQL("DROP TABLE media_cleanup");
    old.execSQL("DROP TABLE media_staging");
    old.execSQL("DROP TABLE receipt_captures");
    old.setVersion(2);
    old.close();
    journal = new DurableMediaResultJournal(context, directory -> { directoryFlushes++; });
    assertEquals(copies, journal.read("request_one"));
    assertEquals(5, journal.getReadableDatabase().getVersion());
    journal.acknowledge("request_one");
    assertArrayEquals(Files.readAllBytes(source.toPath()), Files.readAllBytes(new File(copies.get(0)).toPath()));
    assertEquals(1, cleanupCount());
    assertTrue(source.isFile());
  }

  @Test public void acknowledgementPreservesOutsidePaths() throws Exception {
    File outside = new File(context.getFilesDir(), "keep.jpg");
    Files.write(outside.toPath(), new byte[] {1, 9});
    String manifest = new org.json.JSONArray().put(new org.json.JSONObject()
        .put("path", outside.getPath())).toString();
    journal.getWritableDatabase().execSQL(
        "INSERT INTO acknowledgements VALUES('request_old')");
    journal.getWritableDatabase().execSQL(
        "INSERT INTO media_cleanup VALUES('request_old',?)", new Object[] {manifest});
    assertTrue(journal.cleanAcknowledgedCopies());
    assertEquals(1, cleanupCount());
    assertArrayEquals(new byte[] {1, 9}, Files.readAllBytes(outside.toPath()));
  }

  private long cleanupCount() {
    return android.database.DatabaseUtils.longForQuery(
        journal.getReadableDatabase(), "SELECT COUNT(*) FROM media_cleanup", null);
  }

  @Test public void failedAcknowledgementRollsBackCleanupOwnershipAndRetainsReplay() throws Exception {
    journal.begin("request_one");
    File source = new File(context.getCacheDir(), "rollback.jpg");
    Files.write(source.toPath(), new byte[] {4, 6, 8});
    List<String> copies = journal.storeResults("request_one", List.of(source.getPath()));
    journal.getWritableDatabase().execSQL("CREATE TRIGGER fail_ack BEFORE INSERT ON acknowledgements "
        + "BEGIN SELECT RAISE(ABORT, 'injected acknowledgement failure'); END");
    assertThrows(android.database.SQLException.class, () -> journal.acknowledge("request_one"));
    assertEquals(0, cleanupCount());
    assertEquals(copies, journal.read("request_one"));
    assertTrue(journal.cleanAcknowledgedCopies());
    assertTrue(new File(copies.get(0)).isFile());
    journal.getWritableDatabase().execSQL("DROP TRIGGER fail_ack");
    journal.acknowledge("request_one");
    assertArrayEquals(Files.readAllBytes(source.toPath()), Files.readAllBytes(new File(copies.get(0)).toPath()));
  }

  @Test public void missingSourceNeverPublishesAReadyResult() throws Exception {
    journal.begin("request_one");
    File missing = new File(context.getCacheDir(), "missing.jpg");
    assertThrows(java.io.IOException.class,
        () -> journal.storeResults("request_one", List.of(missing.getPath())));
    assertTrue(journal.read("request_one").isEmpty());
    assertThrows(IllegalStateException.class, () -> journal.acknowledge("request_one"));
  }
}

