class UrSMapSettingsConfigTab extends NexgenPanel;

var UrSMapVoteClient xClient;

var NexgenSimpleListBox mapList;
var UWindowComboControl gameTypeList;
var UWindowCheckbox hideBadMapsInp;
var UWindowEditControl TeamScoreInp;
var UWindowEditControl TimeLimitInp;
var UWindowEditControl GameSpeedInp;

var UWindowEditControl DTeamScoreInp;
var UWindowEditControl DTimeLimitInp;
var UWindowEditControl DGameSpeedInp;

var NexgenSharedDataContainer xConf;
var NexgenSharedDataContainer mapListData;

var UWindowSmallButton saveButton;
var UWindowSmallButton Defaults;
var UWindowSmallButton DefaultsTWO;

const SSTR_HideBadMaps = "HideBadMaps";
const seperator = ",";

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  local int region;

  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
  
  // Create layout & add components.
  createWindowRootRegion();
  splitRegionV(192, defaultComponentDist);
  splitRegionH(20, defaultComponentDist, , true);
  splitRegionH(20, defaultComponentDist, , true);
  mapList = NexgenSimpleListBox(addListBox(class'NexgenSimpleListBox'));
  hideBadMapsInp = addCheckBox(TA_Left, "Hide bad maps", true);
  p = addContentPanel();
  splitRegionV(192, defaultComponentDist, , true);
  gameTypeList = addListCombo();
  saveButton = addButton(client.lng.saveTxt, 96, AL_Right);

  p.splitRegionH(84);
  region = p.currRegion;
  p.skipRegion();
  p.splitRegionH(16);
  p.skipRegion();
  p.splitRegionH(20);
  p.addLabel("Default settings", true, TA_Center);
  p.splitRegionH(1);
  p.addComponent(class'NexgenDummyComponent');
  p.divideRegionH(4);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.addLabel("Default TeamScore Limit", true, TA_Left);
  DTeamScoreInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();
  p.addLabel("Default Time Limit", true, TA_Left);
  DTimeLimitInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();
  p.addLabel("Default Game Speed", true, TA_Left);
  DGameSpeedInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();
  Defaults = p.addButton("Set Defaults to CURRENT map", 140, AL_Left);
  p.skipRegion();
  p.skipRegion();

  p.selectRegion(region);
  p.selectRegion(p.splitRegionH(20, defaultComponentDist));
  p.addLabel("Map Settings", true, TA_Center);
  p.splitRegionH(1);
  p.addComponent(class'NexgenDummyComponent');

  p.divideRegionH(3);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(192, 2 * defaultComponentDist);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.splitRegionV(140);
  p.addLabel("TeamScore Limit", true, TA_Left);
  TeamScoreInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();
  p.addLabel("Time Limit", true, TA_Left);
  TimeLimitInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();
  p.addLabel("Game Speed", true, TA_Left);
  GameSpeedInp = p.addEditBox();
  p.skipRegion();
  p.skipRegion();



  // Configure components.

  loadMapList();
  TeamScoreInp.setNumericOnly(true);
  TimeLimitInp.setNumericOnly(true);
  GameSpeedInp.setNumericOnly(true);
  DTeamScoreInp.setNumericOnly(true);
  DTimeLimitInp.setNumericOnly(true);
  DGameSpeedInp.setNumericOnly(true);
  gameTypeList.register(self);
  loadGameTypeList();
  hideBadMapsInp.register(self);
  hideBadMapsInp.bChecked = client.gc.get(SSTR_HideBadMaps, "true") ~= "true";
  setValues();
}

function string getMapName(int index) {
  local string data;
  
  if(xConf == none) return "";

  data = xConf.getString("mapSettings", index);

  if(data == "") return "";

  return Left(Data, InStr(Data, seperator));
}

function int getTeamScore(int index) {
  local string data;

  data = xConf.getString("mapSettings", index);

  // Remove Mapname
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(Left(Data, InStr(data, seperator)));
}

function int getTimeLimit(int index) {
  local string data;

  data = xConf.getString("mapSettings", index);

  // Remove Mapname and TeamScore
  data = mid(data, InStr(data, seperator)+Len(seperator));
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(Left(Data, InStr(data, seperator)));
}

function int getGameSpeed(int index) {
  local string data;

  data = xConf.getString("mapSettings", index);

  // Remove Mapname, TeamScore and TimeLimit
  data = mid(data, InStr(data, seperator)+Len(seperator));
  data = mid(data, InStr(data, seperator)+Len(seperator));

  return int(mid(Data, InStr(data, seperator)+Len(seperator)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of all input components to the current settings.
 *
 **************************************************************************************************/
function setValues() {
  local string mapname;
  local bool bfound;
  local int index, mapEntry;

  if(xConf == none) return;
  
  if (mapList.selectedItem == none) mapname = "";
  else mapname = NexgenSimpleListItem(mapList.selectedItem).displayText;

  // if a map is selected
  if (mapname != "") {
  
    mapEntry = getEntry(mapname);

    if(xConf.getString("mapSettings", mapEntry) != "") {
      TeamScoreInp.setValue(string(getTeamScore(mapEntry)));
      TimeLimitInp.setValue(string(getTimeLimit(mapEntry)));
      GameSpeedInp.setValue(string(getGameSpeed(mapEntry)));
    } else {
      TeamScoreInp.setValue("");
      TimeLimitInp.setValue("");
      GameSpeedInp.setValue("");
    }

  }

  DTeamScoreInp.setValue(xConf.getString("defaultScore"));
  DTimeLimitInp.setValue(xConf.getString("defaultTime"));
  DGameSpeedInp.setValue(xConf.getString("defaultSpeed"));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current settings.
 *
 **************************************************************************************************/
function saveSettings() {
  local string mapname, data;
  local int index, TeamScore, TimeLimit, GameSpeed, mapEntry;

  if(DTeamScoreInp.getValue() != "") xClient.setVar("UrSMapSettings_config", "defaultScore", DTeamScoreInp.getValue());
  if(DTimeLimitInp.getValue() != "") xClient.setVar("UrSMapSettings_config", "defaultTime", DTimeLimitInp.getValue());
  if(DGameSpeedInp.getValue() != "") xClient.setVar("UrSMapSettings_config", "defaultSpeed", DGameSpeedInp.getValue());
  
  // get map
  if (mapList.selectedItem == none) mapname = "";
  else mapname = NexgenSimpleListItem(mapList.selectedItem).displayText;
  
  if(mapname != "") {

    mapEntry = getEntry(mapname);
    
    if(TeamScoreInp.getValue() != "") TeamScore = int(TeamScoreInp.getValue());
    else TeamScore = int(xConf.getString("defaultScore"));
    
    if(TimeLimitInp.getValue() != "") TimeLimit = int(TimeLimitInp.getValue());
    else TimeLimit = int(xConf.getString("defaultTime"));
    
    if(GameSpeedInp.getValue() != "") GameSpeed = int(GameSpeedInp.getValue());
    else GameSpeed = int(xConf.getString("defaultSpeed"));
    
    // Create string
    data = mapname$seperator$TeamScore$seperator$TimeLimit$seperator$GameSpeed;
    
    xClient.setVar("UrSMapSettings_config", "mapSettings", data, mapEntry);
  }
  
  xClient.saveSharedData("UrSMapSettings_config");
}

function int getEntry(string Mapname) {
  local int i;
  
  if(xConf == none) return -1;

  for(i=0;i<xConf.getArraySize("mapSettings");i++) {
  
    if(getMapname(i) == "") break;
    
    if(getMapname(i) == Mapname) return i;
  }
  
  // No entry found, return next free entry
  return i;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the value of a shared variable has been updated.
 *  $PARAM        container  Shared data container that contains the updated variable.
 *  $PARAM        varName    Name of the variable that was updated.
 *  $PARAM        index      Element index of the array variable that was changed.
 *  $REQUIRE      container != none && varName != "" && index >= 0
 *  $OVERRIDE
 *
 **************************************************************************************************/
function varChanged(NexgenSharedDataContainer container, string varName, optional int index) {
  local string mapname;
  
  if (container.containerID ~= class'UrSMapSettingsConfigDC'.default.containerID) {
    switch (varName) {
      case "defaultScore": DTeamScoreInp.setValue(container.getString(varName));          break;
      case "defaultTime": DTimeLimitInp.setValue(container.getString(varName));           break;
      case "defaultSpeed": DGameSpeedInp.setValue(container.getString(varName));          break;
      case "mapSettings":
        // get map
       if (mapList.selectedItem == none) mapname = "";
       else mapname = NexgenSimpleListItem(mapList.selectedItem).displayText;

       if(mapname != "" && getMapname(index) ==  mapname) {
         setValues();
       }
       break;
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the game type list.
 *
 **************************************************************************************************/
function loadGameTypeList() {
  local int index;
  local string gameClass;
  local string mapPrefix;
  local string gameName;

  // Load available game types.
  while (index < arrayCount(client.sConf.gameTypeInfo) && client.sConf.gameTypeInfo[index] != "") {
    class'NexgenUtil'.static.split(client.sConf.gameTypeInfo[index], gameClass, mapPrefix);
    class'NexgenUtil'.static.split(mapPrefix, mapPrefix, gameName);

    gameTypeList.addItem(gameName, string(index));

    index++;
  }

  // Select current game type.
  gameTypeList.setSelectedIndex(client.sConf.activeGameType);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the map list.
 *
 **************************************************************************************************/
function loadMapList() {
  local int index;
  local bool bHideBadMaps;
  local string gameClass;
  local string mapPrefix;
  local string remaining;
  local int numMaps;
  local string mapName;

  // Clear the map list.
  mapList.items.clear();
  mapList.selectedItem = none;
  mapSelected();

  // Check if the map list is available.
  if (mapListData == none) {
    addMap("Receiving maplist...");
    return;
  }

  // Get map prefix.
  index = gameTypeList.getSelectedIndex();
  if (index >= 0) {
    class'NexgenUtil'.static.split(client.sConf.gameTypeInfo[index], gameClass, remaining);
    class'NexgenUtil'.static.split(remaining, mapPrefix, remaining);
  } else {
    mapPrefix = "";
  }

  // Load the map list.
  bHideBadMaps = hideBadMapsInp.bChecked;
  numMaps = mapListData.getInt("numMaps");
  if (!bHideBadMaps || mapPrefix != "") {
    for (index = 0; index < numMaps; index++) {
      mapName = mapListData.getString("maps", index);

      // Add map?
      if (class'NexgenUtil'.static.isValidLevel(mapName) && (!bHideBadMaps || left(mapName, len(mapPrefix)) ~= mapPrefix)) {
        addMap(mapName);
      }
    }
  }
  mapList.sort();
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a map was selected from the map list.
 *
 **************************************************************************************************/
function mapSelected() {
  
  setValues();
  
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new map to the map list.
 *  $PARAM        mapName  Name of the map that is to be added.
 *  $REQUIRE      mapName != ""
 *
 **************************************************************************************************/
function string addMap(string mapName) {
  local NexgenSimpleListItem item;

  item = NexgenSimpleListItem(mapList.items.append(class'NexgenSimpleListItem'));
  item.displayText = mapName;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the initial synchronization of the given shared data container is
 *                done. After this has happend the client may query its variables and receive valid
 *                results (assuming the client is allowed to read those variables).
 *  $PARAM        container  The shared data container that has become available for use.
 *  $REQUIRE      container != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function dataContainerAvailable(NexgenSharedDataContainer container) {
  if (container.containerID == class'UrSMapSettingsConfigDC'.default.containerID) {
    xConf = container;
    if(mapListData != none) loadMapList();
    setValues();
  }
  else if (container.containerID == "maplist") {
    mapListData = container;
    if(xConf != none) loadMapList();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {
  local NexgenSimpleListItem newItem;

  super.notify(control, eventType);
  
  if(xConf == none) return;

  // Map selected?
  if (control == mapList && eventType == DE_Click) {
    mapSelected();
  }

  // Game type selected?
  if (control == gameTypeList && eventType == DE_Change) {
    if (hideBadMapsInp.bChecked) {
      loadMapList();
    }
  }

  // Hide bad maps checkbox changed?
  if (control == hideBadMapsInp && eventType == DE_Change) {
    // Save setting.
    client.gc.set(SSTR_HideBadMaps, string(hideBadMapsInp.bChecked));
    client.gc.saveConfig();

    // Reload map list.
    loadMapList();
  }

  // Button pressed?
  if (control != none && eventType == DE_Click && control.isA('UWindowSmallButton') &&
      !UWindowSmallButton(control).bDisabled) {

    switch (control) {
      case saveButton: saveSettings(); break;

      case Defaults: setDefault(); break;
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Set the Default Settings to the current Map
 *
 **************************************************************************************************/
function setDefault() {
  local string mapname;
  local int index;
  local bool bfound;

  // get map
  mapname = NexgenSimpleListItem(mapList.selectedItem).displayText;

  if (mapname == "") {
    client.showMsg("<C00>You have to select a map!");
    return;
  }

  // set TeamScore
  TeamScoreInp.setValue(xConf.getString("defaultScore"));

  // set TimeLimit
  TimeLimitInp.setValue(xConf.getString("defaultTime"));

  // set GameSpeed
  GameSpeedInp.setValue(xConf.getString("defaultSpeed"));

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     panelIdentifier="mapsettings"
}