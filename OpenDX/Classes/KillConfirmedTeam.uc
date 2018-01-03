//=============================================================================
// yee
//=============================================================================
class KillConfirmedTeam expands TCTeam;

function Killed( pawn Killer, pawn Other, name damageType )
{
	local KCObj KC;
	local TCPlayer KillerTC, VictimTC;
	
	KillerTC = TCPlayer(Killer);
	VictimTC = TCPlayer(Other);
	Super.Killed(Killer,Other,damageType);
	
	if((KillerTC != VictimTC) && (KillerTC != None && VictimTC != None)) //Making sure it isn't suicide and both players do actually exist.
	{
		KillerTC.PlayerReplicationInfo.Streak += 1;
		KC = Spawn(class'KCObj', VictimTC,, VictimTC.Location);
		KC.KilledPlayer = VictimTC;
		KC.KillerPlayer = KillerTC;
		KC.SetTimer(0.5,True);
		KC.tLifespan = Settings.KCLifespan;
		KC.scoreMultiplier = Settings.BaseScoreMultiplier;
	}
}

defaultproperties
{
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) - |P2(Grab the skulls of your victims to score!)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) - |P2(Grab the skulls of your victims to score!)"
	GTName="Kill Confirmed Team"
	bDisableDefaultScoring=True
}
