#!/bin/bash
PROCESSCMD="False"

# To save wear and tear of devices such as SSD's we will use a premade RAMDISK
# To store our temporary files which will simply vanish when rebooting, thus not
# Adding needless clutter to our system, which does not need to persist.
# /dev/shm is a user accessible TMPFS ramdisk which does not require sudo access
# and can be used by anyone, the contents are lost every reboot as per usual.
# This is up and running as standard, mothing to install/setup, ready to use.
TESTRAM="/dev/shm/SteamTool/RAMACTIVE"
if ! test -f "$TESTRAM"; then
  # File doesnt exist, so lets setup a RamDisk and make the file Exist
  mkdir /dev/shm/SteamTool
  echo "OK" > /dev/shm/SteamTool/RAMACTIVE
fi

# Check that PATH includes $HOME/.local/bin
CWARN="NONE"
CHKA=$(cat $HOME/.profile | grep -i "HOME/.local/bin:" | grep -i "PATH")
CHKB=$(cat $HOME/.bashrc | grep -i "HOME/.local/bin:" | grep -i "PATH")
if [[ $CHKA == "" ]] && [[ $CHKB == "" ]]; then
  # No PATH Found, add PATH to .bashrc
  echo 'if [ -d "$HOME/.local/bin" ] ; then' >> $HOME/.bashrc
  echo 'PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
  echo 'fi' >> $HOME/.bashrc
  echo "PATH was not set to check $HOME/.local/bin for scripts/commands, this has been corrected."
  echo "** You need to close this terminal window and re-open for changes to take effect **"
  CWARN="YES"
fi

# Check user has the Flatpak ProtonTricks installed and give options if not found.
CHKA=$(cat $HOME/.profile | grep -i "protontricks" | grep -i "alias")
CHKB=$(cat $HOME/.bashrc | grep -i "protontricks" | grep -i "alias")
if [[ $CHKA == "" ]] && [[ $CHKB == "" ]]; then
  # Register alias for protontricks to launch flatpak protontricks
  echo "alias protontricks='flatpak run com.github.Matoking.protontricks'" >> $HOME/.bashrc
  echo "alias protontricks-launch='flatpak run --command=protontricks-launch com.github.Matoking.protontricks'" >> $HOME/.bashrc
  CWARN="YES"
fi

if [[ $CWARN == "YES" ]]; then
  echo Additions have been made to your $HOME/.bashrc file to make using this script and protontricks easier...
  echo Close this terminal window and relaunch for changes to take effect...
  echo
  exit
fi

CHKC=$(flatpak run com.github.Matoking.protontricks -V | grep -i "not installed" 2>/dev/null)
if [[ $CHKC != "" ]]; then
  echo "This script requires Protontricks, Please install via the Discover Store or"
  echo "open konsole and type: flatpak install flathub com.github.Matoking.protontricks"
  echo ""
  exit
fi

# Show commandlist if nothing if no commands specified
if [[ ${1,,} == "" ]]; then
  echo "HELP: List of available commands"
  echo "--------------------------------"
  echo "--find and --exe produce a numbered/indexed list which the other commands use for ease of use."
  echo "EG: if you used --find Skyrim and you only had 1 skyrim game it would be listed as '1 Skyrim'"
  echo "you could then use --open 1 or --exe 1 to refer to skyrim instead of finding the details the long way."
  echo "--------------------------------"
  echo ""
  echo "--find                  Lists all Steam and Non-Steam games detected by ProtonTricks."
  echo "--find <name>           Lists only games partially matching the word you enter."
  echo ""
  echo "--open <index>          Opens Dolphin Browser in the location of a games install/start-in path."
  echo "--deps <index> <list>   Install dependency(s) into a games proton container."
  echo "--exe <index>           Lists all .bat .com & .exe files in the proton container you select."
  echo "--search <index> <name> List all files in <index> partially matching the word you enter."
  echo "--run <index>           Attempt to launch an executable in your previously specified proton container."
  exit
fi

# Check for different Steam installs.
# Find main LibraryFolder.VDF file location.
MAINVDF=`find /home/$USER -maxdepth 8 -name "libraryfolders.vdf" | grep -i "steamapps"`
if [[ ${1,,} == "--exe" ]] || [[ ${1,,} == "--open" ]] || [[ ${1,,} == "--run" ]] | [[ ${1,,} == "--search" ]]; then
  # Find common windows executable files.
  if [[ $2 == "" ]]; then
    echo "Enter an index number to continue..."
  else
    xtrpath=$(sed -n "$2"p /dev/shm/SteamTool/test-locat)
    if [[ ${1,,} == "--exe" ]]; then
      rm -f /dev/shm/SteamTool/test-lastexe >/dev/null
      echo $2 > /dev/shm/SteamTool/test-lastexe
      echo "Listing common Windows executable files..."
      echo "Use 'steamtool --run <indexnumber>' to launch a listed executable file..."
      echo "You can only --run files if you have launched a game at least once to"
      echo "use the environment and APPID required by ProtonTricks which this script uses..."
      echo "------------------------------------------"
      find "$xtrpath" -type f \( -iname \*.exe -o -iname \*.com -o -iname *.bat -o -iname \*.AppImage \) > /dev/shm/SteamTool/test-exelist
      echo "INDEX   LOCATION"
      cat -b -n /dev/shm/SteamTool/test-exelist
    fi
    if [[ ${1,,} == "--open" ]]; then
      echo "Opening selected game folder..."
      dolphin "$xtrpath" > /dev/null 2>&1 &
    fi

    if [[ ${1,,} == "--search" ]]; then
      if [[ $2 == "" ]]; then
        echo "You need to provide an Index number..."
      else
        if [[ $3 == "" ]]; then
          echo "I need something to search for..."
        else
          echo "List of files containing '$3'..."
          find "$xtrpath" -type f \( -iname \*$3* \) > /dev/shm/SteamTool/test-searchlist
          cat -b -n /dev/shm/SteamTool/test-searchlist
        fi
      fi
    fi

    if [[ ${1,,} == "--run" ]]; then
      if [[ $2 == "" ]]; then
        echo "You need to provide an Index number..."
      else
        if test -f "/dev/shm/SteamTool/test-lastexe"; then
          echo "Running Executable in Game Location..."
          echo "Please Wait, this can take a while depending on the game..."
          echo "Creating 'SteamTool-Exe-Log.txt' Logfile in your Documents folder"
          echo ""
          lastexe=$(cat /dev/shm/SteamTool/test-lastexe)
          xtrid=$(sed -n "$lastexe"p /dev/shm/SteamTool/test-id)
          xtrexe=$(sed -n "$2"p /dev/shm/SteamTool/test-exelist)
          WINEESYNC=1 WINEFSYNC=1 flatpak run --command=protontricks-launch com.github.Matoking.protontricks --appid "$xtrid" "$xtrexe" > $HOME/Documents/SteamTool-Exe-Log.txt 2>&1 &
        else
          echo "Cannot --run something until you have used --exe to search for runnable files..."
          echo ""
        fi
      fi
    fi
  fi
fi

if [[ ${1,,} == "--find" ]]; then
  rm -f /dev/shm/SteamTool/test-lastexe >/dev/null
  if [[ $2 == "" ]]; then
  # List everything found in Steam Manifests (does not include non-steam games)
  full_process="True"
  PROCESSCMD="True"
  else
  # List matching search found in Steam Manifests (does not include non-steam games)
  full_process="False"
  PROCESSCMD="True"
  fi
fi

if [[ ${1,,} == "--deps" ]]; then
  if [[ $2 == "" ]]; then
    echo "You need to provide an Index number..."
  else
    xtrid=$(sed -n "$2"p /dev/shm/SteamTool/test-id)
    if [[ $3 == "" ]]; then
      echo "Specify the Dependency you need to install...   (EG: corefonts)"
    else
      # Run protontricks and try to install dependencies
      WINEESYNC=1 WINEFSYNC=1 flatpak run com.github.Matoking.protontricks "$xtrid" $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} #>/dev/null 2>&1
      echo ""
    fi
  fi
fi

if [[ $PROCESSCMD == "True" ]]; then
echo "Checking all Steam locations, please wait..."
echo ""
# Clean up some temporary files..
rm -f /dev/shm/SteamTool/test-id >/dev/null
rm -f /dev/shm/SteamTool/test-name >/dev/null
rm -f /dev/shm/SteamTool/test-locat >/dev/null
rm -f /dev/shm/SteamTool/test-paths >/dev/null
rm -f /dev/shm/SteamTool/compat-paths >/dev/null

for file in $MAINVDF; do
    if [[ ! -e "$file" ]]; then
      echo "No files exist in $app_mani_dir"
      exit 1
    fi
  base_dir=$(grep '"path"' "$file" | cut -d'"' -f4)
  echo $base_dir | tr " " "\n" > /dev/shm/SteamTool/test-paths
done

basedir=$(find /home/$USER -maxdepth 8 -name "steamapps" | grep -i ".steam/")

GINDEX=0
paths="/dev/shm/SteamTool/test-paths"

# do clever stuff for compatdata/non-steam installed games and find start-in path which we cant get
# from the usual text based .VDF file(s), as the .VDF file used for non-steam game locations/etc is binary.
# and i am not smart enough to extract the information from a binary file, so we have this workaround.
flatpak run com.github.Matoking.protontricks -l | grep -i "Non-Steam shortcut" | grep -i "$2" 1>/dev/shm/SteamTool/compat-paths 2>/dev/null
while IFS= read -r line; do
    newname=${line/"Non-Steam shortcut: "/}
    newname=${newname::-13}
    newid=${line: -11}
    newid=${newid::-1}
    if [[ $newname != "" ]]; then
      let GINDEX=GINDEX+1
      if [[ $GINDEX -eq "1" ]]; then
        echo "INDEX  APPID      TITLE"
      fi
      if [[ "$1" != "--run" ]] && [[ "$1" != "--open" ]]; then
        printf "%6d " "$GINDEX"
        printf "%-11s" "$newid"
        echo "$newname (Non-Steam)"
        echo $newid >> /dev/shm/SteamTool/test-id
        echo $newname >> /dev/shm/SteamTool/test-name
        newname=$(flatpak run com.github.Matoking.protontricks --no-runtime -c "env" $newid | grep "STEAM_APP_PATH" 2>/dev/null)
        echo "${newname:15}" 1>>/dev/shm/SteamTool/test-locat 2>/dev/null

      else
        if [[ $2 == $GINDEX ]]; then
          echo "Match: $GINDEX $app_id $app_name"
        fi
      fi
    fi
done < ""/dev/shm/SteamTool/compat-paths""

# Do clever stuff for regular steam games
while IFS= read -r line
do
  base_dir=$line
  app_mani_dir="${base_dir}/steamapps/appmanifest*.acf"
  compat_dir="${base_dir}/steamapps/compatdata"
    for file in ${app_mani_dir}; do
      if [[ ! -e "$file" ]]; then
        # Do nothing..... currently at least.
        printf ""
      else
      # Extract app id and name from appmanifest files
      app_id=$(grep '"appid"' "$file" | cut -d'"' -f4)
      app_name=$(grep '"name"' "$file" | cut -d'"' -f4)
      app_locat=$(grep '"installdir"' "$file" | cut -d'"' -f4)

      if [[ $full_process == "True" ]]; then
        process_entry="True"
      else
        if grep -q -i "$2" <<< "$app_name"; then
          process_entry="True"
        else
          process_entry="False"
        fi
      fi

      if [[ $process_entry == "True" ]]; then
        if [[ $app_id != "" ]]; then
          let GINDEX=GINDEX+1
          if [[ $GINDEX -eq "1" ]]; then
            echo "INDEX  APPID      TITLE"
          fi
          if [[ "$1" != "--run" ]] && [[ "$1" != "--open" ]]; then
            printf "%6d " "$GINDEX"
            printf "%-11s" "$app_id"
            echo $app_name
            echo $app_id >> /dev/shm/SteamTool/test-id
            echo $app_name >> /dev/shm/SteamTool/test-name
            echo $base_dir/steamapps/common/$app_locat >> /dev/shm/SteamTool/test-locat
          else
            if [[ $2 == $GINDEX ]]; then
              echo "Match: $GINDEX $app_id $app_name"
            fi
          fi
        fi
        fi
      fi
    done
done < "$paths"
echo ""
fi
