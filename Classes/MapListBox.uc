class MapListBox extends UWindowListBox;

var bool bShowScreenshot;
var bool bResize;

const screenShotDimensionBase = 48;

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
  local float textHeightX, textHeightY;
  local MapListBoxItem xItem;
  local int screenShotDimension;
  
  xItem = MapListBoxItem(item);
  
  // Font  
  if(bResize) c.font = root.fonts[F_Large];
  else        c.font = root.fonts[F_Normal];

  // Screenshot
  if(!xItem.bDummy && bShowScreenshot) {
    c.drawColor.r = 255;
    c.drawColor.g = 255;
    c.drawColor.b = 255;        
    screenShotDimension = screenShotDimensionBase*(1+int(bResize));
    if(xItem.mapShot != none) DrawStretchedTexture(c, x + 2, y, screenShotDimension, screenShotDimension, xItem.mapShot);
    offsetX += screenShotDimension + 4;
    c.StrLen("TEST", textHeightX, textHeightY);
    offsetY  = screenShotDimension/2 - textHeightY/2;
    ItemHeight=screenShotDimension+2;
  } else { 
    ItemHeight=13.000000;
  }

  if(!xItem.bDummy && MapListBoxItem(item).bSelected) {
    if (MapListBoxItem(item).bMarked) {
      c.drawColor.r = 0;
      c.drawColor.g = 0;
      c.drawColor.b = 128;
      drawStretchedTexture(c, x + offsetX, y, w - offsetX, h - 1, Texture'WhiteTexture');
      c.drawColor.r = 255;
      c.drawColor.g = 0;
      c.drawColor.b = 0;
    } else {
      c.drawColor.r = 0;
      c.drawColor.g = 0;
      c.drawColor.b = 128;
      drawStretchedTexture(c, x + offsetX, y, w - offsetX, h - 1, Texture'WhiteTexture');
      c.drawColor.r = 255;
      c.drawColor.g = 255;
      c.drawColor.b = 255;
    }
  } else if (MapListBoxItem(item).bMarked) {
    c.drawColor.r = 255;
    c.drawColor.g = 0;
    c.drawColor.b = 0;
  } else {
    c.drawColor.r = 0;
    c.drawColor.g = 0;
    c.drawColor.b = 0;
  }

  clipText(c, x + offsetX + 4, y + offsetY, xItem.mapName);
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
 *  $DESCRIPTION  Returns the item with the given mapName.
 *  $PARAM        map  mapName of the searched item.
 *  $REQUIRE      item != none
 *  $RETURN       The item with the specified mapName.
 *
 **************************************************************************************************/
function MapItem getMap(string mapName) {
  local MapItem item;

  // Search for item.
  for (item = MapItem(items); item != none; item = MapItem(item.next)) {
    if (item.mapName == mapName) {
      return item;
    }
  }

  // Map not found, return none.
  return none;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     ListClass=Class'MapListBoxItem'
}
