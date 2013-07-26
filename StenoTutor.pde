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

import java.io.*;
import java.util.Properties;
import java.util.Arrays;

// Session parameters, see data/session.properties for more info
String lessonName;
int startBaseWords;
int incrementWords;
int minLevelUpWordWpm;
int minLevelUpTotalWpm;
int wordAvgSamples;
int wordStartAvgWpm;
boolean isSingleWordBuffer;
boolean isSoundEnabled;
boolean isAnnounceLevels;
int wpmReportingPeriod;

// Contains various helper methods
Utils utils = new Utils();

// Used to read Plover log
BufferedReader logReader = null;

// Font definition, size is modified later
final PFont font = createFont("Arial",30,true);

// Default relative path to Plover log for Win and other OSs
final String winLogBasePath = "/AppData/Local/plover/plover/plover.log";
final String xLogBasePath = "/.config/plover/plover.log";

// Path to Plover log file
String logFilePath;

// Paths to lesson dictionaries and blacklist
String lesDictionaryFilePath;
String chdDictionaryFilePath;
String blkDictionaryFilePath;

// Input buffer
String buffer = "";

// Target line buffer
NextWordsBuffer nextWordsBuffer;

// Dictionary of current lesson
ArrayList<Word> dictionary;

// Stats of current lesson for each word
ArrayList<WordStats> wordStats = new ArrayList<WordStats>();

/*
 * Blacklisted words, useful if you just started learning without a NKRO keyboard or a
 * dedicated one and some words are not recognized by Plover.
 * You can blacklist the current word by pressing the CONTROL key.
 * The blacklist is saved at each new inclusion to a text file in /data/lessons, with the
 * same name of the corresponding lesson files but with .blk extension.
 */
ArrayList<String> wordsBlacklist = new ArrayList<String>();

// Current level
int currentLevel = 0;

// Unlocked words counter
int unlockedWords = 0;

// Index of the current word
int currentWordIndex = 0;

// Whether the lesson is started
boolean isLessonStarted = false;

// Whether the lesson is paused
boolean isLessonPaused = false;

// Store lesson start time for WPM calculation
long lessonStartTime;

// Store last typed word time for smart training purposes
long lastTypedWordTime;

// Store lesson pause start time for proper resuming
long lastPauseTime;

// Total words typed in the current lesson
int typedWords = 0;

// Worst word WPM and String value
int worstWordWpm = 0;
String worstWord = "";

// Stores the previous stroke, needed when redrawing text info
Stroke previousStroke = new Stroke();

// Whether CONTROL key has been pressed and released, used to blacklist the current word
boolean ctrlKeyReleased = false;

// Whether TAB key has been pressed and released, used pause/resume the session
boolean tabKeyReleased = false;

// If debugging, prints more info
boolean debug = false;

/*
 * ---------------------
 * GUI LAYOUT VARIABLES
 * ---------------------
 */
int frameSizeX = 700;
int frameSizeY = 280;
int defaultFontSize = 20;
int mainTextFontSize = 24;
int baseX = 60;
int baseY = 70;
int labelValueSpace = 20;
int nextWordX = baseX + 120;
int nextWordY = baseY;
int nextChordX = baseX + 120;
int nextChordY = baseY + -35;
int lastChordX = baseX + 120;
int lastChordY = baseY + 80;
int bufferX = baseX + 120;
int bufferY = baseY + 50;
int wpmX = baseX + 120;
int wpmY = baseY + 140;
int timerX = baseX + 270;
int timerY = baseY + 140;
int wordWpmX = baseX + 120;
int wordWpmY = baseY + 170;
int levelX = baseX + 270;
int levelY = baseY + 170;
int unlockedWordsX = baseX + 470;
int unlockedWordsY = baseY + 140;
int totalWordsX = baseX + 470;
int totalWordsY = baseY + 170;
int worstWordWpmX = baseX + 120;
int worstWordWpmY = baseY + 200;
int worstWordX = baseX + 270;
int worstWordY = baseY + 200;

// Session setup
void setup() {
  // Read session configuration
  readSessionConfig();
  
  // Find Plover log path
  findPloverLog();
  
  // Go to the end of Plover log file
  logReader = utils.readEndOfFile(logFilePath);
  
  // Prepare file paths and read lesson dictionary and blacklist
  lesDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".les";
  chdDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".chd";
  blkDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".blk";
  dictionary = utils.readDictionary(lesDictionaryFilePath, chdDictionaryFilePath, debug);
  wordsBlacklist = utils.readBlacklist(blkDictionaryFilePath);
  
  // Make sure startBaseWords is adjusted based on blacklist
  applyStartBlacklist();
  
  // Initialize word stats
  for (int i = 0; i < dictionary.size(); i++) {
    wordStats.add(new WordStats(wordStartAvgWpm, wordAvgSamples));
  }
  
  // Initialize target line buffer and set next word index
  nextWordsBuffer = new NextWordsBuffer(frameSizeX - nextWordX);
  currentWordIndex = nextWordsBuffer.getCurrentWordIndex();
  
  // Configure display size
  size(frameSizeX, frameSizeY);
  
  // Paint background and show text info
  background(25);
  Stroke stroke = new Stroke();
  showTextInfo(stroke);
}

// Draw cycle
void draw() {
  // If CONTROL key has been released, blacklist the current word
  if (ctrlKeyReleased) {
    blacklistCurrentWord();
  }
  
  // If TAB key has been released, pause/resume the session
  if (tabKeyReleased) {
    togglePause();
    tabKeyReleased = false;
  }

  // Read the next stroke from Plover log
  Stroke stroke = utils.getNextStroke(logReader);

  // If the stroke is not null, store it
  if (stroke != null) {
    // If the lesson just started, add word start avg time. This ensures that
    // the first word doesn't start with extremely low penalty.
    if (!isLessonStarted) {
      isLessonStarted = true;
      lessonStartTime = System.currentTimeMillis();
      lastTypedWordTime = lessonStartTime - ((long) 60000.0 / wordStartAvgWpm);
      // Announce Level 0
      announceCurrentLevel();
      // If WPM reporting is enabled, start it
      if (isSoundEnabled && wpmReportingPeriod > 0) {
        WpmReporter wpmReporter = new WpmReporter((long) wpmReportingPeriod * 1000);
        wpmReporter.start();
      }
    }
    previousStroke = stroke;
  }
  
  // Check if input buffer matches and possibly advance to the next word
  checkBuffer(false);
  
  // Paint background and show text info
  background(25);
  showTextInfo(stroke == null ? previousStroke : stroke);
}

// Check for released keys and update corresponding state
void keyReleased() {
  // Blacklist command
  if (keyCode == CONTROL) ctrlKeyReleased = true;

  // Input buffer update.
  if (key != CODED) {
    // If the lesson is paused, any key will resume the lesson.
    if (isLessonPaused) {
      tabKeyReleased = true;
    }
    
    switch(key) {
    case BACKSPACE:
      if (isLessonStarted) buffer = buffer.substring(0, max(0, buffer.length() - 1));
      break;
    case TAB:
      tabKeyReleased = true;
      break;
    case ESC:
    case DELETE:
    case ENTER:
    case RETURN:
      break;
    default:
      buffer += key;
    }
  }
}

// Pause/resume the session
void togglePause() {
  if (!isLessonStarted) return;
  if (isLessonPaused) {
    long now = System.currentTimeMillis();
    long pauseTime = now - lastPauseTime;
    lessonStartTime += pauseTime;
    lastTypedWordTime += pauseTime;
    isLessonPaused = false;
  } else {
    lastPauseTime = System.currentTimeMillis();
    isLessonPaused = true;
  }
}

// Apply start blacklist
void applyStartBlacklist() {
  int totalWords = 0;
  int i = 0;
  while (totalWords < startBaseWords && i < dictionary.size()) {
    if (wordsBlacklist.contains(dictionary.get(i).word.trim())) {
      startBaseWords++;
    }
    totalWords++;
    i++;
  }
}

// Read session configuration
void readSessionConfig() {
  Properties properties = new Properties();
  try {
    properties.load(openStream(sketchPath + "/data/session.properties"));
  } catch (Exception e ) {
    println("Cannot read session properties, using defalt values. Error: " + e.getMessage());
  }
  logFilePath = properties.getProperty("session.logFilePath", "");
  lessonName = properties.getProperty("session.lessonName", "common_words");
  startBaseWords = Integer.valueOf(properties.getProperty("session.startBaseWords", "" + 5));
  incrementWords = Integer.valueOf(properties.getProperty("session.incrementWords", "" + 5));
  minLevelUpWordWpm = Integer.valueOf(properties.getProperty("session.minLevelUpWordWpm", "" + 30));
  minLevelUpTotalWpm = Integer.valueOf(properties.getProperty("session.minLevelUpTotalWpm", "" + 20));
  wordAvgSamples = Integer.valueOf(properties.getProperty("session.wordAvgSamples", "" + 10));
  wordStartAvgWpm = Integer.valueOf(properties.getProperty("session.wordStartAvgWpm", "" + 20));
  isSingleWordBuffer = Boolean.valueOf(properties.getProperty("session.isSingleWordBuffer", "false"));
  isSoundEnabled = Boolean.valueOf(properties.getProperty("session.isSoundEnabled", "true"));
  isAnnounceLevels = Boolean.valueOf(properties.getProperty("session.isAnnounceLevels", "true"));
  wpmReportingPeriod = Integer.valueOf(properties.getProperty("session.wpmReportingPeriod", "" + 60));
}

// Automatically find Plover log file path
void findPloverLog() {
  if(!logFilePath.equals("")) return;
  String userHome = System.getProperty("user.home");
  String userOs = System.getProperty("os.name");
  if (userOs.startsWith("Windows")) {
    logFilePath = userHome + winLogBasePath;
  } else {
    logFilePath = userHome + xLogBasePath;
  }
}

// Blacklist current word
void blacklistCurrentWord() {
  // Reset CONTROL key state
  ctrlKeyReleased = false;
  
  // If the lesson has already started and is not paused, add current
  // word to blacklist, save blacklist to file and unlock a new word.
  // Finally, move to next word.
  if (isLessonStarted && !isLessonPaused) {
    wordsBlacklist.add(dictionary.get(currentWordIndex).word);
    utils.writeBlacklist(wordsBlacklist, blkDictionaryFilePath);
    unlockedWords++;
    
    // Make sure that the unlocked world isn't yet another blacklisted word
    while (wordsBlacklist.contains(dictionary.get(startBaseWords + unlockedWords - 1).word)) unlockedWords++;
    
    // Clear and refresh next words buffer
    nextWordsBuffer.listEnd();
    checkBuffer(true);
  }
}

// Returns time elapsed from lesson start time in milliseconds
long getElapsedTime() {
  return isLessonPaused ? (lastPauseTime - lessonStartTime) : (System.currentTimeMillis() - lessonStartTime);
}

// Display all text info shown in StenoTutor window
void showTextInfo(Stroke stroke) {
  textAlign(RIGHT);
  fill(isLessonPaused ? 200 : 250);
  textFont(font,mainTextFontSize);
  text("Target words:", nextWordX - labelValueSpace, nextWordY);
  text("Input:", bufferX - labelValueSpace, bufferY);
  fill(200);
  textFont(font,defaultFontSize);
  text("Next chord:", nextChordX - labelValueSpace, nextChordY);
  text("Typed chord:", lastChordX - labelValueSpace, lastChordY);
  text("WPM:", wpmX - labelValueSpace, wpmY);
  text("Time:", timerX - labelValueSpace, timerY);
  text("Current w WPM:", wordWpmX - labelValueSpace, wordWpmY);
  text("Level:", levelX - labelValueSpace, levelY);
  text("Unlocked w:", unlockedWordsX - labelValueSpace, unlockedWordsY);
  text("Total w:", totalWordsX - labelValueSpace, totalWordsY);
  text("Worst w WPM:", worstWordWpmX - labelValueSpace, worstWordWpmY);
  text("Worst w:", worstWordX - labelValueSpace, worstWordY);
  textAlign(LEFT);
  fill(isLessonPaused ? 200 : 250);
  textFont(font,mainTextFontSize);
  nextWordsBuffer.showText(nextWordX, nextWordY);
  text(buffer.trim() + (System.currentTimeMillis() % 1000 < 500 ? "_" : ""), bufferX, bufferY);
  fill(200);
  textFont(font, defaultFontSize);
  text(dictionary.get(currentWordIndex).stroke, nextChordX, nextChordY);
  text(stroke.isDelete ? "*" : buffer.equals("") ? "" : stroke.stroke, lastChordX, lastChordY);
  text((int) getAverageWpm(), wpmX, wpmY);
  long timerValue = isLessonStarted ? getElapsedTime() : 0;
  text((int) timerValue/1000, timerX, timerY);
  text(isLessonStarted ? (int) wordStats.get(currentWordIndex).getAvgWpm() : 0, wordWpmX, wordWpmY);
  text(currentLevel, levelX, levelY);
  text(getActualUnlockedWords(), unlockedWordsX, unlockedWordsY);
  text(dictionary.size() - wordsBlacklist.size(), totalWordsX, totalWordsY);
  text(worstWordWpm, worstWordWpmX, worstWordWpmY);
  text(worstWord, worstWordX, worstWordY);
}

// Get session average WPM
float getAverageWpm() {
  return isLessonStarted ? (typedWords / (getElapsedTime() / 60000.0)) : 0.0;
}

// If the input buffer matches the current word or if forceNextWord
// is true, store word stats and delegate to setNextWordIndex() to
// compute the next word based on word stats. Also, if conditions to
// level up are met, unlock new words.
void checkBuffer(boolean forceNextWord) {
  if (buffer.trim().equals(dictionary.get(currentWordIndex).word) || forceNextWord) {
    buffer = ""; // Clear input buffer
    long typeTime = System.currentTimeMillis();
    wordStats.get(currentWordIndex).typeTime.add(typeTime - lastTypedWordTime);
    lastTypedWordTime = typeTime;
    typedWords++;
    checkLevelUp();
    currentWordIndex = nextWordsBuffer.getNextWordIndex();
    updateWorstWord();
  }
}

// Update worst word WPM and String value
void updateWorstWord() {
  int worstWordIndex = 0;
  int tempWorstWordWpm = 500;
  for (int i = 0; i < startBaseWords + unlockedWords; i++) {
    if (wordsBlacklist.contains(dictionary.get(i).word)) {
      continue;
    }
    WordStats stats = wordStats.get(i);
    int wpm = (int) stats.getAvgWpm();
    if (wpm < tempWorstWordWpm) {
      worstWordIndex = i;
      tempWorstWordWpm = wpm;
    }
  }
  worstWordWpm = tempWorstWordWpm;
  worstWord = dictionary.get(worstWordIndex).word;
}

// Check level up. If conditions to level up are met, unlock new
// words.
void checkLevelUp() {
  if ((int) (typedWords / (getElapsedTime() / 60000.0)) < minLevelUpTotalWpm) {
    return;
  }
  for (int i = 0; i < startBaseWords + unlockedWords; i++) {
    if (wordsBlacklist.contains(dictionary.get(i).word)) {
      continue;
    }
    if (wordStats.get(i).getAvgWpm() < minLevelUpWordWpm) {
      return;
    }
  }
  levelUp(); 
}

// Level up, unlock new words
void levelUp() {
  int totalWords = startBaseWords + unlockedWords;
  int i = totalWords;
  unlockedWords += incrementWords;
  while (totalWords < startBaseWords + unlockedWords && i < dictionary.size()) {
    if (wordsBlacklist.contains(dictionary.get(i).word.trim())) {
      unlockedWords++;
    }
    totalWords++;
    i++;
  }
  currentLevel++;
  
  // Announce current level
  announceCurrentLevel();
}

// Announce current level
void announceCurrentLevel() {
  if (isSoundEnabled && isAnnounceLevels) {
    Speaker speaker = new Speaker("Level " + currentLevel); 
    speaker.start();
  }
}

// Get total unlocked words less blacklisted ones
int getActualUnlockedWords() {
  int result = 0;
  for (int i = 0; i < startBaseWords + unlockedWords; i++) {
    if (!wordsBlacklist.contains(dictionary.get(i).word)) {
      result++;
    }
  }
  return result;
}

// Update the input buffer according to the passed stroke.
// Not used in this version, see keyReleased() for the current
// input buffer update mechanism.
void updateBuffer(Stroke stroke) {
  if (stroke.isDelete) buffer = buffer.substring(0, max(0, buffer.length() - stroke.word.length()));
  else buffer += stroke.word;
}
