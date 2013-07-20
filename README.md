Copyright 2013 Emanuele Caruso. See LICENSE.txt for details.

StenoTutor - Learn to stenotype
===============================

With StenoTutor you can learn to stenotype on your QWERTY keyboard, also thanks to [Plover](https://github.com/plover/plover), an open source application which transforms your QWERTY keyboard in a stenograph, while still providing full control of your operating system.

StenoTutor is a free software available for GNU/Linux, Windows and Mac (not tested on Mac, please let me know if it works), and requires a recent Java runtime installed and Plover 2.4.x installed and running. It is coded in Processing IDE 2.x.

StenoTutor is smart: words that takes you longer to type have more possibilites of showing up, so you will spend most of your time working on your weaknesses. It also allows to blacklist some words, in case you don't have a NKRO keyboard yet and you just want to see if you enjoy steno and how well you speed up, without being annoyed by words that your keyboard cannot actually type.

Lessons have been copied from a similar project called [Fly](https://launchpad.net/flyploverfly).

The StenoTutor application was initially developed and published by Emanuele Caruso.

Installation
------------

* Make sure the a recent version of Java is installed
* Download [the repository zip file](https://github.com/caru/StenoTutor/archive/master.zip) in a directory of your choice.
* Extract the folder corresponding to your system on your hard drive. For example, if you use Linux 32-bit, extract the folder named "application.linux32/"
* Optionally tweak session.properties in "data/" subdirectory.
* Run Plover (it must be version 2.4.x). It must be running and enabled to properly capture its translated output.

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
* Blacklist specific words (press CONTROL to blacklist the current word), which is saved on disk at each new addition.
* Display: next chord, next word, input buffer, input chord, current word last-x-average wpm, session wpm, level, timer, total unlocked words, worst word and worst word WPM.
* Incremental word presentation: you can configure how many words to show at the beginning of the lession, how many to add at each level up, minimum average WPM to level up, minimum single word average WPM to level up, how many of the latest samples to use for word average WPM calculation and word start average WPM.
* There is no leveling down, StenoTutor will always make sure that you mainly work on the words that currently put you into trouble, which are usually the new ones.
* Custom lessons can be created in "data/lesson/" directory.
* Session parameters can be customized in "data/session.properties".
* Errors must be manually deleted by the student with '*' key. This allows StenoTutor to provide an experience more similar to real world typing.
* Option to pre-compute and show multiple words at a time, to provide a typing experience similar to many online multiplayer typing games and more similar to real world typing. You can configure this in session.properties, property name session.isSingleWordBuffer. It defaults to false, that is multiple words per line.
* When leveling up, the new level is announced with speech synthesis

Known Bugs
----------
* There is no check for the completion of the lesson dictionary, so there are no greetings yet and there may be errors too.
* Unlocked and total words count don't take blacklist words into account

Planned Features and Future Enhancements
----------------------------------------
* Show worst 5 words and their average WPM
* QWERTY/steno on-screen keyboard
* Highlight next chord on keyboard and color highlighting as well.
* Alphabet training mode
* Sentence training mode
* Options to show/hide the various info and features
* Save session statistics in txt files
* Accuracy recording, including average session accuracy, accuracy level up limits, average accuracy per word and a mixed speed/accuracy based word selection
* Font colors and GUI colors configuration file
* GUI interface, eg: buttons
* Word dictation via speech synthesis

Changelog
---------

*Version 0.0.3*
* Added speech synthesis capability. Currently, new levels are announced. Sound can be turned of in session.properties, property name session.isSoundEnabled
* Input is now directly taken from Plover standard output.
* Fixed bug: word backlisting was not working properly with multiple words per line.

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
