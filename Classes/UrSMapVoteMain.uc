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
var int timeLeft;
var int delayTime;
var int mapCount;
var bool bLevelSwitchPending;
var string serverTravelString;
var int delay;

var int mapvotecounts[100];
var string mapvotename[100];
var bool   bMidGameVote;
var int    playerIDList[32];
var int    playerVote[32];
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
  for (index = UrSMapVoteConfig(xConf).repeatLimit; index < arrayCount(UrSMapVoteConfig(xConf).votedMaps); index++) {
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
 *  $PARAM        mutateString  The mutate command.
 *  $PARAM        Sender  PlayerPawn who sent the command.
 *
 **************************************************************************************************/
function Mutate(string mutateString, PlayerPawn Sender) {
  local UrSMapVoteClient xClient;
  local string mapName;

  Super.Mutate(mutateString, Sender);

  xClient = UrSMapVoteClient(getXClient(sender));
  if (xClient == none) return;

  if(left(Caps(mutateString),10) == "BDBMAPVOTE") {
    if(Mid(Caps(mutateString),11,8) == "VOTEMENU") {
      if(Level.TimeSeconds > 5) {
        xClient.openMapvote();
      } else xClient.client.showMsg("<C00>MapVote is not available at match start.");
    }

    if(Mid(Caps(mutateString),11,3) == "MAP") {
      mapName = mid(mutateString,15);
      submitVote(mapName,Sender);
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
  timeLeft = UrSMapVoteConfig(xConf).voteLimit;
  delayTime = UrSMapVoteConfig(xConf).opendelay;

  bGameEnded = true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the mapVote delay has been reached.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function openVoteWindow() {
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
  local int i, voterNum,noVoteCount,mapnum;
  local NexgenClient client;
  local UrSMapVoteClient xClient;
  local int x;
  local NexgenSharedDataContainer container;

  // Called only one time
  // Sets up the array and loads the maplist
  if(!bReadMaps) {
    bReadMaps = true;
    for(x=0;x<32;x++) playerIDList[x] = -1;

    // Locate NexgenPlus
    for(i=0;i<ArrayCount(control.plugins);i++) {
      if(InStr(control.plugins[i].class, "NXPMain") != -1) {
        container = NexgenExtendedPlugin(control.plugins[i]).dataSyncMgr.getDataContainer("maplist");
        break;
      }
    }
    
    if(container == none) {
      control.nsclog("[NexgenMapVote] Maplist data container not found!");
      return;
    }
       
    mapCount = container.getInt("numMaps");

    // Load maps from container
    for(x=0;x<ArrayCount(maplist)-1;x++) {
      maplist[x+1] = container.getString("maps", x);
    }
  }

  // Do ServerTravel.
  if(bLevelSwitchPending) {
    for (client = control.clientList; client != none; client = client.nextClient) {
      xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
      xClient.timeLeft  = 0;
    }
    if( Level.NextURL == "" ) {
      if(Level.NextSwitchCountdown < 0) {
        // Get a random mapfile
        // mapCount = maps.numMaps;
        mapnum = Rand(mapCount) + 1;

        while(Left(maplist[mapnum],3) == "[X]") {
          mapnum = Rand(mapCount) + 1;
        }

        serverTravelString = setupGameMap(maplist[mapnum]);
        Level.ServerTravel(serverTravelString, false);
      } else Level.ServerTravel(serverTravelString, false);
    }
    return;
  }

  // Check players
  cleanUpPlayerIDs();

  // Update votes
  tallyVotes(false);

  // Game has ended. Do Stuff:
  if (bGameEnded) {
    // Open VoteWindow.
    if (delayTime > 0) {
      delayTime--;

      if (delayTime == 0) {
        openVoteWindow();
        control.broadcastMsg("<C04>Vote for the next map!");
      }
    }

    // Start/Update Voting Countdown.
    if (delayTime < 1 && timeLeft > 0) {
      if (timeLeft == UrSMapVoteConfig(xConf).voteLimit) control.broadcastMsg("<C04>"$timeLeft$" seconds left to vote.");
      timeLeft--;

      for (client = control.clientList; client != none; client = client.nextClient) {
        xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
        xClient.delayTime = delayTime;
        xClient.timeLeft  = timeLeft;
        xclient.bGameEnded = bGameEnded;
      }

      if(timeLeft == 10) control.broadcastMsg("<C04>10 seconds left to vote.");

      // Countdown Voice Announcer.
      if(timeLeft < 11 && timeLeft > 0 ) {
        for( P = Level.PawnList; P!=None; P=P.nextPawn ) {
          if(P.IsA('TournamentPlayer')) TournamentPlayer(P).TimeMessage(timeLeft);
        }
      }
    }

    if(timeLeft == 10 && timeLeft > 0) {
        noVoteCount = 0;
        for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn ) {
           if(aPawn.bIsPlayer && PlayerPawn(aPawn) != none) {
             voterNum = findPlayerIndex(PlayerPawn(aPawn).PlayerReplicationInfo.playerID);
             if(voterNum > -1)  {
               if(playerVote[voterNum] == 0) noVoteCount++;
             }
           }
        }
        if(noVoteCount == 0)
        tallyVotes(true);
    }
    if(timeLeft == 0) tallyVotes(true);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the playerIDList index for a given playerID.
 *  $Param  playerID  playerID of the player to search.
 *  $Return The playerIDList index for the searched player.
 *
 **************************************************************************************************/
function int findPlayerIndex(int playerID) {
  local int x;

  for(x=0;x<32;x++) {
    if(playerIDList[x] == playerID) return x;
  }

  for(x=0;x<32;x++) {
    if(playerIDList[x]==-1) {
      playerIDList[x]=playerID;
      return x;
    }
  }
  return -1;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Cleans up the playerID list.
 *
 **************************************************************************************************/
function cleanUpPlayerIDs() {
  local Pawn aPawn;
  local int x;
  local bool bFound;

  for(x=0;x<32;x++) {

    if(playerIDList[x]>-1) {
       bFound = false;
       for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn ) {
        if(aPawn.bIsPlayer && aPawn.IsA('PlayerPawn') && PlayerPawn(aPawn).PlayerReplicationInfo.playerID == playerIDList[x]) {
          bFound = true;
          break;
        }
       }
      if(!bFound) {
        playerVote[x] = 0;
        playerIDList[x] = -1;
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
function tallyVotes(bool bForceMapSwitch) {
  local string mapName;
  local Actor  A;
  local int    index,x,y,topmap;
  local int    voteCount[1024];
  local int    ranking[32];
  local int    playersThatVoted;
  local int    tieCount;
  local string gameType, currentMap;
  local int i,textline;
  local string winmap;

  // Check whether we are done
  if(bLevelSwitchPending) return;

  playersThatVoted = 0;
  for(x=0;x<32;x++) {
  if(playerVote[x] != 0) {

    playersThatVoted++;
    voteCount[playerVote[x]]++;
      if(float(voteCount[playerVote[x]]) / float(Level.Game.NumPlayers) > 0.5 && Level.Game.bGameEnded) {
        bForceMapSwitch = true;
      }
    }
  }

  if(!Level.Game.bGameEnded && !bMidGameVote && (float(playersThatVoted) / float(Level.Game.NumPlayers)) * 100 >= UrSMapVoteConfig(xConf).midGameVotePercent) {
    if(Level.Game.NumPlayers > 2) control.broadcastMsg("<C04>Mid-game mapvoting:"@UrSMapVoteConfig(xConf).midGameVotePercent$"% of the players want to change the map!");
    bMidGameVote = true;
    timeLeft = UrSMapVoteConfig(xConf).voteLimit;
    delayTime = 1;
    bGameEnded = true;
  }

  // Get rankings
  index = 0;
  for(x=1;x<=mapCount;x++) {
  if(voteCount[x] > 0) {
    ranking[index++] = x;
  }
  }

  for(x=0; x<index-1; x++) {
  for(y=x+1; y<index; y++) {
    if(voteCount[ranking[x]] < voteCount[ranking[y]]) {
      topmap = ranking[x];
      ranking[x] = ranking[y];
      ranking[y] = topmap;
    }
  }
  }

  // Update entries
  for(x=0;x<index;x++) {
  mapvotecounts[x] = voteCount[ranking[x]];
  mapvotename[x] = maplist[ranking[x]];
  }

  mapvotename[index] = "";
  mapvotecounts[index] = 0;

  // Update client windows
  updateVotelist();

  if(voteCount[ranking[0]] == voteCount[ranking[1]] && voteCount[ranking[0]] != 0) {
  tieCount = 1;
  for(x=1; x<index; x++) {
    if(voteCount[ranking[0]] == voteCount[ranking[x]])
       tieCount++;
    }
    topmap = ranking[Rand(tieCount)];

    currentMap = GetURLMap();
    if(currentMap != "" && !(Right(currentMap,4) ~= ".unr")) currentMap = currentMap$".unr";

    x = 0;
    while(maplist[topmap] ~= currentMap) {
      topmap = ranking[Rand(tieCount)];
      x++;
      if(x>20) break;
    }
  } else topmap = ranking[0];

  if(bForceMapSwitch) {
   if(playersThatVoted == 0) {
     topmap = Rand(mapCount) + 1;
     x = 0;
     while(Left(maplist[topmap],3) == "[X]") {
      topmap = Rand(mapCount) + 1;
      if(x++>50) break;
     }
     control.broadcastMsg("<C04>Noone voted. Choosing random map file ..");
   }
  }

  if(bForceMapSwitch || Level.Game.NumPlayers == playersThatVoted && playersThatVoted > 0 ) {
    if(maplist[topmap] == "") return;

    winmap = maplist[topmap];
    i = InStr(Caps(winmap), ".UNR");
    if(i != -1) winmap = Left(winmap, i);
    control.broadcastMsg("<C04>"$winmap $ " has won.");

    closeVoteWindows();
    bLevelSwitchPending = true;
    serverTravelString = setupGameMap(maplist[topmap]);

    updateRepeatList(maplist[topmap]);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Updates the RepeatList. Only called at game-end after a succesfull voting phase
 *  $Param  mapName The Voted map.
 *
 **************************************************************************************************/
function updateRepeatList(string mapName) {
  local int x;
  local string nextmap;

  if (mapName == "") return;

  for(x=0; x < UrSMapVoteConfig(xConf).repeatLimit; x++) {
    if (UrSMapVoteConfig(xConf).votedMaps[x] == mapName) return;
  }

  for(x=0; x < UrSMapVoteConfig(xConf).repeatLimit+1; x++) {
    if (x == UrSMapVoteConfig(xConf).repeatLimit) {
      UrSMapVoteConfig(xConf).votedMaps[0] = mapName;
      UrSMapVoteConfig(xConf).saveconfig();
      return;
    }
    nextmap = UrSMapVoteConfig(xConf).votedMaps[UrSMapVoteConfig(xConf).repeatLimit - (x+1)];
    UrSMapVoteConfig(xConf).votedMaps[UrSMapVoteConfig(xConf).repeatLimit - x] = nextmap;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Closes all open VoteWindows on the clients.
 *
 **************************************************************************************************/
function closeVoteWindows() {
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
 *  $Param  mapName The voted map.
 *  $Param  Voter   The Voter.
 *
 **************************************************************************************************/
function submitVote(string mapName, Actor Voter) {
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
  if(bLevelSwitchPending || Left(mapName,3) == "[X]") return;

  // Check if map has been marked out
  for(x=0; x < UrSMapVoteConfig(xConf).repeatLimit; x++) {
    if(UrSMapVoteConfig(xConf).votedMaps[x] == mapName) {
      client.showMsg("<C00>You can not vote for this map.");
      return;
    }
  }

  // Check if the voter is a valid player.
  PlayerIndex = findPlayerIndex(client.player.PlayerReplicationInfo.playerID);
  if(PlayerIndex == -1) return;

  // Check if voted map is in the maplist
  for(x=1; x<=mapCount; x++) {
    if(maplist[x] == mapName) {
      MapIndex = x;
      break;
    }
  }

  // Invalid map, vote doesn't count!
  if(MapIndex == 0) return;

  // Check if player has already voted for this map
  if(playerVote[PlayerIndex] == MapIndex) return;

  // Register vote
  playerVote[PlayerIndex] = MapIndex;

  // Inform about vote.
  i = InStr(Caps(mapName), ".UNR");
  if(i != -1) mapName = Left(mapName, i);
  control.broadcastMsg(client.playerName $ " voted for " $ mapName $".");

  // Call main handler.
  tallyVotes(false);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION Sets up the ServerTravel string.
 *  $Param  mapName  The voted map.
 *  $Return The ServerTravel string.
 *
 **************************************************************************************************/
function string setupGameMap(string mapName) {
  return mapName$"?game="$UrSMapVoteConfig(xConf).gameType;
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
      while(mapvotename[x] != "" && mapvotecounts[x] > 0 && x<99) {
        xClient.updateVoteBox(mapvotecounts[x], mapvotename[x], x);
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
     pluginVersion="3"
}
