class UrSMapVoteSettings extends NexgenPanel;

var UrSMapVoteClient xClient;
var NexgenSharedDataContainer xConf;

var NexgenEditControl delayInp;
var NexgenEditControl voteTimeInp;
var NexgenEditControl RepeatInp;
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
	local int region;
	local int index;

  xClient = UrSMapVoteClient(client.getController(class'UrSMapVoteClient'.default.ctrlID));

  // Create layout & add components.
	createPanelRootRegion();
	splitRegionH(12, defaultComponentDist);
	addLabel("MapVote Settings", true, TA_Center);

	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');

	splitRegionH(20, defaultComponentDist, , true);
	region = currRegion;
	skipRegion();
	splitRegionV(196, , , true);
	skipRegion();
	divideRegionV(2, defaultComponentDist);
	saveButton = addButton(client.lng.saveTxt);
	resetButton = addButton(client.lng.resetTxt);

	selectRegion(region);
	selectRegion(divideRegionH(9, defaultComponentDist));
  
  divideRegionV(2, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  divideRegionV(7, defaultComponentDist);
  for(index=0; index<4; index++) divideRegionV(2, defaultComponentDist);

  addLabel("VoteWindow Delay", true, TA_Left);
  delayInp = addEditBox(, 64);

  addLabel("Vote Time", true, TA_Left);
  voteTimeInp = addEditBox(, 64);

  addLabel("Repeat Limit", true, TA_Left);
  RepeatInp = addEditBox(, 64);
  
  addLabel("Tip Duration", true, TA_Left);
  tipDurationInp = addEditBox(, 64);
  
  addLabel("Tip Color:", true, TA_Left);
  addLabel("R", true, TA_Right);
  tipColorRInp = addEditBox(, 64);
  addLabel("G", true, TA_Right);
  tipColorGInp = addEditBox(, 64);
  addLabel("B", true, TA_Right);
  tipColorBInp = addEditBox(, 64);
  
  for(index=0; index<8; index++) splitRegionV(32, defaultComponentDist);
  
  for(index=0; index<8; index++) {
    addLabel("Tip "$index+1, true, TA_Left);
    infoTipsInp[index] = addEditBox();
  }

  // Configure components.
  delayInp.setNumericOnly(true);
	voteTimeInp.setNumericOnly(true);
	RepeatInp.setNumericOnly(true);
  
  tipDurationInp.setNumericOnly(true);
  tipDurationInp.setNumericFloat(true);
  
  tipColorRInp.setNumericOnly(true);
  tipColorGInp.setNumericOnly(true);
  tipColorBInp.setNumericOnly(true);

  delayInp.setMaxLength(2);
  voteTimeInp.setMaxLength(3);
  RepeatInp.setMaxLength(2);
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
  voteTimeInp.setValue(xConf.getString("votelimit"));
  RepeatInp.setValue(xConf.getString("RepeatLimit"));
  tipDurationInp.setValue(Left(xConf.getString("tipDuration"), InStr(xConf.getString("tipDuration"), ".")+3));
  tipColorRInp.setValue(xConf.getString("tipColorR"));
  tipColorGInp.setValue(xConf.getString("tipColorG"));
  tipColorBInp.setValue(xConf.getString("tipColorB"));
  for(index=0; index<8; index++) infoTipsInp[index].setValue(xConf.getString("infoTips", index));
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
  xClient.setVar("UrSmv_config", "votelimit", voteTimeInp.getValue());
  xClient.setVar("UrSmv_config", "RepeatLimit", RepeatInp.getValue());
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
			case "votelimit": voteTimeInp.setValue(container.getString(varName));           break;
			case "RepeatLimit": RepeatInp.setValue(container.getString(varName));           break;
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
