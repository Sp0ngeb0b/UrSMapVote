class UrSMapVoteTab extends NexgenPanel;

#exec TEXTURE IMPORT NAME=NoShot   FILE=Resources\noshot.pcx   GROUP="GFX" FLAGS=0 MIPS=OFF

var UrSMapVoteClient xClient;
var NexgenSharedDataContainer xConf;

var NexgenSharedDataContainer mapListData;

var MapListBox mapList;
var VoteBox ResultBox;

var string PrevSelectedMap;

var UWindowSmallButton voteButton;

var UMenuLabelControl infoTipsLabel;
var UMenuLabelControl fileLabel;
var UMenuLabelControl titleLabel;
var UMenuLabelControl authorLabel;
var UMenuLabelControl playersLabel;
var NexgenImageControl LevelShot;
var Texture Screenshot;
var MapListBoxItem dummyItem;

var UMenuLabelControl hintLabel;
var Color tipColor;

var UWindowCheckBox bNewPanelStyleInp;
var UWindowCheckBox bEnlargeWindowInp;

const levelShotDimensionBase = 96;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  local NexgenContentPanel pp;
  local int region;
  
  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));
  
  if(xClient.bNewPanelStyleResize) {
    winHeight = xClient.newWindowHeight - (class'NexgenMainFrame'.default.windowHeight-winHeight);
    winWidth  = xClient.newWindowWidth;
  }

  // Create layout & add components.
  createWindowRootRegion();
  splitRegionH(32, defaultComponentDist, , true);    
  splitRegionV(192*(1+int(xClient.bNewPanelStyleResize)), defaultComponentDist);
  
  // Tip label
  p = addContentPanel();
  p.splitRegionV(28, defaultComponentDist);
  hintLabel = p.addLabel("Hint:", true, TA_Left);
  infoTipsLabel = p.addLabel();

  // Map list
  p = addContentPanel();
  p.splitRegionH(16, defaultComponentDist);
  p.addLabel("Maplist", true, TA_Center);
  mapList = MapListBox(p.addListBox(class'MapListBox'));

  splitRegionH(levelShotDimensionBase+20+levelShotDimensionBase*int(xClient.bNewPanelStyleResize), defaultComponentDist);

  // Level info.
  p = addContentPanel();
  p.splitRegionV(levelShotDimensionBase+12+levelShotDimensionBase*int(xClient.bNewPanelStyleResize), defaultComponentDist);
  pp = p.addContentPanel();
  LevelShot = pp.addImageBox(, true, levelShotDimensionBase*(1+int(xClient.bNewPanelStyleResize)), levelShotDimensionBase*(1+int(xClient.bNewPanelStyleResize)));

  p.splitRegionH(16);
  p.addLabel("Level Information", true, TA_Center);
  
  p.splitRegionH(8);
  p.skipRegion();
  
  p.splitRegionH(20, defaultComponentDist, , true);     
  p.splitRegionV(48);
  voteButton = p.addButton("Vote", 96, AL_Right);

  p.divideRegionH(4);
  p.divideRegionH(4);
  p.addLabel(client.lng.fileTxt, true);
  p.addLabel(client.lng.titleTxt, true);
  p.addLabel(client.lng.authorTxt, true);
  p.addLabel(client.lng.idealPlayerCountTxt, true);

  fileLabel = p.addLabel();
  titleLabel = p.addLabel();
  authorLabel = p.addLabel();
  playersLabel = p.addLabel();

  splitRegionH(16);
  p = addContentPanel();
  p.splitRegionV(24);
  p.skipRegion();
  p.splitRegionV(64, defaultComponentDist);
  p.addLabel("Rank", true, TA_Left);
  p.splitRegionV(64, defaultComponentDist);
  p.addLabel("Votes", true, TA_Left);
  p.addLabel("Map", true, TA_Left);

  // Client config
  splitRegionH(16, defaultComponentDist, , true);
  ResultBox = VoteBox(addListBox(class'VoteBox'));
  splitRegionV(192, defaultComponentDist);
  splitRegionV(32, defaultComponentDist, , true);
  splitRegionV(32, defaultComponentDist, , true);

  addLabel("Load Screenshots (v469 Style)", true, TA_Right);
  bNewPanelStyleInp = addCheckBox(TA_Left);
  
  addLabel("Enlarge Window", true, TA_Right);
  bEnlargeWindowInp = addCheckBox(TA_Left);

  // Configure components.
  bNewPanelStyleInp.register(self);
  bEnlargeWindowInp.register(self);
  bNewPanelStyleInp.bChecked  = xClient.bNewPanelStyle;
  bEnlargeWindowInp.bChecked  = xClient.bNewPanelStyleResize;
  bEnlargeWindowInp.bDisabled = !xClient.bNewPanelStyle;
  mapList.bShowScreenshot     = xClient.bNewPanelStyle;
  mapList.bResize             = xClient.bNewPanelStyleResize;
  ResultBox.bShowScreenshot   = xClient.bNewPanelStyle;
  ResultBox.bResize           = xClient.bNewPanelStyleResize;
  infoTipsLabel.setFont(F_Bold);
  mapSelected();
  dummyItem = MapListBoxItem(mapList.items.append(class'MapListBoxItem'));
  dummyItem.bDummy = true;
	dummyItem.mapName = "Receiving map list...";
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the map list.
 *
 **************************************************************************************************/
function loadMapList() {
  local int index;
  local string mapName;

  // Clear the map list.
  mapList.items.clear();
  mapList.selectedItem = none;
  mapSelected();

  // Load the map list.
  index = 0;
  while (index < mapListData.getInt("numMaps")) {
    mapName = mapListData.getString("maps", index);
    
    // Add map?
    if (class'NexgenUtil'.static.isValidLevel(mapName)) {
      addMap(mapName, index);
    }

    // Continue with next map.
    index++;
  }
  mapList.sort();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a map was selected from the map list.
 *
 **************************************************************************************************/
function mapSelected() {
  local int i;
  local LevelSummary L;
  local string mapname;
  
  VoteButton.bDisabled = mapList.selectedItem == none || xClient.client.bSpectator;
  if(mapList.selectedItem == none) {
    LevelShot.image = Texture'NoShot';
    return;
  }
    
  mapname = MapListBoxItem(mapList.selectedItem).mapName;
  
  if (resultbox.selectedItem != none) {
    resultbox.selectedItem.bSelected = false;
    resultbox.selectedItem = none;
  }
  
  i = InStr(Caps(MapName), ".UNR");
    if(i != -1) MapName = Left(MapName, i);

  loadMapInfo(mapname);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a map was selected from the resultbox list.
 *
 **************************************************************************************************/
function resultboxselected() {
  local int i;
  local string mapname;

  VoteButton.bDisabled = resultbox.selectedItem == none || xClient.client.bSpectator;
  if (ResultBox.selectedItem == none) {
    LevelShot.image = Texture'Botpack.miniammoledbase';
    return;
  }
  
  mapname = ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem));

  if (mapList.selectedItem != none) {

    // Deselect item in MapList
    mapList.selectedItem.bSelected = false;
    mapList.selectedItem = none;
  }
  
  i = InStr(Caps(MapName), ".UNR");
  if(i != -1) MapName = Left(MapName, i);
    
  loadMapInfo(mapname);
  
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the LevelSummary for the specified Map.
 *  $PARAM        mapName  Name of the map.
 *
 **************************************************************************************************/
function loadMapInfo(string mapname) {
  local LevelSummary L;
  
  Screenshot = Texture(DynamicLoadObject(MapName$".Screenshot", class'Texture'));
  if (Screenshot == none) {
    LevelShot.image = Texture'NoShot';
  } else {
    LevelShot.image = Screenshot;
  }

  fileLabel.setText(mapname);
            
  L = LevelSummary(DynamicLoadObject(MapName$".LevelSummary", class'LevelSummary'));
  if(L != None) {
    titleLabel.setText(L.Title);
    authorLabel.setText(L.Author);
    playersLabel.setText(L.IdealPlayerCount);
  } else {
    titleLabel.setText("Custom map");
    authorLabel.setText("-");
    playersLabel.setText("-");
  }  
}

function loadScreenshot(MapItem item, int index) {
  item.mapShot = xClient.getMapShot(index);
  if(item.mapShot == none) item.mapShot = Texture'NoShot';
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new map to the map list.
 *  $PARAM        mapName  Name of the map that is to be added.
 *  $REQUIRE      mapName != ""
 *
 **************************************************************************************************/
function string addMap(string mapName, int index) {
  local int i, x;
  local MapListBoxItem item;
  
  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));

  item = MapListBoxItem(mapList.items.append(class'MapListBoxItem'));

  if(xConf != none) {
    // Check whether map has been marked out
    for(x=0; x < xConf.getInt("RepeatLimit"); x++) {
      if (xConf.getString("votedMaps", x) == mapname) {
        item.bMarked = true;
        break;
      }
    }
  }
  
  i = InStr(Caps(MapName), ".UNR");
  if(i != -1) MapName = Left(MapName, i);
  item.mapName = mapName;
  loadScreenshot(item, index);
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

  if (container.containerID == class'UrSMapVoteConfigDC'.default.containerID) {
    xConf = container;
    if(mapListData != none) {
      if(xClient.bNewPanelStyle) dummyItem.mapName = "Loading screenshots ...";
      else loadMapList();
    }
    xClient.tipsAvailable();
    tipColor.R = xConf.getByte("tipColorR");
    tipColor.B = xConf.getByte("tipColorG");
    tipColor.G = xConf.getByte("tipColorB");
    infoTipsLabel.setTextColor(tipColor);
    hintLabel.setTextColor(tipColor);
  }
  else if (container.containerID == "maplist") {
    mapListData = container;
    if(xConf != none) {
      if(xClient.bNewPanelStyle) dummyItem.mapName = "Loading screenshots ...";
      else loadMapList();
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
 *  $OVERRIDE
 *
 **************************************************************************************************/
function varChanged(NexgenSharedDataContainer container, string varName, optional int index) {
  if (container.containerID ~= class'UrSMapVoteConfigDC'.default.containerID) {
    switch (varName) {
      case "tipColorR": 
      case "tipColorG": 
      case "tipColorB": 
        tipColor.R = xConf.getByte("tipColorR");
        tipColor.B = xConf.getByte("tipColorG");
        tipColor.G = xConf.getByte("tipColorB");
        infoTipsLabel.setTextColor(tipColor);
        hintLabel.setTextColor(tipColor);
      break;
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the VoteBox gets cleared.
 *
 **************************************************************************************************/
function clearResults() {

  if(ResultBox.SelectedItem != None) {
    PrevSelectedMap = VoteBoxItem(ResultBox.SelectedItem).MapName;
  }

  ResultBox.Items.Clear();
  ResultBox.selectedItem = none;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION   Called when VoteBox gets updated.
 *  $PARAM Votes   Number of votes for the specific map
 *  $PARAM MapName Name of the Map.
 *  $PARAM rank    Current vote-rankin place for the specific map
 *
 ***************************************************************************************************/
function updateVoteBox(int Votes, string mapname, int rank) {
  local MapItem mapItem;
  local VoteBoxItem item;
  local int i;
  
  // Create a new entry
  item = VoteBoxItem(ResultBox.items.append(class'VoteBoxItem'));
  item.VoteCount = Votes;
  item.rank      = rank + 1;
  
  i = InStr(Caps(MapName), ".UNR");
  if(i != -1) MapName = Left(MapName, i);
  
  mapItem = mapList.getMap(mapName);
  if(mapItem != None) item.mapShot = mapItem.mapShot;
	item.mapName = mapName;
  
  // See if we had selected this map
  if(PrevSelectedMap == MapName && mapList.selectedItem == none) {
    ResultBox.SelectMap(PrevSelectedMap);
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
  local MapListBoxItem newItem;
  local string mapname;

  super.notify(control, eventType);
  
  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));

  // Map selected?
  if (control == mapList && eventType == DE_Click) {
    mapSelected();
  }
  
  // ResultBox entry selected?
  if (control == ResultBox && eventType == DE_Click) {
    resultboxselected();
  }
  
  // MapList DoubleClicked?
  if(control == maplist && eventType == DE_DoubleClick) {
    if (mapList.selectedItem == none || MapListBoxItem(mapList.selectedItem).mapName == "") {
      return;
    }
    
    mapSelected();
    if(!xClient.client.bSpectator) xClient.client.player.consoleCommand("mutate BDBMAPVOTE MAP"@MapListBoxItem(mapList.selectedItem).mapName $".unr");
  }
  
  // ResultBox DoubleClicked?
  if(control == ResultBox && eventType == DE_DoubleClick) {
    if (ResultBox.selectedItem == none || ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem)) == "") {
      return;
    }

    resultboxselected();
    if(!xClient.client.bSpectator) xClient.client.player.consoleCommand("mutate BDBMAPVOTE MAP"@ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem))  $".unr");
  }
  
  // Button pressed?
  if (control != none && eventType == DE_Click && control.isA('UWindowSmallButton') &&
      !UWindowSmallButton(control).bDisabled) {

    switch (control) {
      case VoteButton:
      if (mapList.selectedItem == none && ResultBox.selectedItem == none  ||
          mapList.selectedItem != none && MapListBoxItem(mapList.selectedItem).mapName == "") {
        return;
      }
      if (mapList.selectedItem != none) mapname = MapListBoxItem(mapList.selectedItem).mapName;
      else mapname = ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem));
      
      xClient.client.player.consoleCommand("mutate BDBMAPVOTE MAP"@mapname $".unr");
      
    }
  }
  
  // New panel style checkbox?
  if(control == bNewPanelStyleInp && !bNewPanelStyleInp.bDisabled && eventType == DE_Click) {
    client.gc.set(xClient.SSTR_bNewPanelStyle, string(bNewPanelStyleInp.bChecked));
    client.gc.saveConfig();
    client.showMsg("<C07>Changes will take effect after a reconnect.");
    if(bNewPanelStyleInp.bChecked) {
      bEnlargeWindowInp.bDisabled = false;
      bEnlargeWindowInp.bChecked = client.gc.get(xClient.SSTR_bResize, string(client.mainWindow.root.GUIScale == 1.0)) ~= "true";
    } else {
      bEnlargeWindowInp.bDisabled = true;
      bEnlargeWindowInp.bChecked = false;
    }
  } else if(control == bEnlargeWindowInp && !bEnlargeWindowInp.bDisabled && eventType == DE_Click) {
    client.gc.set(xClient.SSTR_bResize, string(bEnlargeWindowInp.bChecked));
    client.gc.saveConfig();
    client.showMsg("<C07>Changes will take effect after a reconnect.");
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     panelIdentifier="UrSMapVote"
}
