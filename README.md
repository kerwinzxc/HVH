# HVH

Hunter v. Hunted custom game for DOTA 2. See http://steamcommunity.com/sharedfiles/filedetails/?id=514589800

## Setup
The easiest way to run the game from development files is to link the directories to the necessary locations.

- Start an elevated command prompt
- Create a directory symbolic link for the game directory
```
mklink /J "<Path to dota 2 beta>\game\dota_addons\hunter_v_hunted" "<Path to clone location>\game\hunter_v_hunted"
```
- Create a directory symbolic link for the content directory
```
mklink /J "<Path to dota 2 beta>\content\dota_addons\hunter_v_hunted" "<Path to clone location>\content\hunter_v_hunted"
```
- Launch addon with the Dota 2 Reborn beta tools
