# VlcTranscodeAudioCD
PowerShell script to automatically transcode audio CD tracks to MP3 using VLC.

## About
The script can be used to transcode all tracks of an audio CD automatically on a per-track basis (as opposed to create one single file).
It uses meta data look up to get the track titles (using VLC) and transcodes the individual tracks into single MP3 files.

## Pre-Requisites
* VLC media player installed (https://www.videolan.org/)
* PowerShell
  
## Usage
1. Ensure audio device (CD player) is attached to machine and ready.
2. Ensure the audio CD is in the audio device.
3. Open a PowerShell console.
4. Source the script e.g. ```. {path to script (*.ps1)}```.
5. Run command ```TranscodeAudioCD "{audio device e.g. D:}" "{output directory}"```. This uses the stream MRL: 'cdda:///{audio device}'.

__Beware: Any pending VLC process (vlc.exe) is stopped by the script!__

Complete example:
```
PS C:\Users\MrX>  . C:\Temp\TrancodeAudioCD.ps1
PS C:\Users\MrX> TranscodeAudioCD "D:" "C:\Temp"
Start transcoding audio CD..
Audio CD has 11 tracks
- Transcoding track 1 to 'C:\Temp\1 Titellied.mp3'
- Transcoding track 2 to 'C:\Temp\2 Ziemlich cooles Script.mp3'
- Transcoding track 3 to 'C:\Temp\3 Dieser verflixte Transcoder.mp3'
- Transcoding track 4 to 'C:\Temp\4 Und noch mal weg.mp3'
- Transcoding track 5 to 'C:\Temp\5 Schatzsuche.mp3'
- Transcoding track 6 to 'C:\Temp\6 Ein Fall für mich.mp3'
- Transcoding track 7 to 'C:\Temp\7 Oma kommt zu Besuch.mp3'
- Transcoding track 8 to 'C:\Temp\8 Schatzkästchen.mp3'
- Transcoding track 9 to 'C:\Temp\9 Endlich eine Katze.mp3'
- Transcoding track 10 to 'C:\Temp\10 Eine Freude.mp3'
- Transcoding track 11 to 'C:\Temp\11 Ende.mp3'
Transcoding audio CD completed. Took 272.271sec.

PS C:\Users\MrX>
```

## Remarks

* The PowerShell script obviously targets the Windows OS. There also Windows specifics related to stream MRL syntax and path handling. They need to be adjusted for other OSs e.g. Linux.
* Currently the audio settings are hard-coded to MP3. Adjust as needed. Refer to [VLC Wiki](https://wiki.videolan.org) for information and ```vlc.exe --help``` / ```vlc.exe -H``` for commad line details.
* Tested with PowerShell 5.1.22621.4391.

Other approaches I used in the past or know of:

* The simplest form of transcodeing, which is also documented on https://wiki.videolan.org/Transcode/, is to transcode the audio CD using the command line (either remote or no interface).
  This creates a single large file (track) that contains the entire audio CD. Depending on the use case, this is fine. In my case I found it difficult on some devices to fast-forward to the desired location.
  The web page also outlines a batch-approach using a Bash script, similar to the PowerShell script here.
  
* There is a Lua extension (OMG.lua) that can be used to get track titles and convert it to MP3 or similar.
  It works by loading the audio CD first, then invoke the extension which shows dialog window to review the collected meta data and initiate transcoding.
  Works fairly well, but is a semi-automated solution and I had issue with the titles (e.g. German 'Umlaute').
  Reference: https://gist.github.com/zcot/bc9f349f7507ae4d645bbf31065738e2
