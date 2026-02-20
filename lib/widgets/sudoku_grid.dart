import 'package:flutter/material.dart';
import '../config/theme.dart';

class SudokuGrid extends StatelessWidget {
  final List<List<int>> grid;
  final List<List<bool>> initialCells;
  final List<List<bool>> errorCells;
  final List<List<Set<int>>> notes;
  final int? selectedRow;
  final int? selectedCol;
  final String? selectedBooster;
  final Function(int row, int col)? onCellTap;
  
  const SudokuGrid({
    Key? key,
    required this.grid,
    required this.initialCells,
    required this.errorCells,
    required this.notes,
    this.selectedRow,
    this.selectedCol,
    this.selectedBooster,
    this.onCellTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get the selected cell's value for highlighting
    int? selectedValue;
    if (selectedRow != null && selectedCol != null) {
      selectedValue = grid[selectedRow!][selectedCol!];
      if (selectedValue == 0) selectedValue = null;
    }
    
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              final cellValue = grid[row][col];
              
              // Check if this cell should be highlighted
              final bool isSelected = selectedRow == row && selectedCol == col;
              final bool isSameRow = selectedRow == row;
              final bool isSameCol = selectedCol == col;
              final bool isSameBox = selectedRow != null && selectedCol != null &&
                  (row ~/ 3) == (selectedRow! ~/ 3) &&
                  (col ~/ 3) == (selectedCol! ~/ 3);
              
              // Check if this cell has the same number as selected cell
              final bool hasSameNumber = selectedValue != null && 
                  cellValue != 0 && 
                  cellValue == selectedValue;
              
              return _SudokuCell(
                value: cellValue,
                notes: notes[row][col],
                isInitial: initialCells[row][col],
                isError: errorCells.isNotEmpty && 
                    errorCells.length > row && 
                    errorCells[row].length > col 
                    ? errorCells[row][col] 
                    : false,
                isSelected: isSelected,
                isSameRow: isSameRow,
                isSameCol: isSameCol,
                isSameBox: isSameBox,
                hasSameNumber: hasSameNumber,
                onTap: () => onCellTap?.call(row, col),
                hasThickRightBorder: col % 3 == 2 && col != 8,
                hasThickBottomBorder: row % 3 == 2 && row != 8,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  final int value;
  final Set<int> notes;
  final bool isInitial;
  final bool isError;
  final bool isSelected;
  final bool isSameRow;
  final bool isSameCol;
  final bool isSameBox;
  final bool hasSameNumber;
  final VoidCallback onTap;
  final bool hasThickRightBorder;
  final bool hasThickBottomBorder;
  
  const _SudokuCell({
    required this.value,
    required this.notes,
    required this.isInitial,
    required this.isError,
    required this.isSelected,
    required this.isSameRow,
    required this.isSameCol,
    required this.isSameBox,
    required this.hasSameNumber,
    required this.onTap,
    required this.hasThickRightBorder,
    required this.hasThickBottomBorder,
  });

  @override
  Widget build(BuildContext context) {
    // Determine background color based on highlighting rules
    Color backgroundColor = Colors.white;
    
    if (isError) {
      // Erreur a la priorité la plus haute
      backgroundColor = AppColors.red.withOpacity(0.2);
    } else if (isSelected) {
      // Cellule sélectionnée - bleu moyen
      backgroundColor = const Color(0xFFBBDEFB); // Bleu clair
    } else if (hasSameNumber) {
      // Même chiffre - brille fort (bleu plus intense)
      backgroundColor = const Color(0xFF90CAF9); // Bleu moyen-fort
    } else if (isSameRow || isSameCol) {
      // Même ligne ou colonne - surbrillance légère
      backgroundColor = const Color(0xFFE3F2FD); // Bleu très clair
    } else if (isSameBox) {
      // Même boîte 3x3 - surbrillance très légère
      backgroundColor = const Color(0xFFF5F5F5); // Gris très clair
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(
            color: hasThickRightBorder ? AppColors.gray900 : AppColors.gray300,
            width: hasThickRightBorder ? 2 : 1,
          ),
          bottom: BorderSide(
            color: hasThickBottomBorder ? AppColors.gray900 : AppColors.gray300,
            width: hasThickBottomBorder ? 2 : 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.blue.withOpacity(0.2),
          highlightColor: AppColors.blue.withOpacity(0.1),
          child: Center(
            child: value != 0
                ? Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isInitial 
                          ? AppColors.gray900 
                          : hasSameNumber
                              ? AppColors.highlightSameNumber 
                              : AppColors.highlightSameNumber,
                    ),
                  )
                : notes.isNotEmpty
                    ? _NotesGrid(notes: notes)
                    : null,
          ),
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final Set<int> notes;
  
  const _NotesGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final number = index + 1;
        final hasNote = notes.contains(number);
        
        return Center(
          child: hasNote
              ? Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
        );
      },
    );
  }
}