//=============================================================================
// Way around the relevancy issue...
//=============================================================================
class wpDummy extends Actor;

var string wpName;
var Actor wpActor;
var bool bCanDelete;

function PostBeginPlay()
{
	SetTimer(0.5,True);
}

function Timer()
{
	local TCPlayer TCP;
	local bool bFound;
	local vector modv;
	
	if(bCanDelete)
		if(wpActor == None)
			Destroy();
	
	if(wpActor != None)
	{
		modv = wpActor.location;
		if(pawn(wpActor) != None)
		{
			modv.z += 20;
		}
		
		foreach Allactors(class'TCPlayer', TCP)
			if(TCPRI(TCP.PlayerReplicationInfo).wpTargetPRI == Self)
				bFound=True;
				
		if(bFound && wpActor != None)
			SetLocation(modv);
		
		if(!bFound)
			Destroy();
	}
}

defaultproperties
{
	Tag='Waypoint'
	bHidden=True
	bAlwaysRelevant=True
}
