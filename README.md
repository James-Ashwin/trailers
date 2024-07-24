# trailers.ps1
Powershell script that can be used to add trailers to your movie collection.  It can be used stand alone or triggered by Radarr.

This came about because I use my Roku mostly for Jellyfin.  And I wanted trailers that my Roku will recognize and play through my Jellyfin client.  So i smashed some shit together and this is the end result.

### Requirements
- YT-DLP
- Powershell
- A movie library with naming convention starting with {Movie Title} ({Release Year}), example: Ghostbusters - (1984).

### Installation
- Download and extract in a directory of your choice.
  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.

### Use Stand Alone
This is good to do for the first use.
- Open a PowerShell window.
- Navigate to the installation folder.
- Launch .\trailers.ps1 PATH_TO_MY_LIBRARY_ROOT_FOLDER (ex: z:\movies).
- Wait for the script to finish.

The first run will take a little bit of time depending on the size of your collection. You can monitor download progress in the Powershell window or directly inside the most recent log file stored under \logs.

### Connect with Radarr
In Radarr, create a new Custom Script connection (Settings > Connect > + > Custom Script) that triggers on Import and on Rename. Set the path to your copy of trailers.ps1.  Test the connection, if all is good, enjoy.
