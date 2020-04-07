class UrSMapVoteTab extends NexgenPanel;

#exec TEXTURE IMPORT NAME=NoShot   FILE=Resources\noshot.pcx   GROUP="GFX" FLAGS=0 MIPS=OFF

var UrSMapVoteClient xClient;
var NexgenSharedDataContainer xConf;

var NexgenSharedDataContainer mapListData;

var MapListBox mapList;
var VoteBox ResultBox;

var string PrevSelectedMap;
var bool bMapListAvailable;

var UWindowSmallButton voteButton;

var UMenuLabelControl infoTipsLabel;
var UMenuLabelControl fileLabel;
var UMenuLabelControl titleLabel;
var UMenuLabelControl authorLabel;
var UMenuLabelControl playersLabel;
var NexgenImageControl LevelShot;
var Texture Screenshot;

var UMenuLabelControl hintLabel;
var Color tipColor;

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

	// Create layout & add components.
	createWindowRootRegion();
  splitRegionH(32, defaultComponentDist, , true);    
	splitRegionV(192, defaultComponentDist);
  
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

  splitRegionH(144, defaultComponentDist, , false);

	// Level info.
	p = addContentPanel();
	p.splitRegionV(136, defaultComponentDist);
	pp = p.addContentPanel();
  LevelShot = pp.addImageBox(, true, 128, 128);

	p.splitRegionH(16);
	p.addLabel("Level Information", true, TA_Center);
  
  p.splitRegionH(16);
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
	p.splitRegionV(64, defaultComponentDist);
  p.addLabel("Rank", true, TA_Center);
  p.splitRegionV(64, defaultComponentDist);
  p.addLabel("Votes", true, TA_Center);
  p.addLabel("MapName", true, TA_Center);

	ResultBox = VoteBox(addListBox(class'VoteBox'));

	// Configure components.
  infoTipsLabel.setFont(F_Bold);
  voteButton.bDisabled = xClient.client.bSpectator;
	loadMapList();
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

	// Check if the map list is available.
	if (!bMapListAvailable || xConf == none) {
		addMap("Receiving map list...");
		return;
	}
  
	// Load the map list.
	index = 0;
	while (index < mapListData.getInt("numMaps")) {
    mapName = mapListData.getString("maps", index);
    
		// Add map?
		if (class'NexgenUtil'.static.isValidLevel(mapName)) {
			addMap(mapName);
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
  	
  mapname = MapListBoxItem(mapList.selectedItem).displayText;
	
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
  if (mapList.selectedItem == none) {
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


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new map to the map list.
 *  $PARAM        mapName  Name of the map that is to be added.
 *  $REQUIRE      mapName != ""
 *
 **************************************************************************************************/
function string addMap(string mapName) {
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
  if (container.containerID == class'UrSMapVoteConfigDC'.default.containerID) {
		xConf = container;
		if(mapListData != none) loadMapList();
    
      tipColor.R = xConf.getByte("tipColorR");
      tipColor.B = xConf.getByte("tipColorG");
      tipColor.G = xConf.getByte("tipColorB");
      infoTipsLabel.setTextColor(tipColor);
      hintLabel.setTextColor(tipColor);
	}
  else if (container.containerID == "maplist") {
		mapListData = container;
		bMapListAvailable = true;
		if(xConf != none) loadMapList();
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
  local VoteBoxItem item;
  local int i;
  
  // Create a new entry
  item = VoteBoxItem(ResultBox.items.append(class'VoteBoxItem'));
	item.VoteCount = Votes;
	item.rank      = rank + 1;
	
	i = InStr(Caps(MapName), ".UNR");
  if(i != -1) MapName = Left(MapName, i);
  
	item.MapName   = mapname;
	
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
    if (mapList.selectedItem == none || MapListBoxItem(mapList.selectedItem).displayText == "") {
      // xClient.client.showMsg("<C00>You have to select a map first!");
      return;
    }
    
    mapSelected();
    if(!xClient.client.bSpectator) xClient.client.player.consoleCommand("mutate BDBMAPVOTE MAP"@MapListBoxItem(mapList.selectedItem).displayText $".unr");
  }
  
  // ResultBox DoubleClicked?
  if(control == ResultBox && eventType == DE_DoubleClick) {
    if (ResultBox.selectedItem == none || ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem)) == "") {
      // xClient.client.showMsg("<C00>You have to select a map first!");
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
          mapList.selectedItem != none && MapListBoxItem(mapList.selectedItem).displayText == "") {
       //  xClient.client.showMsg("<C00>You have to select a map!");
        return;
      }
      if (mapList.selectedItem != none) mapname = MapListBoxItem(mapList.selectedItem).displayText;
      else mapname = ResultBox.getMapName(VoteBoxItem(ResultBox.SelectedItem));
      
      xClient.client.player.consoleCommand("mutate BDBMAPVOTE MAP"@mapname $".unr");
      
		}
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
