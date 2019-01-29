# Corrupted Media Scanner
Uses handbrake to check if files are corrupt or unplayable

## Instructions

Clone or download project

Download HandBrakeCLI.exe for Windows from https://handbrake.fr/downloads2.php and place it in same directory as scan.ps1

Right-click `scan.ps1` then press 'run with powershell' or run from powershell window

Example run: `.\scan.ps1 -dir 'c:\media\directory' -threads 4`

<u>Required</u>

<b>-dir</b> This is your media directory

<b>-threads</b> This is how many handbrake instances will run at once, I recommend running less than 4 unless you have a really good CPU

<u>Optional</u>

<b>-min</b> Minimum size of files to scan in MegaBytes (default=5) set to 0 to scan pictures, nfo files, etc

`good(yyyyMMddmmss).log` will be generated in the root directory with files that are OK

`error(yyyyMMddmmss).log` will be generated in the root directory with information about corrupted files

`(yyyyMMddmmss).csv` will be generated in the root directory with information about all files in a csv

- <b>EBML header parsing failed</b>: highly likely this file won't play
- <b>Read error</b>: there are problems in the file but it <i>usually</i> can still play

## Screenshots:

In progress: 

![In Progress](https://i.imgur.com/UuzdrZg.png)

Completed: 

![Completed](https://i.imgur.com/A0GjMeK.png)

