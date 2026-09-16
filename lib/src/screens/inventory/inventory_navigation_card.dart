import 'package:flutter/material.dart';
import '../../shared/section_card.dart';

/// The same enclosed, readable control at each level of the inventory tree.
class InventoryNavigationCard extends StatelessWidget {
  const InventoryNavigationCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.chevron_right,
    this.image,
    super.key,
  });
  final String title;
  final String? subtitle, image;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null) ...[
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 1.25,
                    child: Image.asset(
                      image!,
                      cacheWidth: 512,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => const SizedBox(
                        height: 92,
                        child: Icon(Icons.handyman_outlined, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 22),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
