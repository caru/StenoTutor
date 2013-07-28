Copyright 2013 Emanuele Caruso. See LICENSE.txt for details.

StenoTutor - Learn to stenotype
===============================

With StenoTutor you can learn to stenotype on your QWERTY keyboard, also thanks to [Plover](https://github.com/plover/plover), an open source application which transforms your QWERTY keyboard in a stenograph, while still mantaining full control over your operating system.

StenoTutor is a free software available for GNU/Linux, Windows and Mac (not tested on Mac, please let me know if it works), and requires a recent Java runtime installed and Plover 2.4.x installed and running. It is coded in Processing IDE 2.x.

StenoTutor tries to be a smart trainer: words that takes you longer to type have more possibilites of showing up, so you will spend most of your time working on your weaknesses. It also allows to blacklist some words, in case you don't have a NKRO keyboard yet and you just want to see if you enjoy steno and how well you speed up, without being annoyed by words that your keyboard cannot actually type without rolling or arpeggiating chords.

Lessons have been initially copied from a similar project called [Fly](https://launchpad.net/flyploverfly).

The StenoTutor application was initially developed and published by Emanuele Caruso.

Installation
------------

* Make sure the a recent version of Java is installed
* Download [the repository zip file](https://github.com/caru/StenoTutor/archive/master.zip) in a directory of your choice.
* Extract the folder corresponding to your system on your hard drive. For example, if you use Linux 32-bit, extract the folder named "application.linux32/"
* Optionally tweak data/session.properties to customize the lesson.
* Run Plover (it must be version 2.4+). It must be running and enabled to properly capture its translated output.

1. Linux - 
Make "StenoTutor" script executable, either on command line (chmod +x StenoTutor) or by right-clicking it and changing file permissions. Finally, run StenoTutor either from command line (./StenoTutor) or by double-clicking it.

2. Windows 64 bit - 
Double-click StenoTutor.bat (if the window is too little, exiting and then running it again should work)

2. Windows 32 bit - 
Double-click StenoTutor.exe (if the window is too little, quitting and then running it again should work)

3. Mac - 
Follow readme.txt

Features
--------
* Smart word selection, slower-typed words show up more often.
* Optional basic Word dictation via speech synthesis, can be enabled in data/session.properties.
* Speech syntesis powered stats and new level announcements, can be disabled.
* QWERTY/steno on-screen keyboard, with next chord highlighting (currently only monochrome and only shows first chord for words that require multiple strokes). You can disable on-screen keyboard, querty keys and next chord highlighting.
* Blacklist specific words (press CONTROL to blacklist the current word), which is saved on disk at each new addition.
* Pause/resume current lesson with TAB key. You can resume with any key or chord, and the stroke will be printed in the input buffer.
* Display: next chord, next word, input buffer, input chord, current word last-x-average wpm, session wpm, level, timer, total unlocked words, worst word and worst word WPM.
* Incremental word presentation: you can configure how many words to show at the beginning of the lession, how many to add at each level up, minimum average WPM to level up, minimum single word average WPM to level up, how many of the latest samples to use for word average WPM calculation and word start average WPM.
* There is no leveling down, StenoTutor will always make sure that you mainly work on the words that currently put you into trouble, which are usually the new ones.
* Custom lessons can be created in "data/lesson/" directory.
* Session parameters can be customized in "data/session.properties".
* Errors must be manually deleted by the student with '*' key. This allows StenoTutor to provide an experience more similar to real world typing.
* Option to pre-compute and show multiple words at a time, to provide a typing experience similar to many online multiplayer typing games and more similar to real world typing. It is configurable. It defaults to multiple words per line.
* When leveling up, the new level is announced with speech synthesis

Known Bugs
----------
* Next chord highlighting currently shows only first chord for words that require multiple strokes.
* There is no check for the completion of the lesson dictionary, so there are no greetings yet and there may be errors too.

Planned Features and Future Enhancements
----------------------------------------
* Dynamically show next line words as they are created to allow for a better typing flow at the end of lines
* Color coded highlighting of next chord.
* Run StenoTutor commands from input buffer
* GUI interface, eg: buttons and/or menus
* Change lesson format to something more convenient, eg: Plover dictionary format
* Add a command to repeat current word with text-to-speech
* Show worst 5 words and their average WPM
* Alphabet training mode
* Sentence training mode
* Options to show/hide the various info and features
* Save session statistics in txt files
* Accuracy recording, including average session accuracy, accuracy level up limits, average accuracy per word and a mixed speed/accuracy based word selection
* Font colors and GUI colors configuration file

How to build StenoTutor (for developers)
----------------------------------------

If you want to modify and rebuild StenoTutor, you just have to download and install the Processing IDE and extract the whole StenoTutor repository to your Documents/Processing folder (or you can get it with git)
Then you will be able to open it in from Processing: File -> Sketchbook -> StenoTutor. Or you can find it with File -> Open.
Ctrl-R -> play sketch (compiles and opens StenoTutor)
Ctrl-E -> export application (updates application.xxx folders for the various OSs)

You can also probably use your favorite editor. For example, Processing plugins exist for Emacs and Sublime text editors.
In the future, it may be needed or just convenient to refactor StenoTutor to a standard Java project (while still using Processing framework and libraries)

Changelog
---------

*Version 0.0.6*
* Added on-screen keyboard with next chord highligthing. You can optionally disable on-screen keyboard, querty keys and next chord highlighting.
* Added optional text-to-speech word dictation, can be enabled in data/session.properties. Default: disabled.
* Lot of refactored code, now it's much more readable.

*Version 0.0.5*
* Word blacklisting is now disabled if the lesson is paused, because that caused issues on word stats

*Version 0.0.4*
* Fixed bug: did not correctly import some lesson files
* Added lesson on long vowels provided by Daniel Langlois

*Version 0.0.3*
* Added speech synthesis capability. Currently, new levels and session WPM are announced periodically. All this is fine tunable in session.properties.
* Added pause/resume current lesson with TAB key. You can resume with any key or chord, and the stroke will be printed in the input buffer.
* Input is now directly taken from Plover standard output.
* Fixed bug: word backlisting was not working properly with multiple words per line.
* Fixed bug: unlocked and total words count didn't take blacklist words into account.

*Version 0.0.2*
* Show one target word at a time or fill the line and complete it. You can configure this in session.properties, property name session.isSingleWordBuffer

*Version 0.0.1*
* Smart word selection, slower-typed words show up more often.
* Blacklist specific words (press CONTROL to blacklist the current word), which is saved on disk at each new addition.
* Display: next chord, next word, input buffer, input chord, current word last-x-average wpm, session wpm, level, timer, total unlocked words, worst word and worst word WPM.
* Incremental word presentation: you can configure how many words to show at the beginning of the lession, how many to add at each level up, minimum average WPM to level up, minimum single word average WPM to level up, how many of the latest samples to use for word average WPM calculation and word start average WPM.
* There is no leveling down, StenoTutor will always make sure that you mainly work on the words that currently put you into trouble, which are usually the new ones.
* Custom lessons can be created in "data/lesson/" directory.
* Session parameters can be customized in "data/session.properties".
* Errors must be manually deleted by the student with '*' key. This allows StenoTutor to provide an experience more similar to real world typing.
