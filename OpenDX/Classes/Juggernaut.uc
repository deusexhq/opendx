//=============================================================================
// yee
//=============================================================================
class Juggernaut expands TCTeam;

var TCPlayer Juggernaut;
var bool bShouldRun;

function Tick(float Deltatime)
{
	if(bShouldRun && Juggernaut == None)
	{
		Settings.Print("Juggernaut was missing.. resetting teams.");
		bShouldRun=False;
		ResetTeams();
	}
}

function Killed( pawn Killer, pawn Other, name damageType )
{
	local TCPlayer KillerTC, VictimTC;
	
	KillerTC = TCPlayer(Killer);
	VictimTC = TCPlayer(Other);
	Super.Killed(Killer,Other,damageType);
	
	if(VictimTC == Juggernaut && Juggernaut != None) //Did the juggernaut just die
	{
		Settings.Print("|P2The juggernaut has died!");
		Juggernaut = None;
		bShouldRun = False;
		VictimTC.RemovePerkbyName("Juggernaut");
		TCPRI(VictimTC.PlayerReplicationInfo).bJuggernaut = False;
		ResetTeams();
	}
	
	if(Juggernaut == None)
	{
		if(KillerTC != None && KillerTC.PlayerReplicationInfo.Streak >= Settings.StreakLimit)
		{
			bShouldRun = True;
			Juggernaut = KillerTC;
			TCPRI(KillerTC.PlayerReplicationInfo).bJuggernaut = True;
			Settings.Print("|P2"$KillerTC.PlayerReplicationInfo.PlayerName$" became the juggernaut!");
			JuggernautTeams();
			KillerTC.GetPerk("OpenDX.Juggernaut");
		}
	}
}

function JuggernautTeams()
{
	local TCPlayer TCP;
	local int jteam;
	
	jteam = Juggernaut.PlayerReplicationInfo.Team;
	
	foreach AllActors(class'TCPlayer', TCP)
	{
		if(!TCPRI(TCP.PlayerReplicationInfo).bJuggernaut)
		{
			TCPRI(TCP.PlayerReplicationInfo).tOldTeam = TCP.PlayerReplicationInfo.Team;
			
			if(jteam == 0)
				tSwapPlayer(TCP, 1, True, True);
			else
				tSwapPlayer(TCP, 0, True, True);
		}
	}
}

function ResetTeams()
{
	local TCPlayer TCP;
	
	foreach AllActors(class'TCPlayer', TCP)
	{
		tSwapPlayer(TCP, TCPRI(TCP.PlayerReplicationInfo).tOldTeam, True, True);
	}
}

defaultproperties
{
	GTName="Juggernaut Team"
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) - |P2(Get a high streak to become the juggernaut!)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) - |P2(Get a high streak to become the juggernaut!)"
		//bDisableDefaultScoring=True
}
