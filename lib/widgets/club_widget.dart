import 'package:flutter/material.dart';

class ClubWidget extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback? onTap;

  const ClubWidget({required this.club, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final name = club['name'] ?? '';
    final city = club['city'] ?? '';
    final street = club['street'] ?? '';
    final logoUrl = club['mobileClubLogo'] ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                cacheWidth: 96,
                cacheHeight: 96,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      title: Text(name),
      subtitle: Text('$city, $street'),
      onTap: onTap,
    );
  }
}
