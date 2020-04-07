// Private Nexgen Plugin for UrS
// UrSMapVote (C) 2020 by Patrick 'Sp0ngeb0b' Peltzer
// Based on BDBMAPVOTE code, implements frontend in Nexgen
/*
  Changelog Version 2b:
    - Fixed talking prompt being closed with vote window for real
    - First tip to be displayed selected randomly now
    - Implements features of UrSMapSettings
    
  Changelog Version 2:
    - Fixed talking prompt being closed with vote window
    - Spectators also have access to vote tab now
    - Added tips displayed in the tab
*/
class UrSMapVoteMain extends NexgenExtendedPlugin;

var int versionNum;                     // Plugin version number.

var bool bGameEnded;
var int TimeLeft;
var int delayTime;
var int MapCount;
var bool bLevelSwitchPending;
var string ServerTravelString;
var int Delay;

var int MAPVOTECOUNTS[100];
var string MAPVOTENAME[100];
var bool   bMidGameVote;
var int    PlayerIDList[32];
var int    PlayerVote[32];
var int    ServerTravelTime;
var string maplist[128];
var bool bReadMaps;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the plugin. Note that if this function returns false the plugin will
 *                be destroyed and is not to be used anywhere.
 *  $RETURN       True if the initialization succeeded, false if it failed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool initialize() {
  local int index;
  local string levelFile;

  // Let super class initialize.
  if (!super.initialize()) {
    return false;
  }

  // Check Repeat list
  for (index = UrSMapVoteConfig(xConf).RepeatLimit; index < arrayCount(UrSMapVoteConfig(xConf).votedMaps); index++) {
    if (UrSMapVoteConfig(xConf).votedMaps[index] != "") {
      UrSMapVoteConfig(xConf).votedMaps[index] = "";
    }
  }
  UrSMapVoteConfig(xConf).saveconfig();
  
  // Adjust map settings for current map
  levelFile = class'NexgenUtil'.static.getLevelFileName(level);
  for (index = 0; index < arrayCount(UrSMapVoteConfig(xConf).mapSettings); index++) {
    if (levelFile == UrSMapVoteConfig(xConf).getMap(index)) {

      // Modify TeamScoreLimit
      setTeamScoreLimit(UrSMapVoteConfig(xConf).getTeamScore(index));

      // Modify TimeLimit
      setTimeLimit(UrSMapVoteConfig(xConf).getTimeLimit(index));

      // Modify GameSpeed
      setGameSpeed(UrSMapVoteConfig(xConf).getGameSpeed(index));

      break;
    }
  }
  if (index == arrayCount(UrSMapVoteConfig(xConf).mapSettings)) {
    setTeamScoreLimit(UrSMapVoteConfig(xConf).defaultScore);
    setTimeLimit(UrSMapVoteConfig(xConf).defaultTime);
    setGameSpeed(UrSMapVoteConfig(xConf).defaultSpeed);
  }
      
  // Add new right type
  control.sConf.addRightDefiniton("mapsettings", "Modify map settings.");
  
  return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the plugin requires the to shared data containers to be created. These
 *                may only be created / added to the shared data synchronization manager inside this
 *                function. Once created they may not be destroyed until the current map unloads.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function createSharedDataContainers() {
  dataSyncMgr.addDataContainer(class'UrSMapVoteConfigDC');
  dataSyncMgr.addDataContainer(class'UrSMapSettingsConfigDC');
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Mutate Commands.
 *  $PARAM        MutateString  The mutate command.
 *  $PARAM        Sender  PlayerPawn who sent the command.
 *
 **************************************************************************************************/
function Mutate(string MutateString, PlayerPawn Sender) {
  local UrSMapVoteClient xClient;
  local string MapName;

  Super.Mutate(MutateString, Sender);

  xClient = UrSMapVoteClient(getXClient(sender));
  if (xClient == none) return;

  if(left(Caps(MutateString),10) == "BDBMAPVOTE") {
    if(Mid(Caps(MutateString),11,8) == "VOTEMENU") {

         if(Level.TimeSeconds > 5) {
           xClient.openMapvote();
         }
         else xClient.client.showMsg("<C00>MapVote is not available at match start.");
      }

      if(Mid(Caps(MutateString),11,3) == "MAP") {
         MapName = mid(MutateString,15);
         SubmitVote(MapName,Sender);
      }
   }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the value of a shared variable has been updated.
 *  $PARAM        container  Shared data container that contains the updated variable.
 *  $PARAM        varName    Name of the variable that was updated.
 *  $PARAM        index      Element index of the array variable that was changed.
 *  $REQUIRE      container != none && varName != "" && index >= 0
 *  $PARAM        author           Object that was responsible for the change.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function varChanged(NexgenSharedDataContainer container, string varName, optional int index, optional Object author) {
  local NexgenClient client;
  local bool bIsSensitive;
  local string varIndex;

  // Log admin actions.
  if (author != none && (author.isA('NexgenClient') || author.isA('NexgenClientController'))) {
    // Get client.
    if (author.isA('NexgenClientController')) {
      client = NexgenClientController(author).client;
    } else {
      client = NexgenClient(author);
    }

    // Only log changes for configuration variables.
    if (container.containerID ~= class'UrSMapVoteConfigDC'.default.containerID || 
        container.containerID ~= class'UrSMapSettingsConfigDC'.default.containerID) {

      // Check for arrays.
      if (container.isArray(varName)) {
        varIndex = "[" $ index $ "]";
      }

      // Log action.
      control.logAdminAction(client, "<C07>%1 has set %2.%3 to \"%4\".", client.playerName,
                             string(UrSMapVoteConfig(xConf).class), varName $ varIndex,
                             container.getString(varName, index),
                             client.player.playerReplicationInfo, true);
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the game has ended.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function gameEnded() {
  local NexgenClient client;
  local UrSMapVoteClient xClient;

  DeathMatchPlus(Level.Game).bDontRestart = true;
  TimeLeft = UrSMapVoteConfig(xConf).votelimit;
  delayTime = UrSMapVoteConfig(xConf).opendelay;

  bGameEnded = true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the mapVote delay has been reached.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function OpenVoteWindow() {
  local NexgenClient client;
  local UrSMapVoteClient xClient;

  if (bLevelSwitchPending) return;

  // Open window.
  for (client = control.clientList; client != none; client = client.nextClient) {
    if (!client.bSpectator) {
      xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
      if(xClient != none) {
        if(xClient.client.player.bIsTyping) xClient.setTimer(1.0, true);
        else xClient.openMapvote();
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Plugin timer driven by the Nexgen controller. Ticks at a frequency of 1 Hz and is
 *                independent of the game speed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function virtualTimer() {
  local Pawn P;
  local pawn aPawn;
  local int i, VoterNum,NoVoteCount,mapnum;
  local NexgenClient client;
  local UrSMapVoteClient xClient;
  local int x;
  local NexgenSharedDataContainer container;
  
  // Called only one time
  // Sets up the array and loads the maplist
  if(!bReadMaps) {
    bReadMaps = true;
    for(x=0;x<32;x++) PlayerIDList[x] = -1;

    // Locate NexgenPlus
    for(i=0;i<ArrayCount(control.plugins);i++) {
      if(InStr(control.plugins[i].class, "NXPMain") != -1) {
        container = NexgenExtendedPlugin(control.plugins[i]).dataSyncMgr.getDataContainer("maplist");
        break;
      }
    }
    
    if(container == none) {
      log("MAPLIST DATACONTAINER NOT FOUND ! ! ! ");
      return;
    }
       
    MapCount = container.getInt("numMaps");

    // Load maps from container
    for(x=0;x<ArrayCount(maplist)-1;x++) {
      maplist[x+1] = container.getString("maps", x);
    }
  }

  // Do ServerTravel.
  if(bLevelSwitchPending) {
    for (client = control.clientList; client != none; client = client.nextClient) {
        xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
        xClient.TimeLeft  = 0;
    }
    if( Level.NextURL == "" ) {
      if(Level.NextSwitchCountdown < 0) {

        // Get a random mapfile
        // MapCount = maps.numMaps;
        mapnum = Rand(MapCount) + 1;

        while(Left(maplist[mapnum],3) == "[X]") {
          mapnum = Rand(MapCount) + 1;
        }

        ServerTravelString = SetupGameMap(maplist[mapnum]);
        Level.ServerTravel(ServerTravelString, false);
      } else Level.ServerTravel(ServerTravelString, false);
    }
    return;
  }

  // Check players
  CleanUpPlayerIDs();

  // Update votes
  TallyVotes(false);

  // Game has ended. Do Stuff:
  if (bGameEnded) {

    // Open VoteWindow.
    if (delayTime > 0) {
      delayTime--;

      if (delayTime == 0) {
        OpenVoteWindow();
        control.broadcastMsg("<C04>Vote for the next map!");
      }
    }

    // Start/Update Voting Countdown.
    if (delayTime < 1 && TimeLeft > 0) {
      if (TimeLeft == UrSMapVoteConfig(xConf).votelimit) control.broadcastMsg("<C04>"$TimeLeft$" seconds left to vote.");
      TimeLeft--;

      for (client = control.clientList; client != none; client = client.nextClient) {
        xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
        xClient.delayTime = delayTime;
        xClient.TimeLeft  = TimeLeft;
        xclient.bGameEnded = bGameEnded;
      }

      if(TimeLeft == 10) control.broadcastMsg("<C04>10 seconds left to vote.");

      // Countdown Voice Announcer.
      if(TimeLeft < 11 && TimeLeft > 0 ) {
        for( P = Level.PawnList; P!=None; P=P.nextPawn ) {
          if(P.IsA('TournamentPlayer')) TournamentPlayer(P).TimeMessage(TimeLeft);
        }
      }
    }

    if(TimeLeft == 10 && TimeLeft > 0) {
        NoVoteCount = 0;
        for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn ) {
           if(aPawn.bIsPlayer && PlayerPawn(aPawn) != none) {
             VoterNum = FindPlayerIndex(PlayerPawn(aPawn).PlayerReplicationInfo.PlayerID);
             if(VoterNum > -1)  {
               if(PlayerVote[VoterNum] == 0) NoVoteCount++;
             }
           }
        }
        if(NoVoteCount == 0)
        TallyVotes(true);
    }
    if(TimeLeft == 0) TallyVotes(true);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the PlayerIDList index for a given PlayerID.
 *  $Param  PlayerID  PlayerID of the player to search.
 *  $Return The PlayerIDList index for the searched player.
 *
 **************************************************************************************************/
function int FindPlayerIndex(int PlayerID) {
   local int x;

   for(x=0;x<32;x++) {
    if(PlayerIDList[x] == PlayerID) return x;
   }

   for(x=0;x<32;x++) {
    if(PlayerIDList[x]==-1) {
      PlayerIDList[x]=PlayerID;
      return x;
    }
   }

   return -1;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Cleans up the PlayerID list.
 *
 **************************************************************************************************/
function CleanUpPlayerIDs() {
   local Pawn aPawn;
   local int x;
   local bool bFound;

   for(x=0;x<32;x++) {

      if(PlayerIDList[x]>-1) {
         bFound = false;
         for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn ) {
          if(aPawn.bIsPlayer && aPawn.IsA('PlayerPawn') && PlayerPawn(aPawn).PlayerReplicationInfo.PlayerID == PlayerIDList[x]) {
            bFound = true;
            break;
          }
         }
         if(!bFound) {
          PlayerVote[x] = 0;
          PlayerIDList[x] = -1;
         }
      }
   }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Main Vote Function. Handles all given votes.
 *  $Param  bForceMapSwitch  Whether the MapSwitch has been forced.
 *
 **************************************************************************************************/
function TallyVotes(bool bForceMapSwitch) {
   local string MapName;
   local Actor  A;
   local int    index,x,y,topmap;
   local int    VoteCount[1024];
   local int    Ranking[32];
   local int    PlayersThatVoted;
   local int    TieCount;
   local string GameType,CurrentMap;
   local int i,textline;
   local string winmap;

  // Check whether we are done
  if(bLevelSwitchPending) return;

   PlayersThatVoted = 0;
   for(x=0;x<32;x++) {
    if(PlayerVote[x] != 0) {
    
      PlayersThatVoted++;
      VoteCount[PlayerVote[x]]++;
        if(float(VoteCount[PlayerVote[x]]) / float(Level.Game.NumPlayers) > 0.5 && Level.Game.bGameEnded) {
          bForceMapSwitch = true;
        }
      }
   }

   if(!Level.Game.bGameEnded && !bMidGameVote && (float(PlayersThatVoted) / float(Level.Game.NumPlayers)) * 100 >= UrSMapVoteConfig(xConf).MidGameVotePercent) {
      if(Level.Game.NumPlayers>2) control.broadcastMsg("<C04>Mid-game mapvoting:"@UrSMapVoteConfig(xConf).MidGameVotePercent$"% of the players want to change the map!");
      bMidGameVote = true;
      TimeLeft = UrSMapVoteConfig(xConf).votelimit;
      delayTime = 1;
      bGameEnded = true;
   }

   // Get rankings
   index = 0;
   for(x=1;x<=MapCount;x++) {
    if(VoteCount[x] > 0) {
      Ranking[index++] = x;
    }
   }

   for(x=0; x<index-1; x++) {
    for(y=x+1; y<index; y++) {
      if(VoteCount[Ranking[x]] < VoteCount[Ranking[y]]) {
        topmap = Ranking[x];
        Ranking[x] = Ranking[y];
        Ranking[y] = topmap;
      }
    }
   }

   // Update entries
   for(x=0;x<index;x++) {
    MAPVOTECOUNTS[x] = VoteCount[Ranking[x]];
    MAPVOTENAME[x] = maplist[Ranking[x]];
   }
   
   MAPVOTENAME[index] = "";
   MAPVOTECOUNTS[index] = 0;

   // Update client windows
   updateVotelist();

   if(VoteCount[Ranking[0]] == VoteCount[Ranking[1]] && VoteCount[Ranking[0]] != 0) {
    TieCount = 1;
    for(x=1; x<index; x++) {
      if(VoteCount[Ranking[0]] == VoteCount[Ranking[x]])
         TieCount++;
      }
      topmap = Ranking[Rand(TieCount)];

      CurrentMap = GetURLMap();
      if(CurrentMap != "" && !(Right(CurrentMap,4) ~= ".unr")) CurrentMap = CurrentMap$".unr";

      x = 0;
      while(maplist[topmap] ~= CurrentMap) {
        topmap = Ranking[Rand(TieCount)];
        x++;
        if(x>20) break;
      }
   }
   else topmap = Ranking[0];

   if(bForceMapSwitch) {
     if(PlayersThatVoted == 0) {
       topmap = Rand(MapCount) + 1;
       while(Left(maplist[topmap],3) == "[X]") topmap = Rand(MapCount) + 1;
       control.broadcastMsg("<C04>Noone voted. Choosing random map file ..");
     }
   }

   if(bForceMapSwitch || Level.Game.NumPlayers == PlayersThatVoted && PlayersThatVoted > 0 ) {
      if(maplist[topmap] == "") return;

      winmap = maplist[topmap];
      i = InStr(Caps(winmap), ".UNR");
      if(i != -1) winmap = Left(winmap, i);
      control.broadcastMsg("<C04>"$winmap $ " has won.");

      CloseVoteWindows();
      bLevelSwitchPending = true;
      ServerTravelString = SetupGameMap(maplist[topmap]);
      ServerTravelTime = Level.TimeSeconds;

      updateRepeatList(maplist[topmap]);

   }

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates the RepeatList. Only called at game-end after a succesfull voting phase
 *  $Param  MapName The Voted map.
 *
 **************************************************************************************************/
function updateRepeatList(string mapname) {
  local int x;
  local string nextmap;

  if (mapname == "") return;

  for(x=0; x < UrSMapVoteConfig(xConf).RepeatLimit; x++) {
    if (UrSMapVoteConfig(xConf).votedMaps[x] == mapname) return;
  }

  for(x=0; x < UrSMapVoteConfig(xConf).RepeatLimit+1; x++) {
    if (x == UrSMapVoteConfig(xConf).RepeatLimit) {
      UrSMapVoteConfig(xConf).votedMaps[0] = mapname;
      UrSMapVoteConfig(xConf).saveconfig();
      return;
    }
    nextmap = UrSMapVoteConfig(xConf).votedMaps[UrSMapVoteConfig(xConf).RepeatLimit - (x+1)];
    UrSMapVoteConfig(xConf).votedMaps[UrSMapVoteConfig(xConf).RepeatLimit - x] = nextmap;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Closes all open VoteWindows on the clients.
 *
 **************************************************************************************************/
function CloseVoteWindows() {
  local NexgenClient client;
  local UrSMapVoteClient xClient;

  for (client = control.clientList; client != none; client = client.nextClient) {

    xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
    if (xClient != None) {
      xClient.closeVotewindow();
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Handles a given vote.
 *  $Param  MapName The voted map.
 *  $Param  Voter   The Voter.
 *
 **************************************************************************************************/
function SubmitVote(string MapName, Actor Voter) {
  local NexgenClient client;
  local int PlayerIndex,x,MapIndex,i;
  
  client = control.getClient(Voter);
  
  if(client == none) return;

  // Check voter
  if(client.bSpectator) {
    client.showMsg("<C00>Spectators are not allowed to vote.");
    return;
  }
  
  // Check if vote has already ended
  if(bLevelSwitchPending || Left(MapName,3) == "[X]") return;

  // Check if map has been marked out
  for(x=0; x < UrSMapVoteConfig(xConf).RepeatLimit; x++) {
    if(UrSMapVoteConfig(xConf).votedMaps[x] == MapName) {
      client.showMsg("<C00>You can not vote for this map.");
      return;
    }
  }

  // Check if the voter is a valid player.
  PlayerIndex = FindPlayerIndex(client.player.PlayerReplicationInfo.PlayerID);
  if(PlayerIndex == -1) return;

  // Check if voted map is in the maplist
  for(x=1; x<=MapCount; x++) {
    if(maplist[x] == MapName) {
      MapIndex = x;
      break;
    }
  }

  // Invalid map, vote doesn't count!
  if(MapIndex == 0) return;

  // Check if player has already voted for this map
  if(PlayerVote[PlayerIndex] == MapIndex) return;

  // Register vote
  PlayerVote[PlayerIndex] = MapIndex;

  // Inform about vote.
  i = InStr(Caps(MapName), ".UNR");
  if(i != -1) MapName = Left(MapName, i);
  control.broadcastMsg(client.playerName $ " voted for " $ MapName $".");

  // Call main handler.
  TallyVotes(false);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION Sets up the ServerTravel string.
 *  $Param  MapName  The voted map.
 *  $Return The ServerTravel string.
 *
 **************************************************************************************************/
function string SetupGameMap(string MapName)
{
  return MapName$"?game="$UrSMapVoteConfig(xConf).GameType;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION Updates the vote results on the client's window
 *
 **************************************************************************************************/
function updatevotelist() {
  local NexgenClient client;
  local UrSMapVoteClient xClient;
  local int x;

  // get client list.
  for (client = control.clientList; client != none; client = client.nextClient) {

    xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));

    if (xClient != None) {

      // First clear all existing entries
      xClient.clearList();

      // Update entries
      x=0;
      while(MAPVOTENAME[x] != "" && MAPVOTECOUNTS[x] > 0 && x<99) {
        xClient.updateVoteBox(MAPVOTECOUNTS[x], MAPVOTENAME[x], x);
        x++;
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the time limit for the current map.
 *  $PARAM        amount  The new time limit.
 *
 **************************************************************************************************/
function setTimeLimit(int amount) {
	local DeathMatchPlus game;
	local int previousTimeLimit;

	// Preliminary checks.
	if (!level.game.isA('DeathMatchPlus')) {
		return;
	}

	// Get DeathMatchPlus game.
	game = DeathMatchPlus(level.game);

	// Change time limit.
	previousTimeLimit = game.timeLimit;

	game.timeLimit = amount;
	TournamentGameReplicationInfo(game.gameReplicationInfo).timeLimit = amount;
	game.saveConfig();

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the team score limit for the current map.
 *  $PARAM        amount  The new team score limit.
 *
 **************************************************************************************************/
function setTeamScoreLimit(int amount) {
	local TeamGamePlus game;

	// Preliminary checks.
	if (!level.game.isA('TeamGamePlus') || amount < 1) {
		return;
	}

	// Get TeamGamePlus game.
	game = TeamGamePlus(level.game);

	// Change frag limit.
	game.goalTeamScore = amount;
	TournamentGameReplicationInfo(game.gameReplicationInfo).goalTeamScore = amount;
	game.saveConfig();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the game speed for the current map.
 *  $PARAM        gameSpeed  The new game speed limit.
 *
 **************************************************************************************************/
function setGameSpeed(int gameSpeed) {

	// Preliminary checks.
	if (gameSpeed < 50) {
		return;
	}

	// Change the game speed.
	level.game.setGameSpeed(gameSpeed / 100.0);
	level.game.saveConfig();
	level.game.gameReplicationInfo.saveConfig();
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed serverside set() function of NexgenSharedDataSyncManager. Uses correct
 *                formatting.
 *
 **************************************************************************************************/
function setFixed(string dataContainerID, string varName, coerce string value, optional int index, optional Object author) {
  local NexgenSharedDataContainer dataContainer;
  local NexgenClient client;
  local NexgenExtendedClientController xClient;
  local string oldValue;
  local string newValue;

  // Get the data container.
  dataContainer = dataSyncMgr.getDataContainer(dataContainerID);
  if (dataContainer == none) return;

  oldValue = dataContainer.getString(varName, index);
  dataContainer.set(varName, value, index);
  newValue = dataContainer.getString(varName, index);

  // Notify clients if variable has changed.
  if (newValue != oldValue) {
    for (client = control.clientList; client != none; client = client.nextClient) {
      xClient = getXClient(client);
      if (xClient != none && xClient.bInitialSyncComplete && dataContainer.mayRead(xClient, varName)) {
        if (dataContainer.isArray(varName)) {
          xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
                          @ static.formatCmdArgFixed(dataContainerID)
                          @ static.formatCmdArgFixed(varName)
                          @ index
                          @ static.formatCmdArgFixed(newValue));
        } else {
          xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
                          @ static.formatCmdArgFixed(dataContainerID)
                          @ static.formatCmdArgFixed(varName)
                          @ static.formatCmdArgFixed(newValue));
        }
      }
    }
  }

  // Also notify the server side controller of this event.
  if (newValue != oldValue) {
    varChanged(dataContainer, varName, index, author);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the static formatCmdArg function in NexgenUtil. Empty strings
 *                are formated correctly now (original source of all trouble).
 *
 **************************************************************************************************/
static function string formatCmdArgFixed(coerce string arg) {
  local string result;

  result = arg;

  // Escape argument if necessary.
  if (result == "") {
    result = "\"\"";                      // Fix (originally, arg was assigned instead of result -_-)
  } else {
    result = class'NexgenUtil'.static.replace(result, "\\", "\\\\");
    result = class'NexgenUtil'.static.replace(result, "\"", "\\\"");
    result = class'NexgenUtil'.static.replace(result, chr(0x09), "\\t");
    result = class'NexgenUtil'.static.replace(result, chr(0x0A), "\\n");
    result = class'NexgenUtil'.static.replace(result, chr(0x0D), "\\r");

    if (instr(arg, " ") > 0) {
      result = "\"" $ result $ "\"";
    }
  }

  // Return result.
  return result;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     versionNum=100
     extConfigClass=Class'UrSMapVoteConfigExt'
     sysConfigClass=Class'UrSMapVoteConfigSys'
     clientControllerClass=Class'UrSMapVoteClient'
     pluginName="UrSMapVote"
     pluginAuthor="Sp0ngeb0b"
     pluginVersion="2b"
}
