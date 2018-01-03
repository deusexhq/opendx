class PerkJuggernaut extends Perks;
//Icarus + Repel + Nuke
var bool bReverse, bTrig;
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
	local TCPlayer Player;
	Player = PerkOwner;
	
	SpawnExplosion(Player.Location);
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

function PerkOn()
{
	PerkOwner.bNuke=True;
}

function PerkOff()
{
	PerkOwner.bNuke=False;
}

function PerkTick()
{
	if(PerkOwner.HealthLegLeft <= 0)
	{
		Skullshot();
		BroadcastMessage("The Juggernaut is crippled!");
		PerkSleep(30);
	}
	
	if(PerkOwner.Velocity.Z < -600 && !bReverse)
	{
		bTrig=True;
		bReverse=True;
		PerkOwner.ClientMessage("|P3Juggernaut landing system activated...");
	}
	
	if(bTrig)
	{
		if(bReverse)
			PerkOwner.Velocity.Z += 100;
		
		if(PerkOwner.Velocity.Z > 0)
		{
			bTrig=False;
			bReverse=False;
			PerkOwner.ClientMessage("|P3Juggernaut landing system de-activated...");
		}
	}
}

defaultproperties
{
	CheckRadius=256
	PerkName="Juggernaut"
	bLock=True
}
