### SteamTool
Bash script for managing SteamDeck proton installed games via the ProtonTricks Flatpak.

For ease of use move this script to a location of your choice (*i use Documents/Linux-Scripts*) then symlink the script to **~/.local/bin/steamtool**, make sure **~/.local/bin** is part of your **PATH**.
---------------------------------------------------------------------------------------------

### List of available commands.

**--find**
use without any arguments to list all steam games and all non-steam games, non-steam games are only
found in the paths used & setup in your steam client.
  
**--find Name**
Same as above but only lists games containing the text you specify.

### When using --find all output will be prefixed with an Index number, this Index number is used for all other commands

**--open Index**
Opens the start-in or install path for the selected game via Index number in Dolphin File Browser.
  
**--exe Index**
When you have 'Found' a list of games this will list all executables found in the Index Number you specify.

**--run Index**
When you have a list of Executables for the Index you specified this will launch the selected executable via its Index number.

**--deps Index DepList**
this can install up to 13 dependancys, if more are required then enclose them all in double quoptes
As usual with ProtonTricks, there will often be issues installing dependencies as not all function correctly such as .NET Framework
