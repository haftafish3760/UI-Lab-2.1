part of 'dashboard_screen.dart';

int? _parseWorkdayOdometerTenths(String text) {
  final value = double.tryParse(text.replaceAll(',', '').trim());
  if (value == null || value.isNegative || value > 9999999) return null;
  return (value * 10).round();
}

class _EndWorkdayDialog extends StatefulWidget {
  const _EndWorkdayDialog({
    required this.initialOdometerTenths,
    required this.minimumOdometerTenths,
  });

  final int initialOdometerTenths;
  final int minimumOdometerTenths;

  @override
  State<_EndWorkdayDialog> createState() => _EndWorkdayDialogState();
}

class _EndWorkdayDialogState extends State<_EndWorkdayDialog> {
  late final _controller = TextEditingController(
    text: formatOdometerTenths(widget.initialOdometerTenths),
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('End workday'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter the physical ending odometer before closing today’s workday.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('ending-odometer-field'),
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Ending odometer',
              suffixText: 'mi',
              errorText: _errorText,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Keep workday open'),
      ),
      FilledButton(
        key: const ValueKey('confirm-end-workday-button'),
        onPressed: _submit,
        child: const Text('End workday'),
      ),
    ],
  );

  void _submit() {
    final reading = _parseWorkdayOdometerTenths(_controller.text);
    if (reading == null || reading < widget.minimumOdometerTenths) {
      setState(
        () => _errorText =
            'Enter an ending odometer at or above the starting reading.',
      );
      return;
    }
    Navigator.of(context).pop(reading);
  }
}
