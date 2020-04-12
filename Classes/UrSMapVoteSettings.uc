class UrSMapVoteSettings extends NexgenPanel;

var UrSMapVoteClient xClient;
var NexgenSharedDataContainer xConf;

var NexgenEditControl delayInp;
var NexgenEditControl voteTimeInp;
var NexgenEditControl repeatInp;
var NexgenEditControl midGameVotePercInp;
var NexgenEditControl tipDurationInp;
var NexgenEditControl tipColorRInp;
var NexgenEditControl tipColorGInp;
var NexgenEditControl tipColorBInp;
var NexgenEditControl infoTipsInp[8];

var UWindowSmallButton resetButton;
var UWindowSmallButton saveButton;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  local int region;
  local int index;

  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));

  // Create layout & add components.
  createPanelRootRegion();
  splitRegionH(12, defaultComponentDist);
  addLabel("MapVote Settings", true, TA_Center);

  splitRegionH(1, defaultComponentDist);
  addComponent(class'NexgenDummyComponent');

  // Buttons
  splitRegionH(20, defaultComponentDist, , true);
  region = currRegion;
  skipRegion();
  splitRegionV(196, , , true);
  skipRegion();
  divideRegionV(2, defaultComponentDist);
  saveButton = addButton(client.lng.saveTxt);
  resetButton = addButton(client.lng.resetTxt);

  selectRegion(region);
  selectRegion(splitRegionH(48, defaultComponentDist));
  
  // Vote settings
  p = addContentPanel(PBT_Transparent); 
  p.divideRegionH(2, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist); 
  p.divideRegionV(2, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist);
  p.addLabel("Vote Start Delay", true, TA_Left);
  delayInp = p.addEditBox(, 64);
  p.addLabel("Vote Time", true, TA_Left);
  voteTimeInp = p.addEditBox(, 64);
  p.addLabel("Block Map for X Rounds", true, TA_Left);
  repeatInp = p.addEditBox(, 64);
  p.addLabel("Mid-game vote percent", true, TA_Left);
  midGameVotePercInp = p.addEditBox(, 64);
  
  // Tips
  p = addContentPanel(); 
  p.splitRegionH(20, defaultComponentDist);
  p.divideRegionV(2, defaultComponentDist);
  region = p.currRegion++;
  p.divideRegionV(2, defaultComponentDist);
  p.splitRegionV(64, defaultComponentDist);
  p.addLabel("Tip Duration", true, TA_Left);
  tipDurationInp = p.addEditBox(, 64);
  p.addLabel("Tip Color:", true, TA_Left);
  p.splitRegionV(16, defaultComponentDist);
  p.addLabel("R", true, TA_Right);
  p.splitRegionV(24+defaultComponentDist, defaultComponentDist);
  tipColorRInp = p.addEditBox(, 24);
  p.splitRegionV(16, defaultComponentDist);
  p.addLabel("G", true, TA_Right);
  p.splitRegionV(24+defaultComponentDist, defaultComponentDist);
  tipColorGInp = p.addEditBox(, 24);
  p.splitRegionV(16, defaultComponentDist);
  p.addLabel("B", true, TA_Right);
  p.splitRegionV(24+defaultComponentDist, defaultComponentDist);
  tipColorBInp = p.addEditBox(, 24);
  p.selectRegion(region);
  p.selectRegion(p.divideRegionH(4, defaultComponentDist));
  for(index=0; index<4; index++) p.divideRegionV(2, defaultComponentDist);
  for(index=0; index<8; index++) p.splitRegionV(32, defaultComponentDist);
  for(index=0; index<8; index++) {
    p.addLabel("Tip "$index+1, true, TA_Left);
    infoTipsInp[index] = p.addEditBox();
  }

  // Configure components.
  delayInp.setNumericOnly(true);
  voteTimeInp.setNumericOnly(true);
  repeatInp.setNumericOnly(true);
  
  tipDurationInp.setNumericOnly(true);
  tipDurationInp.setNumericFloat(true);
  
  tipColorRInp.setNumericOnly(true);
  tipColorGInp.setNumericOnly(true);
  tipColorBInp.setNumericOnly(true);

  delayInp.setMaxLength(2);
  voteTimeInp.setMaxLength(3);
  repeatInp.setMaxLength(2);
  tipDurationInp.setMaxLength(3);

  setValues();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of all input components to the current settings.
 *
 **************************************************************************************************/
function setValues() {
  local int index;
  
  // Quit if configuration is not available.
  if (xConf == none) return;

  delayInp.setValue(xConf.getString("opendelay"));
  voteTimeInp.setValue(xConf.getString("voteLimit"));
  repeatInp.setValue(xConf.getString("repeatLimit"));
  midGameVotePercInp.setValue(xConf.getString("midGameVotePercent"));
  tipDurationInp.setValue(Left(xConf.getString("tipDuration"), InStr(xConf.getString("tipDuration"), ".")+3));
  tipColorRInp.setValue(xConf.getString("tipColorR"));
  tipColorGInp.setValue(xConf.getString("tipColorG"));
  tipColorBInp.setValue(xConf.getString("tipColorB"));
  for(index=0; index<8; index++) infoTipsInp[index].setValue(xConf.getString("infoTips", index));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the game type list.
 *
 **************************************************************************************************
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
*/

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
    setValues();
    resetButton.bDisabled = false;
    saveButton.bDisabled = false;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current settings.
 *
 **************************************************************************************************/
function saveSettings() {
  local int index;

  xClient.setVar("UrSmv_config", "opendelay", delayInp.getValue());
  xClient.setVar("UrSmv_config", "voteLimit", voteTimeInp.getValue());
  xClient.setVar("UrSmv_config", "repeatLimit", repeatInp.getValue());
  xClient.setVar("UrSmv_config", "midGameVotePercent", midGameVotePercInp.getValue());
  xClient.setVar("UrSmv_config", "tipDuration", tipDurationInp.getValue());
  xClient.setVar("UrSmv_config", "tipColorR", tipColorRInp.getValue());
  xClient.setVar("UrSmv_config", "tipColorG", tipColorGInp.getValue());
  xClient.setVar("UrSmv_config", "tipColorB", tipColorBInp.getValue());
  for(index=0; index<8; index++) xClient.setVar("UrSmv_config", "infoTips", infoTipsInp[index].getValue(), index);
  
  xClient.saveSharedData("UrSmv_config");
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
      case "opendelay": delayInp.setValue(container.getString(varName));              break;
      case "voteLimit": voteTimeInp.setValue(container.getString(varName));           break;
      case "repeatLimit": repeatInp.setValue(container.getString(varName));           break;
      case "midGameVotePercent": midGameVotePercInp.setValue(container.getString(varName)); break;
      case "tipDuration": tipDurationInp.setValue(Left(container.getString(varName), InStr(container.getString(varName), ".")+3)); break;
      case "tipColorR": tipColorRInp.setValue(container.getString(varName));           break;
      case "tipColorG": tipColorGInp.setValue(container.getString(varName));           break;
      case "tipColorB": tipColorBInp.setValue(container.getString(varName));           break;
      case "infoTips": infoTipsInp[index].setValue(container.getString(varName, index));break;
    }
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
  super.notify(control, eventType);

  // Button pressed?
  if (control != none && eventType == DE_Click && control.isA('UWindowSmallButton') &&
      !UWindowSmallButton(control).bDisabled) {

    switch (control) {
      case resetButton: setValues(); break;
      case saveButton: saveSettings(); break;
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
     panelIdentifier="UrSmapvotesettings"
     PanelHeight=208.000000
}
