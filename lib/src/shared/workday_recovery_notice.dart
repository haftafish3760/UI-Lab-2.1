import 'package:flutter/material.dart';
import '../data/workday/workday_persistence_session.dart';

/// A committed command can outlive a failed refresh. Recovery reloads local
/// state; it never replays a business command or assumes cloud availability.
class WorkdayRecoveryNotice extends StatefulWidget {
  const WorkdayRecoveryNotice({
    required this.session,
    required this.child,
    super.key,
  });
  final WorkdayPersistenceSession session;
  final Widget child;
  @override
  State<WorkdayRecoveryNotice> createState() => _WorkdayRecoveryNoticeState();
}

class _WorkdayRecoveryNoticeState extends State<WorkdayRecoveryNotice> {
  bool _reloading = false;
  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      await widget.session.reload();
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) => Column(
      children: [
        if (!widget.session.isReady)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.session.error ??
                            'Workday information is unavailable.',
                      ),
                      TextButton(
                        onPressed: _reloading ? null : _reload,
                        child: Text(
                          _reloading ? 'Reloading workday…' : 'Reload workday',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    ),
  );
}
