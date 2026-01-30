import 'package:flutter/material.dart';
import '../models/booster_model.dart';
import '../config/theme.dart';
import 'booster_card.dart';

class GameControls extends StatelessWidget {
  final List<BoosterModel> boosters;
  final String? selectedBooster;
  final Function(String) onBoosterTap;
  
  const GameControls({
    Key? key,
    required this.boosters,
    required this.selectedBooster,
    required this.onBoosterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border(
          top: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Boosters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: boosters.map((booster) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: BoosterCard(
                    icon: booster.icon,
                    name: booster.displayName,
                    count: booster.quantity,
                    isSelected: selectedBooster == booster.boosterType,
                    onTap: () => onBoosterTap(booster.boosterType),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}