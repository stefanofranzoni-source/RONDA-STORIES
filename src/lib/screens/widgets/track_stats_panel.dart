import 'package:flutter/material.dart';
import '../../models/track_stats.dart';
import '../../services/app_strings.dart';

/// Pannello che mostra in modo leggibile le statistiche correnti di
/// un'attività: tempo trascorso, distanza, velocità media e istantanea.
/// Widget "stateless e puro": riceve dati e li mostra, senza logica
/// propria — più semplice da riusare anche in altre schermate.
class TrackStatsPanel extends StatelessWidget {
  final TrackStats stats;
  final AppStrings strings;

  const TrackStatsPanel({super.key, required this.stats, required this.strings});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          icon: Icons.timer_outlined,
          label: strings.time,
          value: _formatDuration(stats.elapsed),
        ),
        _StatItem(
          icon: Icons.straighten,
          label: strings.distance,
          value: '${stats.distanceKm.toStringAsFixed(2)} km',
        ),
        _StatItem(
          icon: Icons.speed,
          label: strings.avgSpeed,
          value: '${stats.averageSpeedKmh.toStringAsFixed(1)} km/h',
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
