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

// This class stores word speed and accuracy, and provides an
// utility method to compute its penalty score.
private class WordStats {
  ArrayList<Long> typeTime = new ArrayList<Long>();
  ArrayList<Boolean> isAccurate = new ArrayList<Boolean>();
  
  // Standard constructor. Add a low performance record by default.
  public WordStats() {
    typeTime.add((long) 60000.0 / wordStartAvgWpm);
    isAccurate.add(false); // this field is not used in the current version
  }
  
  // Get average WPM for this word
  float getAvgWpm() {
    long totalTime = 0;
    if (typeTime.size() > 0) {
      for (int i = typeTime.size() - wordAvgSamples; i < typeTime.size(); i++) totalTime += typeTime.get(max(i, 0));
      return wordAvgSamples * 1.0 / (totalTime / 60000.0);
    } else {
      return 1.0;
    }
  }
  
  // Return the word penalty score. In this version, only speed is
  // taking into account
  long getWordPenalty() {
    long timePenalty = 0;
    if (typeTime.size() > 0) {
      for (int i = typeTime.size() - wordAvgSamples; i < typeTime.size(); i++) timePenalty += typeTime.get(max(i, 0));
      // The returned value is directly proportional to timePenalty^3
      return timePenalty * timePenalty / 2000 * timePenalty;
    } else {
      return 9999999999L;
    }
  }
}
