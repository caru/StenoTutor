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

// This thread periodically announces average WPM
public class WpmReporter extends Thread {
  long period;

  WpmReporter(long period) {
    this.period = period;
  }

  // Wait period, then if lesson is not paused announce WPM
  void run() {
    while (true) {
      try {
        Thread.sleep(period);
      } catch (InterruptedException x) {
        Thread.currentThread().interrupt();
        break;
      }
      if (!isLessonPaused) {
        Speaker speaker = new Speaker((int) getAverageWpm() + " words per minute.");
        speaker.start();
      }
    }
  }
}
