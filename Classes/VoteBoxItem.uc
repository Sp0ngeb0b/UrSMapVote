class VoteBoxItem expands UWindowListBoxItem;

var int    Rank;
var string MapName;
var int    VoteCount;

function int Compare(UWindowList T, UWindowList B) {
  if(Caps(VoteBoxItem(T).MapName) < Caps(VoteBoxItem(B).MapName))
    return -1;
  return 1;
}

defaultproperties
{
}
