//=============================================================================
// AugHealing.
//=============================================================================
class AugNuke extends Augmentation;

#exec TEXTURE IMPORT NAME="AugIconNuke_Small" FILE="Textures\AugIconNuke_Small.pcx" GROUP=Icons FLAGS=2
#exec TEXTURE IMPORT NAME="AugIconNuke" FILE="Textures\AugIconNuke.pcx" GROUP=Icons FLAGS=2

var float mpAugValue;
var float mpEnergyDrain;

state Active
{
Begin:
Loop:
	Sleep(1.0);

	Goto('Loop');
}

function Deactivate()
{
	Super.Deactivate();
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
	mpAugValue=5
	mpEnergyDrain=5
	EnergyRate=5
	Icon=Texture'AugIconNuke'
	smallIcon=Texture'AugIconNuke_Small'
	AugmentationName="Nuke"
	Description="Programmable polymerase automatically directs construction of proteins in injured cells, restoring an agent to full health over time.|n|nTECH ONE: Healing occurs at a normal rate.|n|nTECH TWO: Healing occurs at a slightly faster rate.|n|nTECH THREE: Healing occurs at a moderately faster rate.|n|nTECH FOUR: Healing occurs at a significantly faster rate."
	MPInfo="When active, you heal, but at a rate insufficient for healing in combat.  Energy Drain: High"
	LevelValues(0)=5.000000
	LevelValues(1)=5
	LevelValues(2)=5
	LevelValues(3)=5
	AugmentationLocation=LOC_Torso
	MPConflictSlot=4
}

