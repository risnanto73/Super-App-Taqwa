import 'package:flutter/material.dart';

class HeirInputCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const HeirInputCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.min = 0,
    this.max = 99,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PoppinsSemiBold',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'PoppinsRegular',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildActionButton(
                  Icons.remove,
                  value > min ? () => onChanged(value - 1) : null,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      fontFamily: 'PoppinsBold',
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildActionButton(
                  Icons.add,
                  value < max ? () => onChanged(value + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onPressed != null
              ? Colors.amber.withAlpha(25)
              : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? Colors.amber : Colors.grey[400],
        ),
      ),
    );
  }
}
