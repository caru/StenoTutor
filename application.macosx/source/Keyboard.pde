/*
 *   This file is part of StenoTutor.
 *
 *   StenoTutor is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   StenoTutor is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *   Copyright 2013 Emanuele Caruso. See LICENSE.txt for details.
 */

// This class holds the on-screen keyboard logic.
// It also draws the on-screen keyboard.
public class Keyboard {
  // Keyboard position
  int x;
  int y;

  // Whether to show QWERTY keys
  boolean showQwerty;

  // Keys
  char[][] stenoRows = {
    {'S', 'T', 'P', 'H', '*', 'F', 'P', 'L', 'T', 'D'},
    {'S', 'K', 'W', 'R', '*', 'R', 'B', 'G', 'S', 'Z'},
    {'A', 'O', 'E', 'U'}
  };
  String[][] qwertyRows = {
    {"Q", "W", "E", "R", "TY", "U", "I", "O", "P", "["},
    {"A", "S", "D", "F", "GH", "J", "K", "L", ";", "'"},
    {"C", "V", "N", "M"}
  };

  // Key size
  int keySizeX = 50;
  int keySizeY = 50;

  // Keyboard state variables
  String lastStroke = "";
  boolean[][] pressedKeys;

  // Default constructor
  Keyboard(int x, int y, boolean showKeyboardQwerty) {
    this.x = x;
    this.y = y;
    showQwerty = showKeyboardQwerty;
  }

  // Draw keyboard
  void draw(String stroke) {
    if (lastStroke != stroke) {
      lastStroke = stroke;

      // Get and set pressedKeys[][]
      pressedKeys = getPressedKeys(stroke);
    }
    // Top row
    drawRaw(0, 10, x, y );
    // Bottom row
    drawRaw(1, 10, x, y + (keySizeY + 10));
    // Vowels row
    drawRaw(2, 4, (int) (x + (keySizeX + 10) * 2.5), y + (keySizeY + 10) * 2);
  }

  // Draw a keyboard row with the given parameters
  void drawRaw(int rowIndex, int rowSize, int rowX, int rowY) {
    for (int i = 0; i < rowSize; i++) {
      fill(pressedKeys[rowIndex][i] ? 0 : 75);
      rect(rowX + (keySizeX + 10) * i, rowY, keySizeX, keySizeY, 5);
      fill(225);
      textAlign(CENTER);
      text(stenoRows[rowIndex][i], rowX + keySizeX / 2 + (keySizeX + 10) * i, rowY + (keySizeY / 2 + 10));
      if (showQwerty) {
        fill(40);
        text(qwertyRows[rowIndex][i], rowX + keySizeX / 2 + (keySizeX + 10) * i - 15, rowY + (keySizeY / 2 + 10) - 15);
      }
    }
  }

  // Return the pressed keys corresponding to the given stroke
  boolean[][] getPressedKeys(String stroke) {
    boolean[][] result = new boolean[3][10];
    //result[1][5] = true;
    int index = stroke.indexOf("A");
    if (index == -1) index = stroke.indexOf("O");
    if (index == -1) index = stroke.indexOf("-");
    if (index == -1) index = stroke.indexOf("*");
    if (index == -1) index = stroke.indexOf("E");
    if (index == -1) index = stroke.indexOf("U");

    // The chord only contains left side consonants
    if (index == -1) {
      setLeftConsonants(stroke, result);
    } else if (index > 0) { // both left side consonants and other keys
      setLeftConsonants(stroke.substring(0,index), result);
      setVowelsAndRightConsonants(stroke.substring(index, stroke.length()), result);
    } else { // only other keys
      setVowelsAndRightConsonants(stroke, result);
    }

    return result;
  }
}

// Read all vowels, right consonants and '*' and set the corresponding pressed keys
// in the result array
void setVowelsAndRightConsonants(String substroke, boolean[][] result) {
  for (int i = 0; i < substroke.length(); i++) {
    char stenoKey = substroke.charAt(i);
    if (stenoKey == '*') {
      result[0][4] = true;
      result[1][4] = true;
    }
    else if (stenoKey == 'A') {
      result[2][0] = true;
    }
    else if (stenoKey == 'O') {
      result[2][1] = true;
    }
    else if (stenoKey == 'E') {
      result[2][2] = true;
    }
    else if (stenoKey == 'U') {
      result[2][3] = true;
    }
    else if (stenoKey == 'F') {
      result[0][5] = true;
    }
    else if (stenoKey == 'R') {
      result[1][5] = true;
    }
    else if (stenoKey == 'P') {
      result[0][6] = true;
    }
    else if (stenoKey == 'B') {
      result[1][6] = true;
    }
    else if (stenoKey == 'L') {
      result[0][7] = true;
    }
    else if (stenoKey == 'G') {
      result[1][7] = true;
    }
    else if (stenoKey == 'T') {
      result[0][8] = true;
    }
    else if (stenoKey == 'S') {
      result[1][8] = true;
    }
    else if (stenoKey == 'D') {
      result[0][9] = true;
    }
    else if (stenoKey == 'Z') {
      result[1][9] = true;
    }
  }
}

// Read all left consonants and set the corresponding pressed keys
// in the result array
void setLeftConsonants(String substroke, boolean[][] result) {
  for (int i = 0; i < substroke.length(); i++) {
    char stenoKey = substroke.charAt(i);
    if (stenoKey == 'S') {
      result[0][0] = true;
      result[1][0] = true;
    }
    else if (stenoKey == 'T') {
      result[0][1] = true;
    }
    else if (stenoKey == 'K') {
      result[1][1] = true;
    }
    else if (stenoKey == 'P') {
      result[0][2] = true;
    }
    else if (stenoKey == 'W') {
      result[1][2] = true;
    }
    else if (stenoKey == 'H') {
      result[0][3] = true;
    }
    else if (stenoKey == 'R') {
      result[1][3] = true;
    }
  }
}
