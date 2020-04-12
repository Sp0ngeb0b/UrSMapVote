class UrSMapVoteConfig extends NexgenPluginConfig;

// Map Vote Settings
var config int opendelay;
var config int voteLimit;
var config int midGameVotePercent;
var config string gameType;
var config int repeatLimit;
var config string votedMaps[32];
var config string infoTips[8];
var config float tipDuration;
var config byte tipColorR;
var config byte tipColorG;
var config byte tipColorB;
var config int defaultScore;
var config int defaultTime;
var config int defaultSpeed;
var config string mapSettings[128];

const seperator = ",";

/***************************************************************************************************
 *
 *  $DESCRIPTION  Automatically installs the Nexgen Smart Keybinds.
 *  $ENSURE       lastInstalledVersion >= xControl.versionNum
 *
 **************************************************************************************************/
function install() {

  if (lastInstalledVersion < 100) installVersion100();
  
  lastInstalledVersion = 100;
  
  super.install();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the mapName from the config string
 *
 **************************************************************************************************/
function string getMap(int index) {
  local string data;
  
  data = mapSettings[index];
  
  if(data == "") return "";
  
  return Left(Data, InStr(Data, seperator));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the teamscore from the config string
 *
 **************************************************************************************************/
function int getTeamScore(int index) {
  local string data;

  data = mapSettings[index];
  
  // Remove mapName
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(Left(Data, InStr(data, seperator)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the timelimit from the config string
 *
 **************************************************************************************************/
function int getTimeLimit(int index) {
  local string data;

  data = mapSettings[index];

  // Remove map name and team score
  data = mid(data, InStr(data, seperator)+Len(seperator));
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(Left(Data, InStr(data, seperator)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the gamespeed from the config string
 *
 **************************************************************************************************/
function int getGameSpeed(int index) {
  local string data;

  data = mapSettings[index];

  // Remove map name, team score and time limit
  data = mid(data, InStr(data, seperator)+Len(seperator));
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(mid(Data, InStr(data, seperator)+Len(seperator)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Automatically installs version 100 of the Nexgen Smart Keybinds.
 *
 **************************************************************************************************/
function installVersion100() {
  opendelay = 10;
  voteLimit = 60;
  midGameVotePercent = 51;
  gameType = "Botpack.CTFGame";
  repeatLimit = 5;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
}
