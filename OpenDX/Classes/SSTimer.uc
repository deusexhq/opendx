//================================================================================
// External time-keeper for Sharpshooter
//================================================================================
class SSTimer extends Actor;

var Sharpshooter myGame;
var int SSCount, SSDefaultCount;

function Timer()
{
	local TCPlayer TCP;
	
	SSCount--;
	if(SSCount == 5)
	{
		foreach AllActors(class'TCPlayer', TCP)
			TCP.Notif("Five seconds remaining.");
	}
	if(SSCount <= 0)
	{
		foreach AllActors(class'TCPlayer', TCP)
			TCP.Notif("New round!");
		SSCount = SSDefaultCount;
		myGame.RollItems();
	}
}

defaultproperties
{
    bHidden=true
}
