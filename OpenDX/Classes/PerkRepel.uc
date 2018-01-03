class PerkRepel extends Perks;

var int velz, CheckRadius;

function PerkTick()
{	
	if(PerkOwner.HealthLegLeft <= 0)
	{
		Skullshot();
		PerkOwner.ClientMessage("|P3Repulsion activated!");
		PerkSleep(30);
	}
}

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
	local TCPlayer Player;
	Player = PerkOwner;
	SpawnExplosion(PerkOwner.Location);
	loc = Player.Location;
	loc.Z -= 32;
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

defaultproperties
{
	CheckRadius=256
	PerkName="Repulsion"
	PerkShortName="Repel"
}
