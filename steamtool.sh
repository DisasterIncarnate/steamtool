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
  # File doesnt exist, so lets setup a RamDick and make the file Exist
  mkdir /dev/shm/SteamTool
  echo "OK" > /dev/shm/SteamTool/RAMACTIVE
fi

# Check for different Steam installs.
# Find main LibraryFolder.VDF file location.
MAINVDF=`find /home/$USER -maxdepth 6 -name "libraryfolders.vdf" | grep -i "steamapps"`
if [[ ${1,,} == "--exe" ]] || [[ ${1,,} == "--open" ]] || [[ ${1,,} == "--run" ]]; then
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
      echo "Setup the environment and APPID required by ProtonTricks which this script uses..."
      echo "------------------------------------------"
      find "$xtrpath" -type f \( -iname \*.exe -o -iname \*.com -o -iname *.bat \) > /dev/shm/SteamTool/test-exelist
      echo "INDEX   LOCATION"
      cat -b -n /dev/shm/SteamTool/test-exelist
    fi
    if [[ ${1,,} == "--open" ]]; then
      echo "Opening selected game folder..."
      dolphin "$xtrpath" > /dev/null 2>&1
    fi
    if [[ ${1,,} == "--run" ]]; then
      if [[ $2 == "" ]]; then
        echo "You need to provide an Index number..."
      else
        if test -f "/dev/shm/SteamTool/test-lastexe"; then
          echo "Running Executable in Game Location..."
          echo "Please Wait..."
          echo ""
          lastexe=$(cat /dev/shm/SteamTool/test-lastexe)
          xtrid=$(sed -n "$lastexe"p /dev/shm/SteamTool/test-id)
          xtrexe=$(sed -n "$2"p /dev/shm/SteamTool/test-exelist)
          WINEESYNC=1 WINEFSYNC=1 flatpak run --command=protontricks-launch com.github.Matoking.protontricks --appid "$xtrid" "$xtrexe" > /dev/null 2>&1
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

basedir=$(find /home/$USER -maxdepth 6 -name "steamapps" | grep -i ".steam/")

GINDEX=0
paths="/dev/shm/SteamTool/test-paths"

# do clever stuff for compatdata/non-steam installed games and find start-in path which we cant get
# from the usual text based .VDF file(s), as the .VDF file used for non-steam game locations/etc is binary.
# and i am not smart enough to extract the information frmo a binary file, so we have this workaround.
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
        flatpak run com.github.Matoking.protontricks -c pwd $newid >> /dev/shm/SteamTool/test-locat
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
