class UrSMapVoteConfigDC extends NexgenSharedDataContainer;

var UrSMapVoteConfig xConf;

// Map Vote Settings
var int opendelay;
var int votelimit;
var int MidGameVotePercent;
var string GameType;
var int RepeatLimit;
var string votedMaps[32];
var string infoTips[8];
var float tipDuration;
var byte tipColorR;
var byte tipColorG;
var byte tipColorB;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the data that for this shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function loadData() {
  local int index;

  xConf = UrSMapVoteConfig(xControl.xConf);

  opendelay           = xConf.opendelay;
  votelimit           = xConf.votelimit;
  MidGameVotePercent  = xConf.MidGameVotePercent;
  GameType            = xConf.GameType;
  RepeatLimit         = xConf.RepeatLimit;
  for (index = 0; index < arrayCount(votedMaps); index++)
    votedMaps[index]  = xConf.votedMaps[index];
    
  for (index = 0; index < arrayCount(infoTips); index++)
    infoTips[index]  = xConf.infoTips[index];
    
   tipDuration        = xConf.tipDuration;
   tipColorR          = xConf.tipColorR;
   tipColorG          = xConf.tipColorG;
   tipColorB          = xConf.tipColorB;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the data store in this shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function saveData() {
  xConf.saveConfig();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be changed.
 *  $PARAM        value    New value for the variable.
 *  $PARAM        index    Array index in case the variable is an array.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $OVERRIDE
 *
 **************************************************************************************************/
function set(string varName, coerce string value, optional int index) {
  switch (varName) {
    case "opendelay":              opendelay              = clamp(int(value), 0, 999);    if (xConf != none) { xConf.opendelay          = opendelay;              } break;
    case "votelimit":              votelimit              = clamp(int(value), 0, 999);    if (xConf != none) { xConf.votelimit          = votelimit;              } break;
    case "MidGameVotePercent":     MidGameVotePercent     = clamp(int(value), 0, 100);    if (xConf != none) { xConf.MidGameVotePercent = MidGameVotePercent;     } break;
    case "GameType":               GameType               = value;                        if (xConf != none) { xConf.GameType           = GameType;               } break;
    case "RepeatLimit":            RepeatLimit            = clamp(int(value), 0, 999);    if (xConf != none) { xConf.RepeatLimit        = RepeatLimit;            } break;
    case "votedMaps":              votedMaps[index]       = value;                        if (xConf != none) { xConf.votedMaps[index]   = votedMaps[index];       } break;
    case "infoTips":               infoTips[index]        = value;                        if (xConf != none) { xConf.infoTips[index]    = infoTips[index];        } break;
    case "tipDuration":            tipDuration            = fclamp(float(value), 0, 99);  if (xConf != none) { xConf.tipDuration        = tipDuration;            } break;
    case "tipColorR":              tipColorR              = clamp(int(value), 0, 255);    if (xConf != none) { xConf.tipColorR          = tipColorR;              } break;
    case "tipColorG":              tipColorG              = clamp(int(value), 0, 255);    if (xConf != none) { xConf.tipColorG          = tipColorG;              } break;
    case "tipColorB":              tipColorB              = clamp(int(value), 0, 255);    if (xConf != none) { xConf.tipColorB          = tipColorB;              } break;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to read the variable value.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $PARAM        varName  Name of the variable whose access is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable may be read by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool mayRead(NexgenExtendedClientController xClient, string varName) {
  switch (varName) {
    case "opendelay":            return true;
    case "votelimit":            return true;
    case "MidGameVotePercent":   return true;
    case "GameType":             return true;
    case "RepeatLimit":          return true;
    case "votedMaps":            return true;
    case "infoTips":             return true;
    case "tipDuration":          return true;
    case "tipColorR":            return true;
    case "tipColorG":            return true;
    case "tipColorB":            return true;
    default:                     return false;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to change the variable value.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $PARAM        varName  Name of the variable whose access is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable may be changed by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool mayWrite(NexgenExtendedClientController xClient, string varName) {
  switch (varName) {
    case "opendelay":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "votelimit":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "MidGameVotePercent":   return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "GameType":             return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "RepeatLimit":          return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "votedMaps":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "infoTips":             return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "tipDuration":          return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "tipColorR":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "tipColorG":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    case "tipColorB":            return xClient.client.hasRight(xClient.client.R_ServerAdmin);
    default:                     return false;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified client is allowed to save the data in this container.
 *  $PARAM        xClient  The controller of the client that is to be checked.
 *  $REQUIRE      xClient != none
 *  $RETURN       True if the data may be saved by the specified client, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool maySaveData(NexgenExtendedClientController xClient) {
  return xClient.client.hasRight(xClient.client.R_ServerAdmin);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reads the byte value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be retrieved.
 *  $PARAM        index    Index of the element in the array that is to be retrieved.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $RETURN       The byte value of the specified variable.
 *
 **************************************************************************************************/
function byte getByte(string varName, optional int index) {
  switch (varName) {
    case "tipColorR":  return tipColorR;
    case "tipColorG":  return tipColorG;
    case "tipColorB":  return tipColorB;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reads the integer value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be retrieved.
 *  $PARAM        index    Index of the element in the array that is to be retrieved.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $RETURN       The integer value of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function int getInt(string varName, optional int index) {
  switch (varName) {
    case "opendelay":           return opendelay;
    case "votelimit":           return votelimit;
    case "MidGameVotePercent":  return MidGameVotePercent;
    case "RepeatLimit":         return RepeatLimit;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reads the float value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be retrieved.
 *  $PARAM        index    Index of the element in the array that is to be retrieved.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $RETURN       The float value of the specified variable.
 *
 **************************************************************************************************/
function float getFloat(string varName, optional int index) {
  switch (varName) {
    case "tipDuration":         return tipDuration;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reads the string value of the specified variable.
 *  $PARAM        varName  Name of the variable whose value is to be retrieved.
 *  $PARAM        index    Index of the element in the array that is to be retrieved.
 *  $REQUIRE      varName != "" && imply(isArray(varName), 0 <= index && index <= getArraySize(varName))
 *  $RETURN       The string value of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function string getString(string varName, optional int index) {
  switch (varName) {
    case "opendelay":            return string(opendelay);
    case "votelimit":            return string(votelimit);
    case "MidGameVotePercent":   return string(MidGameVotePercent);
    case "GameType":             return GameType;
    case "RepeatLimit":          return string(RepeatLimit);
    case "votedMaps":            return votedMaps[index];
    case "infoTips":             return infoTips[index];
    case "tipDuration":          return string(tipDuration);
    case "tipColorR":            return string(tipColorR);
    case "tipColorG":            return string(tipColorG);
    case "tipColorB":            return string(tipColorB);

  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the number of variables that are stored in the container.
 *  $RETURN       The number of variables stored in the shared data container.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function int getVarCount() {
  return 11;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the variable name of the variable at the specified index.
 *  $PARAM        varIndex  Index of the variable whose name is to be retrieved.
 *  $REQUIRE      0 <= varIndex && varIndex <= getVarCount()
 *  $RETURN       The name of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function string getVarName(int varIndex) {
  switch (varIndex) {
    case 0:  return "opendelay";
    case 1:  return "votelimit";
    case 2:  return "MidGameVotePercent";
    case 3:  return "GameType";
    case 4:  return "RepeatLimit";
    case 5:  return "votedMaps";
    case 6:  return "infoTips";
    case 7:  return "tipDuration";
    case 8:  return "tipColorR";
    case 9:  return "tipColorG";
    case 10: return "tipColorB";
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the data type of the specified variable.
 *  $PARAM        varName  Name of the variable whose data type is to be retrieved.
 *  $REQUIRE      varName != ""
 *  $RETURN       The data type of the specified variable.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function byte getVarType(string varName) {
  switch (varName) {
    case "opendelay":            return DT_INT;
    case "votelimit":            return DT_INT;
    case "MidGameVotePercent":   return DT_INT;
    case "GameType":             return DT_STRING;
    case "RepeatLimit":          return DT_INT;
    case "votedMaps":            return DT_STRING;
    case "infoTips":             return DT_STRING;
    case "tipDuration":          return DT_FLOAT;
    case "tipColorR":            return DT_BYTE;
    case "tipColorG":            return DT_BYTE;
    case "tipColorB":            return DT_BYTE;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the array length of the specified variable.
 *  $PARAM        varName  Name of the variable which is to be checked.
 *  $REQUIRE      varName != "" && isArray(varName)
 *  $RETURN       The size of the array.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function int getArraySize(string varName) {
  switch (varName) {
    case "votedMaps":           return arrayCount(votedMaps);
    case "infoTips":            return arrayCount(infoTips);
    default:                    return 0;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified variable is an array.
 *  $PARAM        varName  Name of the variable which is to be checked.
 *  $REQUIRE      varName != ""
 *  $RETURN       True if the variable is an array, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool isArray(string varName) {
  switch (varName) {
    case "votedMaps":
    case "infoTips":
      return true;
    default:
      return false;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     containerID="UrSmv_config"
}
