//=============================================================================
// AugRepel
// Concept : Requires > 10, any higher than that increases the range or power, then drains
//=============================================================================
class AugRepel extends Augmentation;

var int velz, CheckRadius;

function SpawnExplosion(vector Loc)
{
local ShockRing s1, s2, s3;
local SphereEffect se;

    s1 = spawn(class'ShockRing',,,Loc,rot(16384,0,0));
	s1.Lifespan = 5.5;
    s2 = spawn(class'ShockRing',,,Loc,rot(0,16384,0));
	s2.Lifespan = 5.5;
    s3 = spawn(class'ShockRing',,,Loc,rot(0,0,16384));
	S3.Lifespan = 5.5;
	se = spawn(class'SphereEffect',,,Loc,rot(16384,0,0));
	se.Lifespan = 5.5;
	se.MultiSkins[0]=Texture'DeusExDeco.Skins.AlarmLightTex7';
}

function Skullshot()
{
	local vector loc, vline, HitLocation, hitNormal, altloc;
	local rotator altrot;
	local Actor HitActor;
	local actor a;
	local ScriptedPawn     hitPawn;
	local PlayerPawn       hitPlayer;
	local DeusExMover      hitMover;
	local DeusExDecoration hitDecoration;
	
	loc = Player.Location;
	loc.Z -= 32;
	Player.Energy -= 10;
	SpawnExplosion(Loc);
	foreach Player.VisibleActors(class'Actor', A, CheckRadius)
	{
		if (a != None && a != Player)
		{
			hitPawn = ScriptedPawn(a);
			hitDecoration = DeusExDecoration(a);
			hitPlayer = PlayerPawn(a);
			hitMover = DeusExMover(a);
			if (hitPawn != None)
			{
				hitPawn.SetPhysics(Phys_Falling);
				hitPawn.Velocity = (normal(loc - hitPawn.Location) * velz);
				//hitPawn.TakeDamage(Player.Energy, Player, hitLocation, normal(loc - hitPawn.Location) * velz, 'Exploded'); 	
			}
			else if (hitDecoration != None)
			{
				hitDecoration.SetPhysics(Phys_Falling);
				hitDecoration.Velocity = (normal(loc - hitDecoration.Location) * velz);	
				//hitDecoration.TakeDamage(Player.Energy, Player, hitLocation, normal(loc - hitDecoration.Location) * velz, 'Exploded'); 	
			}
			else if (hitPlayer != None)
			{
				hitPlayer.SetPhysics(Phys_Falling);
				hitPlayer.Velocity = (normal(loc - hitPlayer.Location) * velz);
				//hitPlayer.TakeDamage(Player.Energy / 3, Player, hitLocation, normal(loc - hitPlayer.Location) * velz, 'Exploded'); 	
			}
			if (hitMover != None)
			{
					hitMover.bDrawExplosion = True;
				//	hitMover.TakeDamage(Player.Energy * 3, Player, hitLocation,normal(loc - hitMover.Location) * velz, 'Exploded'); 
			}
		}		
	}
}

state Active
{
Begin:
	if(Player.Energy >= 10)
		Skullshot();
	
	Deactivate();
}

function Deactivate()
{
	Super.Deactivate();
}

defaultproperties
{
	CheckRadius=256
	velz=-750
	EnergyRate=0.000000
	Icon=Texture'DeusExUI.UserInterface.AugIconEMP'
	smallIcon=Texture'DeusExUI.UserInterface.AugIconEMP_Small'
	AugmentationName="Blast Shield"
	Description=""
	MPInfo="When active, the aug repels all objects around you"
	LevelValues(0)=5.000000
	LevelValues(1)=15.000000
	LevelValues(2)=25.000000
	LevelValues(3)=40.000000
    AugmentationLocation=5
    MPConflictSlot=9
}

