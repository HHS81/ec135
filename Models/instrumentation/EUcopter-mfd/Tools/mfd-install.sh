#!/bin/bash
# install EUcopter panels in aircraft directory and replace path strings in all xml files
# use mfd-install.sh <aircraft> <install-sub-dir>, e.g. "mfd-install.sh ec145 Models/instruments"

if [ -d "/usr/share/games/flightgear/Aircraft/${1}/${2}/EUcopter-mfd" ] ; then
  echo ">>>>> Found old Panel files, removing <<<<<" 
  rm -rf /usr/share/games/flightgear/Aircraft/${1}/${2}/EUcopter-mfd
fi

mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd"
mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd/Panels"
mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd/XML"
mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd/Textures"
mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd/Tools"
mkdir "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd/Nasal"

for file in `cat mfd-file-list`; do 
   cp "/usr/share/games/flightgear/Aircraft/Instruments-3d/$file" "/usr/share/games/flightgear/Aircraft/$1/$2/$file" ; 
done
cd "/usr/share/games/flightgear/Aircraft/$1/$2/EUcopter-mfd"

#set -x
sed -i "s|Aircraft/Instruments-3d/EUcopter-mfd|Aircraft/${1}/${2}/EUcopter-mfd|g" ./*.xml
sed -i "s|Aircraft/Instruments-3d/EUcopter-mfd|Aircraft/${1}/${2}/EUcopter-mfd|g" ./XML/*.xml
sed -i "s|Aircraft/Instruments-3d/EUcopter-mfd|Aircraft/${1}/${2}/EUcopter-mfd|g" ./Panels/*.xml

cd /usr/share/games/flightgear/Aircraft/$1

if grep "Aircraft/${1}/${2}/EUcopter-mfd" ./$1-set.xml ; then
  echo ">>>>> Panel is already configured for ${1} in subdir ${2} <<<<<" 
  exit 1
fi

if grep "<!--<instrumentation>" ./$1-set.xml ; then
  echo ">>>>> Current ${1}-set file has outcommented instrumentation section, remove before re-running mfd-install <<<<<" 
  exit 1
fi

if grep "<!--<systens>" ./$1-set.xml ; then
  echo ">>>>> Current ${1}-set file has outcommented systems section, remove before re-running mfd-install <<<<<" 
  exit 1
fi

if grep "<!--<nasal>" ./$1-set.xml ; then
  echo ">>>>> Current ${1}-set file has outcommented nasal section, remove before re-running mfd-install <<<<<" 
  exit 1
fi

if grep "<!--<efis>" ./$1-set.xml ; then
  echo ">>>>> Current ${1}-set file has outcommented efis section, remove before re-running mfd-install <<<<<" 
  exit 1
fi

mv ./$2/EUcopter-mfd/Nasal/masterlist-aircraft.nas ./Nasal/masterlist-$1.nas 
cp ./$1-set.xml ./$1-set__backup__.xml 

if grep "Instruments-3d/EUcopter-mfd" ./$1-set.xml; then
  sed -i "s|Aircraft/Instruments-3d/EUcopter-mfd|Aircraft/${1}/${2}/EUcopter-mfd|g" ./Models/instruments.xml   
else  
  sed -i "s|<nasal>|<nasal>\n                   <mfd>\n                      <file>Aircraft/${1}/${2}/EUcopter-mfd/Nasal/mfd.nas</file>\n                      <file>Aircraft/${1}/${2}/EUcopter-mfd/Nasal/masterlist.nas</file>\n                     <file>Aircraft/${1}/${2}/EUcopter-mfd/Nasal/helionix-terrain-map.nas</file>\n                      <file>Aircraft/${1}/Nasal/masterlist-${1}.nas</file>\n                </mfd>\n|" ./${1}-set.xml
                        
  sed -i "s|<systems>|<systems>\n     <autopilot n=\"101\">\n       <name>Helionix instrumentation drivers</name>\n       <path>Aircraft/${1}/${2}/EUcopter-mfd/XML/filter.xml</path>\n    </autopilot>\n|" ./${1}-set.xml 
  sed -i -e "/<efis>/r ./${2}/EUcopter-mfd/Tools/efis-template" ./${1}-set.xml 
  sed -i -e "/<instrumentation>/r ./${2}/EUcopter-mfd/Tools/instrumentation-template" ./${1}-set.xml 
fi

if [ -f ./Models/instruments.xml ] ; then
   cp ./Models/instruments.xml ./Models/instruments__backup__.xml 
   sed -i "s|Aircraft/Instruments-3d/EUcopter-mfd|Aircraft/${1}/${2}/EUcopter-mfd|g" ./Models/instruments.xml   
fi

