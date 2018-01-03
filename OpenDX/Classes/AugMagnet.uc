//=============================================================================
//Magnetize
//=============================================================================
class AugMagnet extends Augmentation;

var int BioDrainODX;
var actor Magnet;

function SpawnExplosion(vector Loc)
{
local ShockRing s1, s2, s3;

    s1 = spawn(class'ShockRing',,,Loc,rot(16384,0,0));
	s1.Lifespan = 2.5;
    s2 = spawn(class'ShockRing',,,Loc,rot(0,16384,0));
	s2.Lifespan = 2.5;
    s3 = spawn(class'ShockRing',,,Loc,rot(0,0,16384));
	S3.Lifespan = 2.5;
}

function Skullshot()
{
	local Actor hitActor;
	local vector loc, line, HitLocation, hitNormal;
	local ScriptedPawn     hitPawn;
	local PlayerPawn       hitPlayer;
	local DeusExMover      hitMover;
	local DeusExDecoration hitDecoration;
	local int              damage;
	local vector v2;
	
	v2 = Player.location;
	v2.z += 20;
	
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
			Magnet = hitMover;
		}
		else if (hitPawn != None)
		{
			Magnet = hitPawn;
		}
		else if (hitDecoration != None)
		{
			Magnet = hitDecoration;
		}
		else if (hitPlayer != None)
		{
			Magnet = hitPlayer;
		}
	}
	
	if(Magnet == None)
	{
		loc = Player.Location;
		loc.Z -= 32;
		
		SpawnExplosion(Loc);
		SpawnExplosion(HitLocation);
		Player.DoJump();
		Player.Velocity = (normal(Loc - HitLocation) * -1450);
		Player.SetPhysics(Phys_Falling);
		Deactivate();
	}
	else
		SpawnExplosion(Magnet.Location);
}

function Pull()
{
	local vector loc;
	loc = Player.Location;
	loc.Z -= 32;
	
	Player.DoJump();
	Player.Velocity = (normal(Loc - Magnet.Location) * -750);
	Player.SetPhysics(Phys_Falling);
}

state Active
{
Begin:
	Skullshot();
	
Loop:
	Sleep(0.1);
	Pull();
	if(Magnet != None)
		Goto('Loop');
	else
		Deactivate();
}

function Deactivate()
{
	Magnet = None;
	Super.Deactivate();
}

defaultproperties
{
	BioDrainODX=10
	//mpAugValue=0.000000
	//mpEnergyDrain=0.000000
	EnergyRate=0.000000
	Icon=Texture'DeusExUI.UserInterface.AugIconEMP'
	smallIcon=Texture'DeusExUI.UserInterface.AugIconEMP_Small'
	AugmentationName="Magnetize"
	Description=""
	MPInfo="When active, it.. magnets. idk"
	LevelValues(0)=5.000000
	LevelValues(1)=15.000000
	LevelValues(2)=25.000000
	LevelValues(3)=40.000000
    AugmentationLocation=5
    MPConflictSlot=9
	DeActivateSound=none
}

