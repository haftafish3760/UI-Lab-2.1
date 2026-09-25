part of 'receipt_image_processor.dart';

class _ReceiptStitchIsolateMessage {
  const _ReceiptStitchIsolateMessage({
    required this.request,
    required this.resultPort,
  });

  final _ReceiptStitchRequest request;
  final SendPort resultPort;
}

Future<void> _receiptStitchIsolateEntry(
  _ReceiptStitchIsolateMessage message,
) async {
  final result = await _runReceiptStitchInBackground(message.request);
  message.resultPort.send(result);
}

Future<ReceiptStitchResult> _runReceiptStitchInManagedIsolate({
  required _ReceiptStitchRequest request,
  required Duration? processingTimeout,
  required String timeoutReasonCode,
  required String timeoutWarning,
  bool Function()? shouldCancel,
}) async {
  final resultPort = ReceivePort();
  final exitPort = ReceivePort();
  final exitSignal = Completer<void>();
  final exitSubscription = exitPort.listen((_) {
    if (!exitSignal.isCompleted) exitSignal.complete();
  });
  final exited = exitSignal.future;
  Timer? cancellationMonitor;
  Isolate? isolate;
  try {
    if (shouldCancel?.call() ?? false) {
      return ReceiptStitchResult.fallback(
        inputPaths: request.paths,
        warning: 'Processing paused. Your receipt photos are retained.',
        fallbackReasonCode: 'stitch_cancelled',
      );
    }
    isolate = await Isolate.spawn(
      _receiptStitchIsolateEntry,
      _ReceiptStitchIsolateMessage(
        request: request,
        resultPort: resultPort.sendPort,
      ),
      onError: resultPort.sendPort,
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
      debugName: 'maintainiac-receipt-stitch',
    );
    final cancelled = Completer<Object?>();
    if (shouldCancel != null) {
      cancellationMonitor = Timer.periodic(const Duration(milliseconds: 100), (
        _,
      ) {
        if (shouldCancel() && !cancelled.isCompleted) {
          isolate?.kill(priority: Isolate.immediate);
          cancelled.complete('cancelled');
        }
      });
    }
    final responseFuture = Future.any<Object?>([
      resultPort.first,
      cancelled.future,
      exited.then((_) async {
        // Give the result port its turn after the worker's final send.
        await Future<void>.delayed(Duration.zero);
        return null;
      }),
    ]);
    final response = processingTimeout == null
        ? await responseFuture
        : await responseFuture.timeout(processingTimeout);
    if (response is ReceiptStitchResult) return response;
    if (response == 'cancelled') {
      return ReceiptStitchResult.fallback(
        inputPaths: request.paths,
        warning: 'Processing paused. Your receipt photos are retained.',
        fallbackReasonCode: 'stitch_cancelled',
      );
    }
    // Retain partial artifacts; deletion requires explicit user confirmation.
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning:
          'Receipt photos could not be combined safely. Receipt details will use them from top to bottom.',
      fallbackReasonCode: 'stitch_isolate_failed',
    );
  } on TimeoutException {
    isolate?.kill(priority: Isolate.immediate);
    await Future<void>.delayed(Duration.zero);
    // Retain partial artifacts; deletion requires explicit user confirmation.
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning: timeoutWarning,
      fallbackReasonCode: timeoutReasonCode,
    );
  } catch (_) {
    // Retain partial artifacts; deletion requires explicit user confirmation.
    return ReceiptStitchResult.fallback(
      inputPaths: request.paths,
      warning:
          'Receipt photos could not be combined safely. Receipt details will use them from top to bottom.',
      fallbackReasonCode: 'stitch_isolate_failed',
    );
  } finally {
    cancellationMonitor?.cancel();
    isolate?.kill(priority: Isolate.immediate);
    // Do not release the shared workload slot while a worker can still run.
    if (isolate != null) await exited;
    resultPort.close();
    await exitSubscription.cancel();
    exitPort.close();
  }
}
