import 'package:flutter/material.dart';
import 'section_card.dart';

/// Shared section identity for business forms; color always accompanies words.
enum BusinessFormIdentity { company, customer }

class BusinessFormSection extends StatelessWidget {
  const BusinessFormSection({
    required this.title,
    required this.child,
    this.identity = BusinessFormIdentity.company,
    super.key,
  });
  final String title;
  final Widget child;
  final BusinessFormIdentity identity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final company = identity == BusinessFormIdentity.company;
    final accent = company ? colors.primary : colors.tertiary;
    return SectionCard(
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: colors.brightness == Brightness.dark ? .30 : .16,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      backgroundColor: Color.alphaBlend(
        accent.withValues(
          alpha: colors.brightness == Brightness.dark ? .10 : .04,
        ),
        colors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                company ? Icons.business_outlined : Icons.person_outline,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
