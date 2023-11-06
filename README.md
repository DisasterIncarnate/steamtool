## SteamTool
Bash script for managing SteamDeck proton installed games via the ProtonTricks Flatpak, using this script you can search for games you have installed, directly open their install/start-in folders, run executables in a games own proton container (*handy for modders or applying patches to older games*) and you can install extra required dependencies.

For ease of use move this script to a location of your choice (*i use Documents/Linux-Scripts*) then symlink the script to **~/.local/bin/steamtool**, make sure **~/.local/bin** is part of your **PATH**.  This script will checks PATH for this location and will add the needed PATH to your .bashrc file if needed. 

## List of available commands.

**--find**

use without any arguments to list all steam games and all non-steam games, non-steam games are only found in the paths used & setup in your steam client.
  
**--find Name**

Same as above but only lists games containing the text you specify.

## To use all other commands a --find command must be used to generate an index of files which all other commands use, the same applies to --exe which generates a separate index list for use with --run, these index lists are retained until a new --find or --exe is used.

**--open Index**

Opens the start-in or install path for the selected game via Index number in Dolphin File Browser.
  
**--exe Index**

When you have 'Found' a list of games this will list all executables found in the Index Number you specify.

**--run Index**

When you have a list of Executables for the Index you specified this will launch the selected executable via its Index number.

**--deps Index DepList**

this can install up to 13 dependencies, if more are required then enclose them all in double quoptes.  As usual with ProtonTricks, there will often be issues installing dependencies as not all function correctly such as .NET Framework

![Alt text](/steamtool.jpg?raw=true "SteamTool Screenshot")

https://www.youtube.com/watch?v=4NFKpRzDQQc
