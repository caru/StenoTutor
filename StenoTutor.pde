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
  readEndOfFile();
  
  // Prepare file paths and read lesson dictionary and blacklist
  lesDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".les";
  chdDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".chd";
  blkDictionaryFilePath = sketchPath + "/data/lessons/" + lessonName + ".blk";
  readDictionary();
  readBlacklist();
  
  // Make sure startBaseWords is adjusted based on blacklist
  applyStartBlacklist();
  
  // Initialize word stats
  for (int i = 0; i < dictionary.size(); i++) {
    wordStats.add(new WordStats());
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
  Stroke stroke = getNextStroke();

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
    writeBlacklist();
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
  // TODO: append stroke to buffer input in the case:
  // if (stroke.word.equals(" None")) return;
}

// Initialize Plover log reader and go to end of file
void readEndOfFile() {
  String line = null;
  String tempLine = null;
  try {
    Reader reader = new FileReader(logFilePath);
    logReader = new BufferedReader(reader);
    while ((tempLine = logReader.readLine()) != null) {
      line = tempLine;
    }
  }
  catch (Exception e) {
    println("Error while reading Plover log file: " + e.getMessage());
  }
}

// Read lesson dictionary and store words and corresponing strokes
// in list fields
void readDictionary() {
  String tempLine = null;
  BufferedReader lesReader = null;
  BufferedReader chdReader = null;
  ArrayList<String> words = new ArrayList<String>();
  ArrayList<String> strokes = new ArrayList<String>();
  dictionary = new ArrayList<Word>();
  
  // Read and store words
  try {
    Reader reader = new FileReader(lesDictionaryFilePath);
    lesReader = new BufferedReader(reader);
    while ((tempLine = lesReader.readLine()) != null) {
      if (tempLine.length() != 0 && tempLine.charAt(0) == '<' || tempLine.trim().length() == 0) continue;
      String[] newWords = tempLine.split(" ");
      for (String word : newWords) {
        words.add(word);
      }
    }
  }
  catch (Exception e) {
    println("Error while reading .les dictionary file: " + e.getMessage());
  }
  if (lesReader != null) {
    try {
      lesReader.close();
    } catch (Exception e) {
      
    }
  }
  
  // Read and store strokes
  try {
    Reader reader = new FileReader(chdDictionaryFilePath);
    chdReader = new BufferedReader(reader);
    while ((tempLine = chdReader.readLine()) != null) {
      if (tempLine.length() != 0 && tempLine.charAt(0) == '<' || tempLine.trim().length() == 0) continue;
      String[] newStrokes = tempLine.split(" ");
      for (String stroke : newStrokes) {
        strokes.add(stroke);
      }
    }
  }
  catch (Exception e) {
    println("Error while reading .chd dictionary file: " + e.getMessage());
  }
  if (chdReader != null) {
    try {
      chdReader.close();
    } catch (Exception e) {
      
    }
  }
  
  // Store words and strokes in dictionary list
  if (words != null && strokes != null) for (int i = 0; i < words.size(); i++) {
    Word word = new Word();
    word.word = words.get(i);
    word.stroke = strokes.get(i);
    dictionary.add(word);
  }
  
  // Debug info
  if (debug) {
    println("Current lesson contains " + words.size() + " words and " + strokes.size() + " chords.");
  }
}

// Read lesson blacklist (if any) and store blacklisted words
// in wordsBlacklist field
void readBlacklist() {
  String tempLine = null;
  BufferedReader blkReader = null;
  try {
    Reader reader = new FileReader(blkDictionaryFilePath);
    blkReader = new BufferedReader(reader);
    while ((tempLine = blkReader.readLine()) != null) {
      if (tempLine.trim().length() == 0) continue;
      String[] words = tempLine.split(" ");
      for (String word : words) {
        wordsBlacklist.add(word);
      }
    }
  }
  catch (Exception e) {
    
  }
  if (blkReader != null) {
    try {
      blkReader.close();
    } catch (Exception e) {
      
    }
  }
}

// Store updated blacklist data in external file
void writeBlacklist() {
  BufferedWriter blkWriter = null;
  StringBuilder blacklist = new StringBuilder();
  for (String word : wordsBlacklist) {
    blacklist.append(word + " ");
  }
  String fileContent = blacklist.toString();
  fileContent = fileContent.substring(0, fileContent.length() - 1);
  try {
    Writer writer = new FileWriter(blkDictionaryFilePath);
    blkWriter = new BufferedWriter(writer);
    blkWriter.write(fileContent);
  }
  catch (Exception e) {
    
  }
  if (blkWriter != null) {
    try {
      blkWriter.close();
    } catch (Exception e) {
      
    }
  }
}

// Get next stroke from Plover log file
Stroke getNextStroke() {
  Stroke stroke = new Stroke();
  String line = null;
  try {
    line = logReader.readLine();
    int indexOfTransl = -1;
    if(line != null) indexOfTransl = line.indexOf("Translation");
    if(line != null && indexOfTransl > -1) {
      boolean isMultipleWorld = false;
      int indexOfLast = 1 + line.indexOf(",) : ");
      if (indexOfLast < 1) {
        isMultipleWorld = true;
        indexOfLast = line.indexOf(" : ");
      }
      if (indexOfTransl == 24) {
        stroke.isDelete = false;
      }
      else {
        stroke.isDelete = true;
      }
      stroke.stroke = getStroke(line, indexOfTransl + 14, indexOfLast - 2);
      stroke.word = line.substring(indexOfLast + (isMultipleWorld ? 2 : 3), line.length() - 1);
      return stroke;
    } else {
      return null;
    }
  } catch (Exception e) {
  
  }
  return null;
}

// Format strokes and multiple strokes for a single word
String getStroke(String line, int start, int end) {
  String result = "";
  String strokeLine = line.substring(start, end);
  String[] strokes = strokeLine.split("', '");
  for (String stroke: strokes) result += stroke + "/";
  return result.substring(0, result.length() - 1);
}

// This class represents a lesson word
private class Word {
  String stroke = "";
  String word = "";
}

// This class represents an actual stroke
private class Stroke extends Word{
  boolean isDelete = false;
}

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

// Represents a multi-word buffer containing the next target line
private class NextWordsBuffer {
  // A list of integers containing all the words in the line
  ArrayList<Integer> nextWords = new ArrayList<Integer>();
  int highlightedWordIndex;
  int bufferSize;
  
  // Default constructor
  NextWordsBuffer(int bufferSize) {
    this.bufferSize = bufferSize;
    fillNewLine(1);
  }
  
  // Go to last item in the list
  void listEnd() {
    highlightedWordIndex = nextWords.size() - 1;
  }
  
  // Get current word dictionary index
  int getCurrentWordIndex() {
    return nextWords.get(highlightedWordIndex);
  }
  
  // Get next word dictionary index
  int getNextWordIndex() {
    highlightedWordIndex++;
    if (highlightedWordIndex < nextWords.size()) {
      return nextWords.get(highlightedWordIndex);
    } else {
      fillNewLine(nextWords.get(highlightedWordIndex-1));
      return getCurrentWordIndex();
    }
  }
  
  // Fill a new line
  void fillNewLine(int previousWordIndex) {
    int lastWordIndex = previousWordIndex;
    
    // Clear word list
    nextWords.clear();
    
    // Store the used space
    float usedBufferSize = 0;
    
    // Calculate current min and max penalty limits
    long[] penaltyLimits = calculatePenaltyLimits();
    
    // Fill the new line as long as there is space in the buffer
    while (usedBufferSize < bufferSize) {
      int nextWordIndex = getNextWordFromPool(lastWordIndex, penaltyLimits);
      nextWords.add(nextWordIndex);
      lastWordIndex = nextWordIndex;
      
      textFont(font, mainTextFontSize);
      usedBufferSize += textWidth(dictionary.get(nextWordIndex).word.trim() + " ");
      
      // If only one word is required, break the loop
      if(isSingleWordBuffer) break;
    }
    
    // Remove this word because it probably finishes off-screen,
    // unless it's the only one
    if(nextWords.size() > 1) nextWords.remove(nextWords.size()-1);
    
    // Highlight first word
    highlightedWordIndex = 0;
  }
  
  // Compute the next word. Slow-typed words have more possibilities
  // to show up than fast-typed ones
  int getNextWordFromPool(int previousWordIndex, long[] penaltyLimits) {
    // Create word pool
    ArrayList<Integer> wordPool = new ArrayList<Integer>();

    // For each unlocked word, if it's not the current one and it
    // isn't blacklisted, add it to the pool a number of times,
    // based on word penalty.
    for (int i = 0; i < startBaseWords + unlockedWords; i++) {
      if (i == previousWordIndex || wordsBlacklist.contains(dictionary.get(i).word)) continue;
      else {
        int penalty = (int) map(wordStats.get(i).getWordPenalty(), penaltyLimits[0], penaltyLimits[1], 1, 100);
        for (int j = 0; j < penalty; j++) wordPool.add(i);
      }
    }
  
  // Fetch a random word from the word pool
  return wordPool.get((int) random(0, wordPool.size()));
  }

  // Calculate current min and max penalty limits
  long[] calculatePenaltyLimits() {
    long currentMinPenalty = 1000000000;
    long currentMaxPenalty = 0;
    for (int i = 0; i < startBaseWords + unlockedWords - 1; i++) {
      if (i == currentWordIndex || wordsBlacklist.contains(dictionary.get(i).word)) continue;
      long penalty = wordStats.get(i).getWordPenalty();
      if (currentMinPenalty > penalty) currentMinPenalty = penalty;
      if (currentMaxPenalty < penalty) currentMaxPenalty = penalty;
    }
    return new long[] {currentMinPenalty, currentMaxPenalty};
  }
  
  // Draw target line text
  void showText(int x, int y) {
    float currentX = x;
    textFont(font, mainTextFontSize);
    for (int i = 0; i < nextWords.size(); i++) {
      int index = nextWords.get(i);
      String word = dictionary.get(index).word;
      if (i == highlightedWordIndex) {
        noFill();
        stroke(250, 200, 100);
        //rect(currentX - (textWidth(" ") / 2), y - mainTextFontSize, textWidth(word + " "), mainTextFontSize + 7, 5);
        line(currentX, y + mainTextFontSize / 5, currentX + textWidth(word), y + mainTextFontSize / 5);
        fill(250, 200, 100);
      }
      text(word, currentX, y);
      if (i == highlightedWordIndex) fill(isLessonPaused ? 200 : 250);
      currentX += textWidth(word + " ");
    }
  }
}

// This thread periodically announces average WPM
private class WpmReporter extends Thread {
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
