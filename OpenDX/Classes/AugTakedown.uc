//=============================================================================
// AugTakedown
// For.. something
//=============================================================================
class AugTakedown extends Augmentation;

#exec TEXTURE IMPORT NAME="AugIconSkull_Small" FILE="Textures\AugIconSkull_Small.pcx" GROUP=Icons FLAGS=2
#exec TEXTURE IMPORT NAME="AugIconSkull" FILE="Textures\AugIconSkull.pcx" GROUP=Icons FLAGS=2

var float mpAugValue;
var float mpEnergyDrain;

function Skullshot()
{
	local Actor hitActor;
	local vector loc, line, HitLocation, hitNormal;
	local ScriptedPawn     hitPawn;
	local PlayerPawn       hitPlayer;
	local int              damage;
	local vector v2;
	
	Player.Energy -= 25;
	

	Player.PlaySound(sound'RifleFire');
	
	loc = Player.Location;
	loc.Z += Player.BaseEyeHeight;
	line = Vector(Player.ViewRotation) * 100;
	HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
			if (hitActor != None)
			{
				hitPawn = ScriptedPawn(hitActor);
				hitPlayer = PlayerPawn(hitActor);
				if (hitPawn != None)
				{
					Player.ClientMessage("Placeholder: taking down "$hitpawn);
				}
				else if (hitPlayer != None)
				{
					Player.ClientMessage("Placeholder: taking down "$hitplayer.playerreplicationinfo.playername);
				}
			}	
}

state Active
{

Begin:
Loop:
	Sleep(0.1);
//Player
	if(Player.Energy >= 25)
		Skullshot();
	
	Deactivate();
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
	mpAugValue=10.000000
	mpEnergyDrain=0.000000
	EnergyRate=0.000000
	Icon=Texture'AugIconSkull'
	smallIcon=Texture'AugIconSkull_Small'
	AugmentationName="Takedown"
	Description=""
	MPInfo="When active, something something"
	LevelValues(0)=5.000000
	LevelValues(1)=15.000000
	LevelValues(2)=25.000000
	LevelValues(3)=40.000000
	AugmentationLocation=LOC_Arm
	MPConflictSlot=4
}

