package io.flutter.plugins.imagepicker;

import android.content.Context;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMethodCodec;

/** Request-keyed internal protocol; no filesystem paths supplied by Dart. */
final class DurableMediaJournalChannel {
  final DurableMediaResultJournal journal;
  private final MethodChannel channel;

  DurableMediaJournalChannel(Context context, BinaryMessenger messenger) {
    journal = new DurableMediaResultJournal(context);
    channel = new MethodChannel(messenger, "maintainiac/native_media_journal",
        StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue());
    channel.setMethodCallHandler((call, result) -> {
      try {
        if (!(call.arguments instanceof String)) {
          throw new IllegalArgumentException("Media request identity is required");
        }
        String key = (String) call.arguments;
        switch (call.method) {
          case "begin": journal.begin(key); result.success(null); break;
          case "recover": result.success(journal.prepareRecovery(key)); break;
          case "abandon": journal.abandon(key); result.success(null); break;
          case "acknowledge": journal.acknowledge(key); result.success(null); break;
          default: result.notImplemented();
        }
      } catch (Exception error) {
        // Do not disclose private paths or payloads through platform errors.
        result.error("native_media_journal_failed", "Native media handoff unavailable", null);
      }
    });
  }

  void detach() {
    channel.setMethodCallHandler(null);
    journal.close();
  }
}
