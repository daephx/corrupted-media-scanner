# Corrupted Media Scanner
Uses handbrake to check if files are corrupted or unplayable

## Instructions
---

Right-click then press 'run with powershell' or run from powershell window

Example run: `.\scan.ps1 -dir 'c:\media\directory' -threads 4`

<b>-dir</b> This is your media directory

<b>-threads</b> This is how many handbrake instances will run at once, I recommend running less than 4 unless you have a really good CPU

`good.log` will be generated in the root directory with files that are OK

`error.log` will be generated in the root directory with information about corrupted files

- <b>EBML header parsing failed</b>: highly likely this file won't play
- <b>Read error</b>: there are problems in the file but it usually can still play