import 'package:flutter/material.dart';
import '../config/theme.dart';

class NumberPad extends StatelessWidget {
  final Function(int)? onNumberTap;
  final bool isNoteMode;
  final List<List<int>> grid; // NOUVEAU : pour compter les chiffres
  
  const NumberPad({
    Key? key,
    this.onNumberTap,
    this.isNoteMode = false,
    required this.grid, // NOUVEAU
  }) : super(key: key);
  
  // Compter combien de fois un chiffre apparaît dans la grille
  int _countNumber(int number) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == number) {
          count++;
        }
      }
    }
    return count;
  }
  
  // Vérifier si un chiffre est complété (9 fois)
  bool _isNumberComplete(int number) {
    return _countNumber(number) >= 9;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final number = index + 1;
              final isComplete = _isNumberComplete(number);
              final count = _countNumber(number);
              
              return _NumberButton(
                number: number,
                onTap: isComplete ? null : () => onNumberTap?.call(number),
                isNoteMode: isNoteMode,
                isComplete: isComplete,
                count: count,
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(4, (index) {
                final number = index + 6;
                final isComplete = _isNumberComplete(number);
                final count = _countNumber(number);
                
                return _NumberButton(
                  number: number,
                  onTap: isComplete ? null : () => onNumberTap?.call(number),
                  isNoteMode: isNoteMode,
                  isComplete: isComplete,
                  count: count,
                );
              }),
              _NumberButton(
                number: 0,
                icon: Icons.backspace_outlined,
                onTap: () => onNumberTap?.call(0),
                isNoteMode: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isNoteMode;
  final bool isComplete;
  final int count;
  
  const _NumberButton({
    required this.number,
    this.icon,
    required this.onTap,
    this.isNoteMode = false,
    this.isComplete = false,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null && icon == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isComplete 
                ? AppColors.green.withOpacity(0.15)
                : isNoteMode && icon == null 
                    ? AppColors.blue.withOpacity(0.1) 
                    : AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? AppColors.green
                  : isNoteMode && icon == null 
                      ? AppColors.blue 
                      : AppColors.gray200,
              width: isComplete || (isNoteMode && icon == null) ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Chiffre ou checkmark
              Center(
                child: icon != null
                    ? Icon(icon, color: AppColors.gray700, size: 24)
                    : isComplete
                        ? Icon(
                            Icons.check_circle,
                            color: AppColors.green,
                            size: 32,
                          )
                        : Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isNoteMode 
                                  ? AppColors.blue 
                                  : AppColors.gray900,
                            ),
                          ),
              ),
              
              // Icône mode notes
              if (isNoteMode && icon == null && !isComplete)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: AppColors.blue,
                  ),
                ),
              
              // Compteur (3/9)
              if (!isComplete && icon == null && count > 0)
                Positioned(
                  bottom: 2,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count/9',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.gray700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}