class VoteBox extends UWindowListBox;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the specified listbox item.
 *  $PARAM        c     The canvas object on which the rendering will be performed.
 *  $PARAM        item  Item to render.
 *  $PARAM        x     Horizontal offset on the canvas.
 *  $PARAM        y     Vertical offset on the canvas.
 *  $PARAM        w     Width of the item that is to be rendered.
 *  $PARAM        h     Height of the item that is to be rendered.
 *  $REQUIRE      c != none && item != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function drawItem(Canvas c, UWindowList item, float x, float y, float w, float h) {
  local int offsetX;
  local texture flagTex;
  local color backgroundColor;
  
  if(VoteBoxItem(item).bSelected) {
    c.drawColor.r = 0;
    c.drawColor.g = 0;
    c.drawColor.b = 128;
    drawStretchedTexture(c, x, y, w, h - 1, Texture'WhiteTexture');
    c.drawColor.r = 255;
    c.drawColor.g = 255;
    c.drawColor.b = 255;
  } else {
    c.drawColor.r = 0;
    c.drawColor.g = 0;
    c.drawColor.b = 0;
  }

  c.font = root.fonts[F_Bold];
  
  // Rank
  offsetX = 24;
  clipText(c, x + offsetX, y, getRank(VoteBoxItem(item)));
  
  // Votes.
  offsetX += 64;
  clipText(c, x + offsetX, y, getVoteCount(VoteBoxItem(item)));

  // Draw mapname.
  offsetX += 92;
  clipText(c, x + offsetX, y, getMapName(VoteBoxItem(item)));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when an item was double clicked on.
 *  $PARAM        item  The item which was double clicked.
 *  $REQUIRE      item != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function doubleClickItem(UWindowListBoxItem item) {
  if (notifyWindow != none) {
    notifyWindow.notify(self, DE_DoubleClick);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the text displayed for a list item.
 *  $PARAM        item  The item for which its display text has to be determined.
 *  $REQUIRE      item != none
 *  $RETURN       The text that should be displayed for the specified item in the listbox.
 *
 **************************************************************************************************/
function int getVoteCount(VoteBoxItem item) {
  return item.VoteCount;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the text displayed for a list item.
 *  $PARAM        item  The item for which its display text has to be determined.
 *  $REQUIRE      item != none
 *  $RETURN       The text that should be displayed for the specified item in the listbox.
 *
 **************************************************************************************************/
function string getMapName(VoteBoxItem item) {
  return item.MapName;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the text displayed for a list item.
 *  $PARAM        item  The item for which its display text has to be determined.
 *  $REQUIRE      item != none
 *  $RETURN       The text that should be displayed for the specified item in the listbox.
 *
 **************************************************************************************************/
function int getRank(VoteBoxItem item) {
  return item.rank;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new player to the list.
 *  $RETURN       The player item that was added to the list.
 *  $ENSURE       result != none
 *
 **************************************************************************************************/
function VoteBoxItem addVote() {
  return VoteBoxItem(items.append(listClass));
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Removes the player with the specified player code from the list.
 *  $PARAM        playerNum  The player to remove.
 *  $REQUIRE      playerNum >= 0
 *  $ENSURE       getPlayer(playerNum) == none
 *
 **************************************************************************************************/
function removeVote(string map) {
  local VoteBoxItem item;

  // Search for map.
  for (item = VoteBoxItem(items); item != none; item = VoteBoxItem(item.next)) {
    if (item.MapName == map) {
      item.remove();
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the item with the given mapname.
 *  $PARAM        map  Mapname of the searched item.
 *  $REQUIRE      item != none
 *  $RETURN       The item with the specified mapname.
 *
 **************************************************************************************************/
function VoteBoxItem getMap(string map) {
  local VoteBoxItem item;

  // Search for item.
  for (item = VoteBoxItem(items); item != none; item = VoteBoxItem(item.next)) {
    if (item.MapName == map) {
      return item;
    }
  }

  // Player not found, return none.
  return none;
}

function SelectMap(string MapName) {
  local VoteBoxItem MapItem;

  for(MapItem=VoteBoxItem(Items); MapItem!=None; MapItem=VoteBoxItem(MapItem.Next) )
   {
      if(MapName ~= MapItem.MapName)
      {
         SetSelectedItem(MapItem);
         MakeSelectedVisible();
         break;
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
     ListClass=Class'VoteBoxItem'
}
