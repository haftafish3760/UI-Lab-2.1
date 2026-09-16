import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'application_host_controller.dart';

/// The loader cleans up failed attempts. Replacing a running application is
/// available only through its host controller while entry points are blocked.
class ApplicationStartupScreen extends StatefulWidget {
  const ApplicationStartupScreen({
    required this.load,
    this.onAbandoned,
    this.hostController,
    super.key,
  });
  final Future<Widget> Function() load;
  final Future<void> Function(Widget)? onAbandoned;
  final ApplicationHostController? hostController;
  @override
  State<ApplicationStartupScreen> createState() =>
      _ApplicationStartupScreenState();
}

class _ApplicationStartupScreenState extends State<ApplicationStartupScreen>
    with WidgetsBindingObserver {
  Widget? _application;
  bool _loading = false;
  bool _failed = false;
  bool _blocked = false;
  void Function()? _detachHost;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachHost();
    unawaited(_load());
  }

  void _attachHost() {
    _detachHost = widget.hostController?.attach(
      ApplicationHostAttachment(
        currentApplication: () => _application,
        blockEntryPoints: (blocked) {
          if (!mounted || _loading) {
            throw StateError('Host is not ready to switch.');
          }
          setState(() => _blocked = blocked);
        },
        settleView: _settleView,
        presentApplication: (application) async {
          if (!mounted || !_blocked || _loading) {
            throw StateError(
              'Block the ready host before replacing its application.',
            );
          }
          setState(() => _application = application);
          await _settleView();
        },
      ),
    );
  }

  Future<void> _settleView() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      throw StateError('Application host detached during presentation.');
    }
  }

  @override
  void didUpdateWidget(covariant ApplicationStartupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.hostController, widget.hostController)) {
      _detachHost?.call();
      _attachHost();
    }
  }

  @override
  Future<bool> didPopRoute() async => _blocked;
  @override
  Future<bool> didPushRoute(String route) async => _blocked;
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => _blocked;
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => _blocked;

  @override
  void dispose() {
    _detachHost?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || _blocked || _application != null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final application = await widget.load();
      if (mounted) {
        setState(() => _application = application);
      } else {
        await widget.onAbandoned?.call(application);
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing: _blocked,
    child: ExcludeFocus(
      excluding: _blocked,
      child: ExcludeSemantics(
        excluding: _blocked,
        child: _application ?? _startupView(),
      ),
    ),
  );

  Widget _startupView() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _failed
                        ? 'Unable to open Tame Your Biz'
                        : 'Tame Your Biz',
                    style: AppTheme.light.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_failed) ...[
                    const Text(
                      'Opening did not finish. Your local database has not been reset or replaced. You can retry opening it.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _load,
                      child: const Text('Retry opening'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
