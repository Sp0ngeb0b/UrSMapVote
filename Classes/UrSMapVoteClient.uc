class UrSMapVoteClient extends NexgenExtendedClientController;

#exec TEXTURE IMPORT NAME=VoteIcon   FILE=Resources\VoteIcon.pcx   GROUP="GFX" FLAGS=3 MIPS=OFF
#exec TEXTURE IMPORT NAME=VoteIcon2  FILE=Resources\VoteIcon2.pcx  GROUP="GFX" FLAGS=3 MIPS=OFF

var UrSMapVoteTab mapvoteTab;

var bool bNetWait;                      // Client is waiting for initial replication.

var int delayTime;
var int TimeLeft;
var bool bGameEnded;

// Tips animation
var bool bCyclingThroughTips;
var byte currentTip;
var float tipStartTime;
var int tipLength;

const SS_Vote = 'ssvote';               // Voting state

const tipAnimationTimeIn    = 2.0;
const tipAnimationTimeOut   = 0.5;
const tipAnimationTimePause = 1.0;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {
  reliable if (role == ROLE_Authority) // Replicate to client...
    // Variables.
    delayTime, TimeLeft, bGameEnded,

    // Functions.
    openMapvote, updateVoteBox, clearList,
    closeVotewindow;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the setup of the Nexgen remote control panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupControlPanel() {

  mapvoteTab = UrSMapVoteTab(client.mainWindow.mainPanel.addPanel("Map Vote", class'UrSMapVoteTab'));
  
  // Add config panel tab.
  if (client.hasRight(client.R_ServerAdmin)) {
    client.addPluginConfigPanel(class'UrSMapVoteSettings');
  }
  
  // Add mapsettings tab.
  if (client.hasRight("mapsettings")) {
    client.mainWindow.mainPanel.addPanel("Map Settings", class'UrSMapSettingsConfigTab', , "server,serversettings");
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the NexgenClient has received its initial replication info is has
 *                been initialized. At this point it's safe to use all functions of the client.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function clientInitialized() {
  super.clientInitialized();

  if(!client.bSpectator && bGameEnded) openMapvote();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Serverside tick.
 *  $OVERRIDE
 *
 **************************************************************************************************/
 simulated function tick(float deltaTime) {
  local float tipTime;
  local int charsToDisplay;
  local float tipAnimationTimeStay;

  super.tick(delayTime);
  
  if(role == ROLE_SimulatedProxy) { 
    if(mapvoteTab != None && mapvoteTab.xConf != None) {
      if(mapvoteTab.bWindowVisible && client.mainWindow.bWindowVisible) {
        // Tips animation.
        if(!bCyclingThroughTips) {
          // Start animation
          tipStartTime = Level.TimeSeconds;
          tipLength = Len(mapvoteTab.xConf.getString("infoTips" ,currentTip));
          bCyclingThroughTips = true;
        } else {
          tipTime = Level.TimeSeconds-tipStartTime; 
          tipAnimationTimeStay = mapvoteTab.xConf.getFloat("tipDuration");
          if(tipTime > tipAnimationTimeIn) {
            if(tipTime > tipAnimationTimeIn+tipAnimationTimeStay) {
              if(tipTime > tipAnimationTimeIn+tipAnimationTimeStay+tipAnimationTimeOut) {
                if(tipTime > tipAnimationTimeIn+tipAnimationTimeStay+tipAnimationTimeOut+tipAnimationTimePause) {
                  // Next entry.
                  nextTip();
                }
              } else {
                // Out animation.
                charsToDisplay = tipLength*(1-(tipTime-tipAnimationTimeIn-tipAnimationTimeStay)/tipAnimationTimeOut);
              }
            } else {
              // Display complete tip.
              charsToDisplay = tipLength;
            }
          } else {
            // In animation.
            charsToDisplay = tipLength*tipTime/tipAnimationTimeIn;
          }
          mapvoteTab.infoTipsLabel.setText(Left(mapvoteTab.xConf.getString("infoTips", currentTip), charsToDisplay));
        }      
      } else if(bCyclingThroughTips) {
        // Reset.
        nextTip();
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Show next tip.
 *
 **************************************************************************************************/
simulated function nextTip() {
  currentTip++;
  if(currentTip >= mapvoteTab.xConf.getArraySize("infoTips") || mapvoteTab.xConf.getString("infoTips",currentTip) == "") currentTip = 0;
  
  bCyclingThroughTips = false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer function.
 *
 **************************************************************************************************/
function timer() {

  if(!client.player.bIsTyping) {
    openMapvote();
    setTimer(0.0, false);
  }
  
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the server state panel on the Nexgen HUD.
 *  $PARAM        stateType  State type identifier.
 *  $PARAM        text       Text to display on the state panel.
 *  $PARAM        textColor  Color of the text to display.
 *  $PARAM        icon       State icon. The icon is displayed in front of the text.
 *  $PARAM        solidIcon  Solid version of the icon (masked, no transparency).
 *  $PARAM        bBlink     Whether the text on the panel should blink.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function modifyServerState(out name stateType, out string text, out Color textColor,
                                     out Texture icon, out Texture solidIcon, out byte bBlink) {

  if (bGameEnded && delaytime == 0) {
    icon      = Texture'VoteIcon';
    solidIcon = Texture'VoteIcon2';
    stateType = SS_Vote;
    if (TimeLeft > 0) {
      text   = "Vote ("$TimeLeft$")";
      textColor = client.nscHUD.colors[client.nscHUD.C_Yellow];
      bBlink = 1;
    }
    else {
      text   = "Vote ended";
      textColor = client.nscHUD.colors[client.nscHUD.C_Yellow];
      bBlink = 0;
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Opens MapVote on the client.
 *
 **************************************************************************************************/
simulated function openMapvote() {

  // Get mapvote tab.
  mapVoteTab = UrSMapVoteTab(client.mainWindow.mainPanel.getPanel(class'UrSMapVoteTab'.default.panelIdentifier));
  if (mapVoteTab == none) {
    return;
  }

  // Show the tab.
  client.showPanel(class'UrSMapVoteTab'.default.panelIdentifier);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Update the Vote window.
 *
 *
 **************************************************************************************************/
simulated function updateVoteBox(int Votes, string mapname, int rank) {

  if (mapVoteTab == none) return;

  mapVoteTab.updateVoteBox(Votes, mapname, rank);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Clear all existing entries in the VoteList.
 *
 **************************************************************************************************/
simulated function clearList() {

  if (mapVoteTab == none) return;
  mapVoteTab.clearResults();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Closes open VoteWindows.
 *
 **************************************************************************************************/
simulated function closeVotewindow() {

  setTimer(0.0, false);
  
  if (mapVoteTab != none && mapVoteTab.bWindowVisible && client.mainWindow.bWindowVisible) client.mainWindow.close();
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed version of the setVar function in NexgenExtendedClientController.
 *                Empty strings are now formated correctly before beeing sent to the server.
 *
 **************************************************************************************************/
simulated function setVar(string dataContainerID, string varName, coerce string value, optional int index) {
  local NexgenSharedDataContainer dataContainer;
  local string oldValue;
  local string newValue;

  // Get data container.
  dataContainer = dataSyncMgr.getDataContainer(dataContainerID);

  // Check if variable can be updated.
  if (dataContainer == none || !dataContainer.mayWrite(self, varName)) return;

  // Update variable value.
  oldValue = dataContainer.getString(varName, index);
  dataContainer.set(varName, value, index);
  newValue = dataContainer.getString(varName, index);

  // Send new value to server.
  if (newValue != oldValue) {
    if (dataContainer.isArray(varName)) {
      sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(dataContainerID)
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(varName)
              @ index
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(newValue));
    } else {
      sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(dataContainerID)
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(varName)
              @ class'UrSMapVoteMain'.static.formatCmdArgFixed(newValue));
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the exec_UPDATE_VAR function in NexgenExtendedClientController.
 *                Due to the invalid format function, empty strings weren't sent correctly and were
 *                therefore not identifiable for the other machine (server). This caused the var index
 *                being erroneously recognized as the new var value on the server.
 *                Since the serverside set() function in NexgenSharedDataSyncManager also uses the
 *                invalid format functions, I implemented a fixed function in UrSMapVoteMain. The
 *                client side set() function can still be called safely without problems.
 *
 **************************************************************************************************/
simulated function exec_UPDATE_VAR(string args[10], int argCount) {
  local int varIndex;
  local string varName;
  local string varValue;
  local NexgenSharedDataContainer container;
  local int index;

  // Get arguments.
  if (argCount == 3) {
    varName = args[1];
    varValue = args[2];
  } else if (argCount == 4) {
    varName = args[1];
    varIndex = int(args[2]);
    varValue = args[3];
  } else {
    return;
  }

  if (role == ROLE_Authority) {
    // Server side, call fixed set() function
    UrSMapVoteMain(xControl).setFixed(args[0], varName, varValue, varIndex, self);
  } else {

    // Client Side
    dataSyncMgr.set(args[0], varName, varValue, varIndex, self);

    container = dataSyncMgr.getDataContainer(args[0]);

    // Signal event to client controllers.
    for (index = 0; index < client.clientCtrlCount; index++) {
      if (NexgenExtendedClientController(client.clientCtrl[index]) != none) {
        NexgenExtendedClientController(client.clientCtrl[index]).varChanged(container, varName, varIndex);
      }
    }

    // Signal event to GUI.
    client.mainWindow.mainPanel.varChanged(container, varName, varIndex);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     ctrlID="UrSMapVoteClient"
     bCanModifyHUDStatePanel=True
}
