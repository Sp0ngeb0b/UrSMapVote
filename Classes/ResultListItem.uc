class ResultListItem expands MapItem;

var int rank;
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
  if (ResultListItem(a).voteCount > 0 && ResultListItem(b).voteCount > 0) {
    if (ResultListItem(a).voteCount < ResultListItem(b).voteCount) {
      return 1;
    } else {
      return -1;
    }
  }
  if (ResultListItem(a).mapName < ResultListItem(b).mapName) {
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
}
