# trailers.ps1
Powershell script that can be used to add trailers to your movie collection.  It can be used stand alone or triggered by Radarr.

This came about because I wanted trailers that my Roku will recognize and play through my Jellyfin client.  So I smashed some shit together that worked for me and this is the end result.

----------

### Requirements
- YT-DLP
- Powershell
- A movie library with the naming convention {Movie Title} ({Release Year}), example: Ghostbusters - (1984).

----------

### Installation
- Download and extract in a directory of your choice.
  If you want to connect it to Radarr make sure it is in a directory that is visible to your Radarr installation.

----------

### Use Stand Alone
This is good to do for the first use.
- Open a PowerShell window.
- Navigate to the installation folder.
- Launch .\trailers.ps1 PATH_TO_MY_LIBRARY_ROOT_FOLDER (ex: z:\movies).
- Wait for the script to finish.

The first run will take a little bit of time depending on the size of your collection.
You can monitor download progress in the Powershell window or in the most recent log file stored under \logs.

----------

### Connect with Radarr
- Open Radarr
- Create a new Connection
  - Settings > Connect > + > Custom Script
- Set the Notification Triggers to 'On Import' and 'On Rename'.
- Set the path to your copy of trailers.ps1.
- Test the Connection.
- Save the Connection.

----------

### Customize
