//=============================================================================
// AugHealing.
//=============================================================================
class AugHealing2 extends AugHealing;

var float mpAugValue;
var float mpEnergyDrain;

state Active
{
Begin:
	if(Player.Energy < 5)
		Deactivate();
Loop:
	Sleep(1.0);

	if (Player.Health < 100 && Player.Health > 0)
	{
		LoopSound=Sound'DeusExSounds.Augmentation.AugLoop';
		Player.Energy -= 5;
		if((TCPRI(player.PlayerReplicationInfo) != None) && (Juggernaut(Player.Level.Game) != None) && TCPRI(Player.PlayerReplicationInfo).bJuggernaut)
			Player.HealPlayer(5, False);
		else
			Player.HealPlayer(15, False);
			
		Player.ClientFlash(0.5, vect(0, 0, 500));
	}
	else LoopSound=none;
	Goto('Loop');
}

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// If this is a netgame, then override defaults
	if ( Level.NetMode != NM_StandAlone )
	{
		LevelValues[3] = mpAugValue;
		EnergyRate = mpEnergyDrain;
	}
}

defaultproperties
{
	mpAugValue=0
	mpEnergyDrain=0
	EnergyRate=0
	Icon=Texture'DeusExUI.UserInterface.AugIconHealing'
	smallIcon=Texture'DeusExUI.UserInterface.AugIconHealing_Small'
	AugmentationName="Nano Regeneration"
	Description="Programmable polymerase automatically directs construction of proteins in injured cells, restoring an agent to full health over time.|n|nTECH ONE: Healing occurs at a normal rate.|n|nTECH TWO: Healing occurs at a slightly faster rate.|n|nTECH THREE: Healing occurs at a moderately faster rate.|n|nTECH FOUR: Healing occurs at a significantly faster rate."
	MPInfo="When active, you heal, but at a rate insufficient for healing in combat.  Energy Drain: High"
	LevelValues(0)=0
	LevelValues(1)=0
	LevelValues(2)=0
	LevelValues(3)=0
	LoopSound=None
	AugmentationLocation=LOC_Torso
	MPConflictSlot=2
}

