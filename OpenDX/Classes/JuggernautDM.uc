//=============================================================================
// yee
//=============================================================================
class JuggernautDM expands TCDeathmatch;

var TCPlayer Juggernaut;


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
		VictimTC.RemovePerkbyName("Juggernaut");
		TCPRI(VictimTC.PlayerReplicationInfo).bJuggernaut = False;
	}
	
	if(Juggernaut == None)
	{
		if(KillerTC != None && KillerTC.PlayerReplicationInfo.Streak >= Settings.StreakLimit)
		{
			Juggernaut = KillerTC;
			TCPRI(KillerTC.PlayerReplicationInfo).bJuggernaut = True;
			KillerTC.GetPerk("OpenDX.Juggernaut");
			Settings.Print("|P2"$KillerTC.PlayerReplicationInfo.PlayerName$" became the juggernaut!");
		}
	}
}

defaultproperties
{
	GTName="Juggernaut DM"
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) - |P2(Get a high streak to become the juggernaut!)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) - |P2(Get a high streak to become the juggernaut!)"
		//bDisableDefaultScoring=True
}
