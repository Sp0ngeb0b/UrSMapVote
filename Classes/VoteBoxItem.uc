class VoteBoxItem expands MapItem;

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
  if (VoteBoxItem(a).voteCount > 0 && VoteBoxItem(b).voteCount > 0) {
    if (VoteBoxItem(a).voteCount < VoteBoxItem(b).voteCount) {
      return 1;
    } else {
      return -1;
    }
  }
  if (VoteBoxItem(a).mapName < VoteBoxItem(b).mapName) {
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
