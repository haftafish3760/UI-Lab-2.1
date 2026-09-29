import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import 'operations_workspace.dart';

/// A document's overview is composed of bounded lanes of the same sections on
/// every size. Financial records and draft ownership stay with the caller.
class DocumentFormOverview extends StatelessWidget {
  const DocumentFormOverview({required this.groups, super.key});
  final List<List<Widget>> groups;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = AppLayoutEngine.workFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      return OperationsLaneGrid(
        layout: layout,
        children: [
          for (final group in groups)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final section in group)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: section,
                  ),
              ],
            ),
        ],
      );
    },
  );
}

class DocumentFormSection extends StatelessWidget {
  const DocumentFormSection({
    required this.title,
    required this.summary,
    required this.icon,
    this.onTap,
    this.borderColor,
    super.key,
  });
  final String title;
  final String summary;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor ?? colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 23, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Uses the owning editor's controllers and autosave session. Opening a section
/// never creates a second draft or financial record. Back retains working input.
class DocumentSectionEditor extends StatefulWidget {
  const DocumentSectionEditor({
    required this.title,
    required this.changes,
    required this.builder,
    required this.beforeClose,
    this.saveLabel = 'Done',
    this.onSave,
    this.errorMessage,
    this.onBackStep,
    super.key,
  });
  final String title;
  final String saveLabel;
  final Future<void> Function()? onSave;
  final String Function(Object)? errorMessage;
  final Listenable changes;
  final WidgetBuilder builder;
  final Future<void> Function() beforeClose;

  /// Returns true when an inline workflow handled Back without leaving the route.
  final Future<bool> Function()? onBackStep;

  @override
  State<DocumentSectionEditor> createState() => _DocumentSectionEditorState();
}

class _DocumentSectionEditorState extends State<DocumentSectionEditor> {
  bool _closing = false;
  bool _allowPop = false;

  Future<void> _close({bool save = false}) async {
    if (_closing) return;
    setState(() => _closing = true);
    try {
      if (!save && await widget.onBackStep?.call() == true) {
        if (mounted) setState(() => _closing = false);
        return;
      }
      await widget.beforeClose();
      if (save) await widget.onSave?.call();
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.errorMessage?.call(error) ??
                'Your latest changes could not be saved. Keep this form open and retry saving.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 32),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedBuilder(
                        animation: widget.changes,
                        builder: (context, _) => AbsorbPointer(
                          absorbing: _closing,
                          child: widget.builder(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.icon(
                          key: const ValueKey('document-section-done'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary,
                          ),
                          onPressed: _closing ? null : () => _close(save: true),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(widget.saveLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
