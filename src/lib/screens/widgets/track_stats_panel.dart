import 'package:flutter/material.dart';
import '../../models/track_stats.dart';
import '../../services/app_strings.dart';

class TrackStatsPanel extends StatelessWidget {
  final TrackStats stats;
  final AppStrings strings;

  const TrackStatsPanel({super.key, required this.stats, required this.strings});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.timer_outlined,
            label: strings.time,
            value: _formatDuration(stats.elapsed),
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.straighten,
            label: strings.distance,
            // Passa automaticamente a formato più compatto oltre 10 km
            value: stats.distanceKm >= 10
                ? '${stats.distanceKm.toStringAsFixed(1)} km'
                : '${stats.distanceKm.toStringAsFixed(2)} km',
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.speed,
            label: strings.avgSpeed,
            value: '${stats.averageSpeedKmh.toStringAsFixed(1)} km/h',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
