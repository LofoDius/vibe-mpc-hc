Track preference matching can be checked independently of MFC:

    g++ -std=c++11 tests/TrackPreferenceTest.cpp -o build/TrackPreferenceTest.exe
    build/TrackPreferenceTest.exe

For the settings dialog, check both OK and Apply with an invalid expression
(such as "["), including after switching to another settings page. The dialog
must stay open, select the invalid field, and leave settings unapplied.
Also check empty expressions, saving/reopening valid expressions, and track
names whose matching text is in the middle or end of the name.
