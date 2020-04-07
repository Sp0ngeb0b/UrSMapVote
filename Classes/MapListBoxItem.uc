class MapListBoxItem extends UWindowListBoxItem;

var string displayText;
var int itemID;
var bool bMarked;
var int voteCount;



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
function int compare(UWindowList a, UWindowList b) {
  if (MapListBoxItem(a).voteCount > 0 && MapListBoxItem(b).voteCount > 0) {
  	if (MapListBoxItem(a).voteCount < MapListBoxItem(b).voteCount) {
		  return 1;
	  } else {
	  	return -1;
	  }
	}
	if (MapListBoxItem(a).displayText < MapListBoxItem(b).displayText) {
		return -1;
	} else {
		return 1;
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     itemID=-1
}
