class MapListBoxItem extends MapItem;

var bool bMarked;
var bool bDummy;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Compares two UWindowList items.
 *  $PARAM        a  First item to compare.
 *  $PARAM        b  Second item to compare.
 *  $REQUIRE      a != none && b != none
 *  $RETURNS      -1 If the first item is 'smaller' then the second item, otherwise 1 is returned.
 *  $OVERRIDE
 *
 **************************************************************************************************/
 function int Compare(UWindowList T, UWindowList B) {
   if(Caps(MapListBoxItem(T).mapName) < Caps(MapListBoxItem(B).mapName))
    return -1;
   return 1;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
}
