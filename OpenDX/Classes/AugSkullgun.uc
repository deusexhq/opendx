//=============================================================================
// AugFlight
// CONCEPT AUG
// Trace to crosshair, if target is found (Deco or Pawn), do damage, then de-activate
//=============================================================================
class AugSkullgun extends Augmentation;

#exec TEXTURE IMPORT NAME="AugIconSkull_Small" FILE="Textures\AugIconSkull_Small.pcx" GROUP=Icons FLAGS=2
#exec TEXTURE IMPORT NAME="AugIconSkull" FILE="Textures\AugIconSkull.pcx" GROUP=Icons FLAGS=2

var int BioDrainODX;

function Skullshot()
{
	local Actor hitActor;
	local vector loc, line, HitLocation, hitNormal;
	local ScriptedPawn     hitPawn;
	local PlayerPawn       hitPlayer;
	local DeusExMover      hitMover;
	local DeusExDecoration hitDecoration;
	local DeusExProjectile hitProjectile;
	local bool             bTakeDamage;
	local int              damage;
	local vector v2;
	
	Player.Energy -= BioDrainODX;
	
	v2 = Player.location;
	v2.z += 20;
	Spawn(class'Tracer',Player,,v2,Player.ViewRotation);
	
	Player.PlaySound(sound'RifleFire');
	
	loc = Player.Location;
	loc.Z += Player.BaseEyeHeight;
	line = Vector(Player.ViewRotation) * 4000;
	HitActor = Trace(hitLocation, hitNormal, loc+line, loc, true);
			if (hitActor != None)
			{
				hitMover = DeusExMover(hitActor);
				hitPawn = ScriptedPawn(hitActor);
				hitDecoration = DeusExDecoration(hitActor);
				hitPlayer = PlayerPawn(hitActor);
				if (hitMover != None)
				{
					damage=50;
					bTakeDamage = true;
				}
				else if (hitPawn != None)
				{
					damage=50;
					bTakeDamage = true;
				}
				else if (hitDecoration != None)
				{
					damage = 50;
					bTakeDamage = true;
				}
				else if (hitPlayer != None)
				{
					damage = 50;
					bTakeDamage = true;
				}
				else if (hitActor != Level)
				{
					damage = 50;
					bTakeDamage = true;
				}
			}

			if (bTakeDamage)
				hitActor.TakeDamage(damage, Player, hitLocation, line, 'Shot'); 	
}

state Active
{
Begin:
	if(Player.Energy >= BioDrainODX)
		Skullshot();
	
	Deactivate();
//Loop:
	//Sleep(0.1);
//Player

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
		//LevelValues[3] = mpAugValue;
		//EnergyRate = mpEnergyDrain;
	}
}

defaultproperties
{
	BioDrainODX=10
	//mpAugValue=0.000000
	//mpEnergyDrain=0.000000
	EnergyRate=0.000000
	Icon=Texture'AugIconSkull'
	smallIcon=Texture'AugIconSkull_Small'
	AugmentationName="Skullgun"
	Description=""
	MPInfo="When active, the aug fires a shot from your eye..."
	LevelValues(0)=5.000000
	LevelValues(1)=15.000000
	LevelValues(2)=25.000000
	LevelValues(3)=40.000000
	AugmentationLocation=LOC_Eye
	MPConflictSlot=4
	DeActivateSound=none
}

