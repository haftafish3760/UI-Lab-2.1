import 'dart:async';
import 'package:flutter/material.dart';
import '../data/storage/draft_recovery_catalog.dart';
import '../data/storage/draft_recovery_hub.dart';
import '../layout/app_layout_engine.dart';
import '../shared/application_recovery_release.dart';
import '../shared/draft_recovery_controller.dart';

/// Presentation of service-owned summaries. Neither list positions nor widget
/// structure become saved workflow identities.
class SavedWorkRecoveryScreen extends StatefulWidget {
  const SavedWorkRecoveryScreen({
    required this.hub,
    required this.onResume,
    super.key,
  });
  final DraftRecoveryHub<Object> hub;
  final Future<void> Function(BuildContext, Object) onResume;
  @override
  State<SavedWorkRecoveryScreen> createState() =>
      _SavedWorkRecoveryScreenState();
}

class _SavedWorkRecoveryScreenState extends State<SavedWorkRecoveryScreen> {
  late final DraftRecoveryController<Object> _controller =
      createApplicationRecoveryController(widget.hub);
  bool _opening = false;
  String? _routeError;
  @override
  void initState() {
    super.initState();
    unawaited(_controller.refresh());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resume(RecoveryHubEntry<Object> entry) async {
    if (_opening || _controller.isBusy) return;
    setState(() {
      _opening = true;
      _routeError = null;
    });
    final workflow = await _controller.resume(entry);
    try {
      if (workflow == null) return;
      if (!mounted) return;
      await widget.onResume(context, workflow);
    } on Object {
      if (mounted) {
        setState(
          () => _routeError =
              'Saved work could not be opened. Refresh and try again.',
        );
      }
    } finally {
      try {
        if (workflow != null) await releaseApplicationRecovery(workflow);
      } on Object {
        if (mounted) {
          setState(
            () => _routeError =
                'Some recent changes could not be saved. The last saved draft is retained.',
          );
        }
      }
      if (mounted) {
        setState(() => _opening = false);
        if (workflow != null) await _controller.refresh();
      }
    }
  }

  Future<void> _discard(RecoveryHubEntry<Object> entry) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished input?'),
        content: Text(
          'Discard ${entry.title}? Confirmed records stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep input'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (mounted && accepted == true) await _controller.discard(entry);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final listing = _controller.listing;
      final busy = _opening || _controller.isBusy;
      return Scaffold(
        appBar: AppBar(title: const Text('Saved work')),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return SingleChildScrollView(
              padding: insets,
              child: Center(
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Continue unfinished work saved on this device. Opening it does not submit or approve it.',
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: busy ? null : _controller.refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh saved work'),
                        ),
                      ),
                      if (_controller.isLoading)
                        const LinearProgressIndicator(),
                      if (_controller.error != null) Text(_controller.error!),
                      if (_routeError != null) Text(_routeError!),
                      if (listing != null && !listing.isComplete)
                        Text(
                          'Some saved work could not be checked: ${listing.unavailableProviders.map((p) => p.label).join(', ')}. Try refreshing.',
                        ),
                      if (listing != null &&
                          listing.isComplete &&
                          listing.entries.isEmpty)
                        const Text('No unfinished work found.'),
                      for (final entry
                          in listing?.entries ?? <RecoveryHubEntry<Object>>[])
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(entry.workflowLabel),
                                Text(_availability(entry.availability)),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    TextButton(
                                      onPressed:
                                          busy ||
                                              entry.availability !=
                                                  DraftRecoveryAvailability
                                                      .recoverable
                                          ? null
                                          : () => _resume(entry),
                                      child: const Text('Continue'),
                                    ),
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => _discard(entry),
                                      child: const Text('Discard input'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

String _availability(DraftRecoveryAvailability value) => switch (value) {
  DraftRecoveryAvailability.recoverable => 'Ready to continue',
  DraftRecoveryAvailability.parentUnavailable =>
    'The related record is unavailable. Input is retained.',
  DraftRecoveryAvailability.conflict =>
    'The related record changed. Input is retained for review.',
  DraftRecoveryAvailability.unreadable =>
    'This input cannot currently be read. It has been retained.',
  DraftRecoveryAvailability.unavailable =>
    'This workflow is currently unavailable. Input is retained.',
};
