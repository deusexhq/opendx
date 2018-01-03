//=============================================================================
//  
//=============================================================================
class AugFlight extends Augmentation;

var float mpAugValue;
var float mpEnergyDrain;

state Active
{
Begin:
Loop:
	Sleep(1.0);

	Player.DoJump();
	Player.SetPhysics(PHYS_Flying);
	//Player.bFlightAug=True;
	Goto('Loop');
}

function Deactivate()
{
	Player.SetPhysics(PHYS_Falling);
	//Player.bFlightAug=False;
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
	mpAugValue=10.000000
	mpEnergyDrain=100.000000
	EnergyRate=120.000000
	Icon=Texture'DeusExUI.UserInterface.AugIconDrone'
	smallIcon=Texture'DeusExUI.UserInterface.AugIconDrone_Small'
	AugmentationName="Flight"
	Description=""
	MPInfo="When active, you fly."
	LevelValues(0)=5.000000
	LevelValues(1)=15.000000
	LevelValues(2)=25.000000
	LevelValues(3)=40.000000
	AugmentationLocation=LOC_Torso
	MPConflictSlot=2
}

