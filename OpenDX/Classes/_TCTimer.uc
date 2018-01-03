//================================================================================
// Based on ANNA's Timer system
//================================================================================
class _TCTimer extends Actor;

var vector iLoc;
var Rotator iRot;
var int cMins;
var int cSecs;

function TCControls GetControls()
{
	local TCControls TCC;
	
	//if(Role < ROLE_Authority)
	//{
		if(TCDeathmatch(Level.Game) != None) TCC = TCDeathMatch(Level.Game).Settings;
		if(TCTeam(Level.Game) != None) TCC = TCTeam(Level.Game).Settings;
		
		return TCC;
	//}
}


function PostBeginPlay()
{
	local TCControls TCGet;

	TCGet = GetControls();
	if(TCGet.AutoIdleTime > 0)
		SetTimer(1,True);
}

simulated function Tick(float deltaTime)
{
    if(TCPlayer(Owner) == none)
    {
        destroy();
        return;
    }

    TCPlayer(Owner)._timerSeconds += deltaTime;
}

function Timer()
{
	local bool bAutoIdle, bAutoIdleKick;
	local bool bMinutePassed;
	
	cSecs++;
	if(cSecs == 60)
	{
		bMinutePassed=True;
		cSecs = 0;
	}
	
	if(GetControls().AutoIdleTime > 0)
		bAutoIdle=True;
		
	if(GetControls().AutoIdleKickTime > 0)
		bAutoIdleKick=True;
		
	if(TCPlayer(Owner).Location == iLoc && TCPlayer(Owner).ViewRotation == iRot)
	{
		if(bMinutePassed)
			TCPlayer(Owner).IdleCounter++;
	}
	else
	{
		if(TCPlayer(Owner).bAway)
		{
			TCPlayer(Owner).bAway=False;
			TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bAway=False;
			GetControls().Print(TCPlayer(Owner).PlayerReplicationInfo.PlayerName$" has returned.");
		}
		iLoc = TCPlayer(Owner).Location;
		iRot = TCPlayer(Owner).ViewRotation;
		TCPlayer(Owner).IdleCounter=0;
	}
	
	if(TCPlayer(Owner).IsInState('Dying'))
		TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bDead=True;
	else TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bDead=False;
	
	if(bAutoIdle && TCPlayer(Owner).IdleCounter >= GetControls().AutoIdleTime && !TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bAway)
	{
		TCPlayer(Owner).bAway=True;
		TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bAway=True;
		GetControls().Print(TCPlayer(Owner).PlayerReplicationInfo.PlayerName$" was idle for "$GetControls().AutoIdleTime$" minutes and has been set as AWAY.");
	}
	if(bAutoIdleKick && TCPlayer(Owner).IdleCounter >= GetControls().AutoIdleKickTime && TCPRI(TCPlayer(Owner).PlayerReplicationInfo).bAway)
	{
		GetControls().Print(TCPlayer(Owner).PlayerReplicationInfo.PlayerName$" was idle for "$GetControls().AutoIdleKickTime$" minutes and removed from the game.");
		TCPlayer(Owner).Destroy();
	}
}

defaultproperties
{
    bHidden=true
}
