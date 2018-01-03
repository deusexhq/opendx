//=============================================================================
//  CONCEPT: When Velocity.Z > 600/700
//=============================================================================
class AugIcarus extends Augmentation;

var float mpAugValue;
var float mpEnergyDrain;
var bool bReverse;
var bool bTrig;

state Active
{
Begin:
	if(Player.Energy <= 1)
		Deactivate();
Loop:
	Sleep(0.1); //Was 1.0, now 0.1
	if(Player.Energy > 1)
	{
		Icarus();
	}
	Goto('Loop');
}

function Icarus()
{	
	if(Player.Velocity.Z < -600 && !bReverse)
	{
		bTrig=True;
		bReverse=True;
		Player.ClientMessage("|P3Icarus landing system activated...");
	}
	
	if(bTrig)
	{
		Player.Energy -= 1;
		if(bReverse)
			Player.Velocity.Z += 100;
		
		if(Player.Velocity.Z > 0)
		{
			bTrig=False;
			bReverse=False;
			Player.ClientMessage("|P3Icarus landing system de-activated...");
		}
	}
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
	mpAugValue=0
	mpEnergyDrain=0
	EnergyRate=0
	Icon=Texture'DeusExUI.UserInterface.AugIconDrone'
	smallIcon=Texture'DeusExUI.UserInterface.AugIconDrone_Small'
	AugmentationName="Icarus Landing System"
	Description=""
	MPInfo="When active, you emit dangerous energy while falling at high velocity."
	LevelValues(0)=0
	LevelValues(1)=0
	LevelValues(2)=0
	LevelValues(3)=0
	LoopSound=None
	AugmentationLocation=4
	MPConflictSlot=3
}

