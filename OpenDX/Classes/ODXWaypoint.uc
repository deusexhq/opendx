//=============================================================================
// Sets the player class waypoint to any object
//=============================================================================

class ODXWaypoint extends ODXTrigger;

var() name MarkerTag; //Tag of the actor we want to mark
var() int MarkerLifespan; //Optional lifespan of the marker
var() string MarkerName; //Optional name of the marker
var() bool bMarkerDeleter; //If true, ignore all variables and only deletes the current markers
var() bool bLocalPlayerOnly; //Only do the markers for the triggering player, false triggers for ALL
var() string PrintMsg; //Do we also want to print a clientmessage to the player

function BeenTriggeredODX(TCPlayer Ins)
{
	local TCPlayer TCP;
	local actor a;
	
	if(PrintMsg != "") //Do the print before anything
	{
		if(bLocalPlayerOnly)
		{
			ins.ClientMessage(PrintMsg);
		}
		else
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.ClientMessage(PrintMsg);
			}
		}
	}
	
	if(bMarkerDeleter) //If we're deleting...
	{
		if(bLocalPlayerOnly)
		{
			ins.CancelWaypoint();
		}
		else
		{
			foreach AllActors(class'TCPlayer',TCP)
			{
				TCP.CancelWaypoint();
			}
		}
		return; //Don't go to the marker creating if we're a deleter
	}
	
	if(MarkerTag != 'None')
	{
		foreach AllActors(class'Actor',A)
		{
			if(A.Tag == MarkerTag)
			{
				if(bLocalPlayerOnly)
				{
					ins.SetWaypoint(A, MarkerName, MarkerLifespan);
				}
				else
				{
					foreach AllActors(class'TCPlayer',TCP)
					{
						TCP.SetWaypoint(A, MarkerName, MarkerLifespan);
					}
				}
			}
		}
	}
}

defaultproperties
{

}
