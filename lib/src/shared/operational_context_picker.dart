part of 'operational_header.dart';

/// Adapts the protected 5.7 picker presentation. It returns an option only;
/// the existing operational controller remains the owner of selected scope.
class _OperationalContextPicker extends StatelessWidget {
  const _OperationalContextPicker({required this.header});
  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('operational-context-picker'),
    backgroundColor: AppColors.headerControl,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppLayoutEngine.singleMaximum,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.selectVehicleLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onHeader,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in header.contextOptions) ...[
              _ContextPickerOption(
                option: option,
                selected: option.id == header.selectedContext.id,
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                MaterialLocalizations.of(context).closeButtonLabel,
                style: const TextStyle(color: AppColors.onHeader),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContextPickerOption extends StatelessWidget {
  const _ContextPickerOption({required this.option, required this.selected});
  final OperationalHeaderContextOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      key: ValueKey('context-picker-option-${option.id}'),
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [AppColors.pickerBlue, AppColors.pickerBlueDeep]
                : const [AppColors.headerControl, AppColors.headerControlAlt],
          ),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(
            color: selected ? const Color(0xFF65B8FF) : AppColors.headerBorder,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.pop(context, option),
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.localizedTitle(context.l10n),
                          style: const TextStyle(
                            color: AppColors.onHeader,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (option.detail case final detail?) ...[
                          const SizedBox(height: 3),
                          Text(
                            detail,
                            style: const TextStyle(
                              color: AppColors.onHeaderMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_rounded, color: AppColors.onHeader),
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
