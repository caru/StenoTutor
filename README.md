Copyright 2013 Emanuele Caruso. See LICENSE.txt for details.

StenoTutor - Learn to stenotype
===============================

With StenoTutor you can learn to stenotype on your QWERTY keyboard, thanks to [Plover](https://github.com/plover/plover), an open source framework which transforms your QWERTY keyboard in a stenograph, while still providing full control of your operating system.

StenoTutor is a free software available for GNU/Linux, Windows and Mac (not tested on Mac, please let me know if it works), and requires a recent Java runtime installed and Plover 2.4.x installed and running. It is coded in Processing IDE 2.x.

StenoTutor is smart: words that takes you longer to type have more possibilites of showing up, so you will spend most of your time working on your weaknesses. It also allows to blacklist some words, in case you don't have a NKRO keyboard yet and you just want to see if you enjoy steno and how well you speed up, without being annoyed by words that your keyboard cannot actually type.

Lessons have been copied from a similar project called [Fly](https://launchpad.net/flyploverfly).

The StenoTutor application was initially developed and published by Emanuele Caruso.

Installation
------------

* Download and extract binary distribution in a directory of your choice.
* Optionally tweak session.properties in "data/" subdirectory.
* Run Plover. It can be disabled, but it must be running.

1. Linux - 
Make StenoTutor script executable:
     chmod +x StenoTutor
Run StenoTutor:
    ./StenoTutor

2. Windows - 
Double-click StenoTutor.bat

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

Known Bugs
----------
* Using the '*' key too many times doesn't work, so in case of many consecutive errors for the same word it is impossible to clear the input buffer. This is not a big issue because you usually press the '*' immediately after one or two errors to clean the input buffer as soon as possible, but it must be fixed.
* There is no check for the completion of the lesson dictionary, so there are no greetings yet and there may be errors too.
* Unrecognized strokes are not printed at all, while the chord should be actually printed and manually deleted by the student.
* Unlocked and total words count don't take blacklist words into account

Planned Features and Future Enhancements
----------------------------------------
* Show worst 5 words and their average WPM
* QWERTY/steno on-screen keyboard
* Highlight next chord on keyboard and color highlighting as well.
* Alphabet training mode
* Sentence training mode
* Options to show/hide the various info and features
* In word training mode, add an option to pre-compute and show multiple words at a time, to provide a typing experience similar to many online multiplayer typing games and more similar to real world typing
* Save session statistics in txt files
* Accuracy recording, including average session accuracy, accuracy level up limits, average accuracy per word and a mixed speed/accuracy based word selection
* Font colors and GUI colors configuration file
* GUI interface, eg: buttons