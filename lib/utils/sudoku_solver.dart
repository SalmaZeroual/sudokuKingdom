class SudokuSolver {
  static bool isValid(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num) return false;
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (grid[i][col] == num) return false;
    }
    
    // Check 3x3 box
    int boxRow = row - row % 3;
    int boxCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[boxRow + i][boxCol + j] == num) return false;
      }
    }
    
    return true;
  }
  
  static bool solve(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isValid(grid, row, col, num)) {
              grid[row][col] = num;
              
              if (solve(grid)) {
                return true;
              }
              
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
  
  static List<int> getPossibleValues(List<List<int>> grid, int row, int col) {
    if (grid[row][col] != 0) return [];
    
    List<int> possible = [];
    for (int num = 1; num <= 9; num++) {
      if (isValid(grid, row, col, num)) {
        possible.add(num);
      }
    }
    return possible;
  }
  
  static bool isSolved(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) return false;
        
        int temp = grid[row][col];
        grid[row][col] = 0;
        
        if (!isValid(grid, row, col, temp)) {
          grid[row][col] = temp;
          return false;
        }
        
        grid[row][col] = temp;
      }
    }
    return true;
  }
}