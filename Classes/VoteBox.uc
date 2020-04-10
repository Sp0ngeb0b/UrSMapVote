class VoteBox extends UWindowListBox;

var bool bShowScreenshot;
var bool bResize;

const screenShotDimensionBase = 40; 

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
  local int offsetX, offsetY;
  local float textSizeX, textSizeY;
  local texture flagTex;
  local color backgroundColor;
  local VoteBoxItem xItem;
  local int screenShotDimension;

  xItem = VoteBoxItem(item);
  
  // Font  
  if(bResize) c.font = root.fonts[F_LargeBold];
  else        c.font = root.fonts[F_Bold];
  
  if(bShowScreenshot) {
    if(bResize) screenShotDimension = 128;
    else screenShotDimension = screenShotDimensionBase;
    ItemHeight=screenShotDimension+2;
    c.StrLen("TEST", textSizeX, textSizeY);
    offsetY = screenShotDimension/2 - textSizeY/2;
  }
  
  if(xItem.bSelected) {
    c.drawColor.r = 0;
    c.drawColor.g = 0;
    c.drawColor.b = 128;
    drawStretchedTexture(c, x, y, w - screenShotDimension - 4, h - 2, Texture'WhiteTexture');
    c.drawColor.r = 255;
    c.drawColor.g = 255;
    c.drawColor.b = 255;
  } else {
    c.drawColor.r = 0;
    c.drawColor.g = 0;
    c.drawColor.b = 0;
  }
  
  // rank
  offsetX = 24;
  clipText(c, x + offsetX, y+offsetY, xItem.rank);
  
  // Votes.
  offsetX += 64;
  clipText(c, x + offsetX, y+offsetY, xItem.voteCount);

  // Draw mapName.
  offsetX += 64;
  clipText(c, x + offsetX, y+offsetY, getMapName(xItem));
    
  // Screenshot.
  if(bShowScreenshot) {
    c.drawColor.r = 255;
    c.drawColor.g = 255;
    c.drawColor.b = 255;        
    if(xItem.mapShot != none) DrawStretchedTexture(c, w - screenShotDimension - 2, y, screenShotDimension, screenShotDimension, xItem.mapShot);
  }
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
function string getMapName(VoteBoxItem item) {
  return item.mapName;
}

function selectMap(string mapName) {
  local VoteBoxItem MapItem;

  for(MapItem=VoteBoxItem(Items); MapItem!=None; MapItem=VoteBoxItem(MapItem.Next) )
   {
      if(mapName ~= MapItem.mapName)
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
