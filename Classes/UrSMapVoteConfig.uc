class UrSMapVoteConfig extends NexgenPluginConfig;

// Map Vote Settings
var config int opendelay;
var config int votelimit;
var config int MidGameVotePercent;
var config string GameType;
var config int RepeatLimit;
var config string votedMaps[32];
var config string infoTips[8];
var config float tipDuration;
var config byte tipColorR;
var config byte tipColorG;
var config byte tipColorB;

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
 *  $DESCRIPTION  Automatically installs version 100 of the Nexgen Smart Keybinds.
 *
 **************************************************************************************************/
function installVersion100() {
  opendelay = 10;
  votelimit = 60;
  MidGameVotePercent = 51;
  GameType = "Botpack.CTFGame";
  RepeatLimit = 5;
}

defaultproperties
{
}
