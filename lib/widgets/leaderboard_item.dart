import 'package:flutter/material.dart';
import '../config/theme.dart';

class LeaderboardItem extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final String? medal;
  final bool highlight;
  
  const LeaderboardItem({
    Key? key,
    required this.rank,
    required this.name,
    required this.score,
    this.medal,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.blue : AppColors.gray200,
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: AppColors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank/Medal
          SizedBox(
            width: 40,
            child: Text(
              medal ?? '#$rank',
              style: TextStyle(
                fontSize: medal != null ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.blue : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
          
          // Score
          Text(
            '$score pts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}