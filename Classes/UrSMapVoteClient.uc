class UrSMapVoteClient extends NexgenExtendedClientController;

#exec TEXTURE IMPORT NAME=VoteIcon   FILE=Resources\VoteIcon.pcx   GROUP="GFX" FLAGS=3 MIPS=OFF
#exec TEXTURE IMPORT NAME=VoteIcon2  FILE=Resources\VoteIcon2.pcx  GROUP="GFX" FLAGS=3 MIPS=OFF

var UrSMapVoteTab mapvoteTab;

// Control variables
var int delayTime;
var int timeLeft;
var bool bGameEnded;

// Tips animation
var bool bCyclingThroughTips;
var byte currentTip;
var float tipStartTime;
var int tipLength;

// Screenshot
var Texture mapShot[1024];
var int lastLoadedIndex;
var bool bNewPanelStyle;
var bool bNewPanelStyleResize;
var bool bWindowSizeAdjusted;
var bool bScreensLoaded;

const SS_Vote = 'ssvote';               // Voting state

const tipAnimationTimeIn    = 2.0;
const tipAnimationTimeOut   = 0.5;
const tipAnimationTimePause = 1.0;

const loadsPerTick    = 1;
const newWindowHeight = 720;
const newWindowWidth  = 960;
const SSTR_bNewPanelStyle = "MapVoteWindowLoadScreens";
const SSTR_bResize        = "MapVoteWindowResize";

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {
  reliable if (role == ROLE_Authority) // Replicate to client...
    // Variables.
    delayTime, timeLeft, bGameEnded,

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

  // Determine panel style and add it
  bNewPanelStyle = client.gc.get(SSTR_bNewPanelStyle, string(int(client.player.Level.EngineVersion) >= 469)) ~= "true"; 
  bNewPanelStyleResize = bNewPanelStyle && client.gc.get(SSTR_bResize, string(client.mainWindow.root.GUIScale == 1.0)) ~= "true"; 
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
 *  $DESCRIPTION  Resizes the Nexgen Window (DAMN!)
 *
 **************************************************************************************************/
simulated function setWindowSize(float height, float width) {
  local UWindowWindow mainPanelBar;
  local float wLeft, wTop;
  
  if(client == none || client.mainWindow == none || client.mainWindow.mainPanel == none) return;

  client.mainWindow.WinHeight = height;
  client.mainWindow.WinWidth  = width;

  client.mainWindow.mainPanel.WinHeight = client.mainWindow.WinHeight-16;
  client.mainWindow.mainPanel.WinWidth  = client.mainWindow.WinWidth-4;
  mainPanelBar = client.mainWindow.Root.FindChildWindow(class'NexgenMainPanelBar', True);
  
  if(mainPanelBar == none) return;
  
  mainPanelBar.WinTop   = client.mainWindow.mainPanel.winHeight - client.mainWindow.mainPanel.barHeight - 3;
  mainPanelBar.WinWidth = client.mainWindow.mainPanel.winWidth;
  mainPanelBar.bAlwaysOnTop = true;
  mainPanelBar.BringToFront();
  client.mainWindow.mainPanel.pages.WinHeight = client.mainWindow.mainPanel.WinHeight - client.mainWindow.mainPanel.barHeight - 3;
  client.mainWindow.mainPanel.pages.WinWidth  = client.mainWindow.mainPanel.WinWidth;
  
  wLeft = fMax(0.0, (client.consoleWindow.root.winWidth  - width)  / 2.0);
  wTop  = fMax(0.0, (client.consoleWindow.root.winHeight - height) / 2.0);
  
  client.mainWindow.WinLeft = wLeft;
  client.mainWindow.WinTop  = wTop;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Getter function to the respective map shot
 *
 **************************************************************************************************/
simulated function Texture getMapShot(int index) {
  return mapShot[index];
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
  local string mapName;
  local int i;
  
  super.tick(delayTime);
  
  if(role == ROLE_SimulatedProxy) { 
    if(mapvoteTab != None) {
      if(mapvoteTab.bWindowVisible && client.mainWindow.bWindowVisible) {
        // Adjust size for new panel style
        if(bNewPanelStyle && bNewPanelStyleResize && !bWindowSizeAdjusted) {
          setWindowSize(newWindowHeight, newWindowWidth);
          bWindowSizeAdjusted = true;
        }
        
        if( mapvoteTab.xConf != None) {
          // Initial Screenshot Loading
          if(bNewPanelStyle && mapvoteTab.mapListData != None && !bScreensLoaded) {
            for(i=lastLoadedIndex; i<mapVoteTab.mapListData.getArraySize("maps") && i<lastLoadedIndex+loadsPerTick; i++) {
              mapName = mapVoteTab.mapListData.getString("maps", i);
              if(mapName == "") {
                bScreensLoaded = true;
                mapVoteTab.loadMapList();
              } else {
                mapShot[i] = Texture(DynamicLoadObject(mapName$".Screenshot", class'Texture'));
              }
            }
            lastLoadedIndex = i;
          }      
        
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
        }
      } else {
        if(bWindowSizeAdjusted) {
          setWindowSize(class'NexgenMainFrame'.default.windowHeight, class'NexgenMainFrame'.default.windowWidth);
          bWindowSizeAdjusted = false;
        }
        if(bCyclingThroughTips) nextTip();
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the tips data is available.
 *
 **************************************************************************************************/
simulated function tipsAvailable() {
  local int tipsAmount;
  
  // Set random first tip
  for(tipsAmount=0; tipsAmount<mapvoteTab.xConf.getArraySize("infoTips"); tipsAmount++) {
    if(mapvoteTab.xConf.getString("infoTips",tipsAmount) == "") break;
  }

  if(tipsAmount > 0) currentTip = Rand(tipsAmount); // Random int from [0, tipsAmount-1]
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
    if (timeLeft > 0) {
      text   = "Vote ("$timeLeft$")";
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

  if(!client.bInitialized) {
    client.showMsg("<C00>Command requires initialization.");
    return;
  }

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
simulated function updateVoteBox(int Votes, string mapName, int rank) {

  if (mapVoteTab == none) return;

  mapVoteTab.updateVoteBox(Votes, mapName, rank);
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
