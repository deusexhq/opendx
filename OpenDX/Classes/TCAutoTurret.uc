//=============================================================================
// AutoTurret.
//=============================================================================
class TCAutoTurret extends AutoTurret;

var bool bDisb;
var() int TurretHealth;
var string TeamString;
var AutoTurretGun gun;

var() localized String titleString;		// So we can name specific turrets in multiplayer
var() bool bTrackPawnsOnly;
var() bool bTrackPlayersOnly;
var() bool bActive;
var() int maxRange;
var() float fireRate;
var() float gunAccuracy;
var() int gunDamage;
var() int ammoAmount;
var Actor curTarget;
var Actor prevTarget;         // target we had last tick.
var Pawn safeTarget;          // in multiplayer, this actor is strictly off-limits
                               // Usually for the player who activated the turret.
var float fireTimer;
var bool bConfused;				// used when hit by EMP
var float confusionTimer;		// how long until turret resumes normal operation
var float confusionDuration;	// how long does an EMP hit last?
var Actor LastTarget;			// what was our last target?
var float pitchLimit;			// what's the maximum pitch?
var Rotator origRot;			// original rotation
var bool bPreAlarmActiveState;	// was I previously awake or not?
var bool bDisabled;				// have I been hacked or shut down by computers?
var float TargetRefreshTime;      // used for multiplayer to reduce rate of checking for targets.
var() float Thick;
var() float PawnThick;
var() int team;						// Keep track of team the turrets on

var int mpTurretDamage;			// Settings for multiplayer
var int mpTurretRange;

var bool bComputerReset;			// Keep track of if computer has been reset so we avoid all actors checks

var bool bSwitching;
var float SwitchTime, beepTime;
var Pawn savedTarget;


// networking replication
replication
{
   //server to client
   reliable if (Role == ROLE_Authority)
      safeTarget, bDisabled, bActive, team, titleString;
}

function Destroyed()
{		
}

function UpdateSwitch()
{
	if ( Level.Timeseconds > SwitchTime )
	{
		bSwitching = False;
		//safeTarget = savedTarget;
		SwitchTime = 0;
		beepTime = 0;
	}
	else
	{
		if ( Level.Timeseconds > beepTime )
		{
			PlaySound(Sound'TurretSwitch', SLOT_Interact, 1.0,, maxRange );
			beepTime = Level.Timeseconds + 0.75;
		}
	}
}

function Actor AcquireMultiplayerTarget()
{
	local Pawn apawn;
	local DeusExPlayer aplayer;
	local Vector dist;
	local Actor noActor;

	if ( bSwitching )
	{
		noActor = None;
		return noActor;
	}

	apawn = gun.Level.PawnList;

	while ( apawn != None )
	{
		//if (apawn.bDetectable && !apawn.bIgnore && apawn.IsA('DeusExPlayer'))
		if (apawn.bDetectable && !apawn.bIgnore)
		{
			aplayer = DeusExPlayer(apawn);

			dist = apawn.Location - gun.Location; //apawn was aplayer

			if ( VSize(dist) < maxRange )
			{
				// Only players we can see
				if ( apawn.FastTrace( apawn.Location, gun.Location ))//apawn was aplayer
				{
					if(!PSOwners(apawn))
					{
						if(curTarget == None)
						{
								
							curTarget = apawn;
								break;
						}
					}
				}
			}
		}
		apawn = apawn.nextPawn;
	}
	return curtarget;
}

function Tick(float deltaTime)
{
	local Pawn pawn;
	local ScriptedPawn sp;
	local DeusExDecoration deco;
	local float near;
	local Rotator destRot;
	local bool bSwitched;

	Super.Tick(deltaTime);

	bSwitched = False;

	if ( bSwitching )
	{
		UpdateSwitch();
		return;
	}

	if (bActive && !bDisabled)
	{
		curTarget = None;

		if ( !bConfused )
		{
			if (TargetRefreshTime < 0)
			TargetRefreshTime = 0;
         
			TargetRefreshTime = TargetRefreshTime + deltaTime;

			if (TargetRefreshTime >= 0.3)
			{
				TargetRefreshTime = 0;
				curTarget = AcquireMultiplayerTarget();

//				if ( curTarget == None )
//				PlaySound(Sound'TurretUnlocked', SLOT_Interact, 1.0,, maxRange );
//				prevtarget = curtarget;		
			}

					foreach gun.VisibleActors(class'Pawn', pawn, maxRange, gun.Location)
					{
						if (pawn.bDetectable && !pawn.bIgnore)
						{
									if(curTarget == None)
									{
										if(!PSOwners(Pawn))
										{
											curTarget = Pawn;
											break;
										}
									}
						}
					}
			}

			// if we have a target, rotate to face it
			if (curTarget != None)
			{
				destRot = Rotator(curTarget.Location - gun.Location);
				gun.DesiredRotation = destRot;
				near = pitchLimit / 2;
				gun.DesiredRotation.Pitch = FClamp(gun.DesiredRotation.Pitch, origRot.Pitch - near, origRot.Pitch + near);
			}
			else
				gun.DesiredRotation = origRot;
	}
	else
	{
		if ( !bConfused )
			gun.DesiredRotation = origRot;
	}

	near = (Abs(gun.Rotation.Pitch - gun.DesiredRotation.Pitch)) % 65536;
	near += (Abs(gun.Rotation.Yaw - gun.DesiredRotation.Yaw)) % 65536;

	if (bActive && !bDisabled)
	{
		// play an alert sound and light up
		if ((curTarget != None) && (curTarget != LastTarget))
			PlaySound(Sound'Beep6',,,, 1280);

		// if we're aiming close enough to our target
		if (curTarget != None)
		{
			gun.MultiSkins[1] = Texture'RedLightTex';
			if ((near < 4096) && (((Abs(gun.Rotation.Pitch - destRot.Pitch)) % 65536) < 8192))
			{
				if (fireTimer > fireRate)
				{
					Fire();
					fireTimer = 0;
				}
			}
		}
		else
		{
			if (gun.IsAnimating())
				gun.PlayAnim('Still', 10.0, 0.001);

			if (bConfused)
				gun.MultiSkins[1] = Texture'YellowLightTex';
			else
				gun.MultiSkins[1] = Texture'GreenLightTex';
		}

		fireTimer += deltaTime;
		LastTarget = curTarget;
	}
	else
	{
		if (gun.IsAnimating())
			gun.PlayAnim('Still', 10.0, 0.001);
		gun.MultiSkins[1] = None;
	}

	// make noise if we're still moving
	if (near > 64)
	{
		gun.AmbientSound = Sound'AutoTurretMove';
		if (bConfused)
			gun.SoundPitch = 128;
		else
			gun.SoundPitch = 64;
	}
	else
		gun.AmbientSound = None;
}

function bool PSOwners(Pawn P)
{
	if(DeusExPlayer(P) != None)
	{
		if(P == safeTarget || P == Owner)
			return True;
		
		if(TCDeathmatch(level.game) != None)
			if(TCPRI(TCPlayer(Owner).PlayerReplicationInfo).TeamNamePRI != "" && TCPRI(TCPlayer(P).PlayerReplicationInfo).TeamNamePRI != "")
				if(TCPRI(TCPlayer(Owner).PlayerReplicationInfo).TeamNamePRI == TCPRI(TCPlayer(P).PlayerReplicationInfo).TeamNamePRI)
					return true;
		
		if(TCDeathmatch(level.game) != None)
			if(TeamString != "" && TCPRI(TCPlayer(P).PlayerReplicationInfo).TeamNamePRI != "")
				if(TeamString == TCPRI(TCPlayer(P).PlayerReplicationInfo).TeamNamePRI)
					return true;
					
		if(TCTeam(level.game) != None && TCPlayer(P).PlayerReplicationInfo.Team == TCPlayer(safeTarget).PlayerReplicationInfo.Team)
			return true;
	}
		
	return False;
}

auto state Active
{
	function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
	{
		local Human dxp;
		local float mindmg;

		if (DamageType == 'EMP')
		{
			return; //Nulled function, IMMUNE TO EMP.
		}

		TurretHealth -= Damage; //Edited this in to avoid some things.

		if(bDisb == False)
		{
			if(TurretHealth <= 0)
			{
				return;
			}
		}
	}
}

function Fire()
{
	local Vector HitLocation, HitNormal, StartTrace, EndTrace, X, Y, Z;
	local Rotator rot;
	local Actor hit;
	local ShellCasing shell;
	local Spark spark;
	local Pawn attacker;

	if (!gun.IsAnimating())
		gun.LoopAnim('Fire');

	// CNN - give turrets infinite ammo
//	if (ammoAmount > 0)
//	{
//		ammoAmount--;
		GetAxes(gun.Rotation, X, Y, Z);
		StartTrace = gun.Location;
		EndTrace = StartTrace + gunAccuracy * (FRand()-0.5)*Y*1000 + gunAccuracy * (FRand()-0.5)*Z*1000 ;
		EndTrace += 10000 * X;
		hit = Trace(HitLocation, HitNormal, EndTrace, StartTrace, True);

		// spawn some effects
      if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      {
         shell = None;
      }
      else
      {
         shell = Spawn(class'ShellCasing',,, gun.Location);
      }
		if (shell != None)
			shell.Velocity = Vector(gun.Rotation - rot(0,16384,0)) * 100 + VRand() * 30;

		MakeNoise(1.0);
		PlaySound(sound'PistolFire', SLOT_None);
		AISendEvent('LoudNoise', EAITYPE_Audio);

		// muzzle flash
		gun.LightType = LT_Steady;
		gun.MultiSkins[2] = Texture'FlatFXTex34';
		SetTimer(0.1, False);

		// randomly draw a tracer
		if (FRand() < 0.5)
		{
			if (VSize(HitLocation - StartTrace) > 250)
			{
				rot = Rotator(EndTrace - StartTrace);
				Spawn(class'Tracer',,, StartTrace + 96 * Vector(rot), rot);
			}
		}

		if (hit != None)
		{
         if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
         {
            spark = None;
         }
         else
         {
            // spawn a little spark and make a ricochet sound if we hit something
            spark = spawn(class'Spark',,,HitLocation+HitNormal, Rotator(HitNormal));
         }

			if (spark != None)
			{
				spark.DrawScale = 0.05;
				PlayHitSound(spark, hit);
			}

			attacker = None;
			if ((curTarget == hit) && !curTarget.IsA('PlayerPawn'))
				attacker = GetPlayerPawn();
         if (Level.NetMode != NM_Standalone)
            attacker = safetarget;
			if ( hit.IsA('DeusExPlayer') && ( Level.NetMode != NM_Standalone ))
				DeusExPlayer(hit).myTurretKiller = Self;
			hit.TakeDamage(gunDamage, attacker, HitLocation, 1000.0*X, 'AutoShot');

			if (hit.IsA('Pawn') && !hit.IsA('Robot'))
				SpawnBlood(HitLocation, HitNormal);
			else if ((hit == Level) || hit.IsA('Mover'))
				SpawnEffects(HitLocation, HitNormal, hit);
		}
//	}
//	else
//	{
//		PlaySound(sound'DryFire', SLOT_None);
//	}
}

function SpawnBlood(Vector HitLocation, Vector HitNormal)
{
	local rotator rot;

	rot = Rotator(Location - HitLocation);
	rot.Pitch = 0;
	rot.Roll = 0;

   if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      return;

	spawn(class'BloodSpurt',,,HitLocation+HitNormal, rot);
	spawn(class'BloodDrop',,,HitLocation+HitNormal);
	if (FRand() < 0.5)
		spawn(class'BloodDrop',,,HitLocation+HitNormal);
}

simulated function SpawnEffects(Vector HitLocation, Vector HitNormal, Actor Other)
{
	local SmokeTrail puff;
	local int i;
	local BulletHole hole;
	local Rotator rot;

   if ((DeusExMPGame(Level.Game) != None) && (!DeusExMPGame(Level.Game).bSpawnEffects))
      return;

   if (FRand() < 0.5)
	{
		puff = spawn(class'SmokeTrail',,,HitLocation+HitNormal, Rotator(HitNormal));
		if (puff != None)
		{
			puff.DrawScale *= 0.3;
			puff.OrigScale = puff.DrawScale;
			puff.LifeSpan = 0.25;
			puff.OrigLifeSpan = puff.LifeSpan;
		}
	}

	if (!Other.IsA('BreakableGlass'))
		for (i=0; i<2; i++)
			if (FRand() < 0.8)
				spawn(class'Rockchip',,,HitLocation+HitNormal);

	hole = spawn(class'BulletHole', Other,, HitLocation, Rotator(HitNormal));

	// should we crack glass?
	if (GetWallMaterial(HitLocation, HitNormal) == 'Glass')
	{
		if (FRand() < 0.5)
			hole.Texture = Texture'FlatFXTex29';
		else
			hole.Texture = Texture'FlatFXTex30';

		hole.DrawScale = 0.1;
		hole.ReattachDecal();
	}
}

function name GetWallMaterial(vector HitLocation, vector HitNormal)
{
	local vector EndTrace, StartTrace;
	local actor newtarget;
	local int texFlags;
	local name texName, texGroup;

	StartTrace = HitLocation + HitNormal*16;		// make sure we start far enough out
	EndTrace = HitLocation - HitNormal;

	foreach TraceTexture(class'Actor', newtarget, texName, texGroup, texFlags, StartTrace, HitNormal, EndTrace)
		if ((newtarget == Level) || newtarget.IsA('Mover'))
			break;

	return texGroup;
}

function PlayHitSound(actor destActor, Actor hitActor)
{
	local float rnd;
	local sound snd;

	rnd = FRand();

	if (rnd < 0.25)
		snd = sound'Ricochet1';
	else if (rnd < 0.5)
		snd = sound'Ricochet2';
	else if (rnd < 0.75)
		snd = sound'Ricochet3';
	else
		snd = sound'Ricochet4';

	// play a different ricochet sound if the object isn't damaged by normal bullets
	if (hitActor != None) 
	{
		if (hitActor.IsA('DeusExDecoration') && (DeusExDecoration(hitActor).minDamageThreshold > 10))
			snd = sound'ArmorRicochet';
		else if (hitActor.IsA('Robot'))
			snd = sound'ArmorRicochet';
	}

	if (destActor != None)
		destActor.PlaySound(snd, SLOT_None,,, 1024, 1.1 - 0.2*FRand());
}

// turn off the muzzle flash
simulated function Timer()
{
	gun.LightType = LT_None;
	gun.MultiSkins[2] = None;
}

/*function AlarmHeard(Name event, EAIEventState state, XAIParams params)
{
	if (state == EAISTATE_Begin)
	{
		if (!bActive)
		{
			bPreAlarmActiveState = bActive;
			bActive = True;
		}
	}
	else if (state == EAISTATE_End)
	{
		if (bActive)
			bActive = bPreAlarmActiveState;
	}
}*/

function PreBeginPlay()
{
	local Vector v1, v2;
	local class<AutoTurretGun> gunClass;
	local Rotator rot;

	Super.PreBeginPlay();

	if (IsA('AutoTurretSmall'))
		gunClass = class'AutoTurretGunSmall';
	else
		gunClass = class'AutoTurretGun';

	rot = Rotation;
	rot.Pitch = 0;
	rot.Roll = 0;
	origRot = rot;
	gun = Spawn(gunClass, Self,, Location, rot);
	if (gun != None)
	{
		v1.X = 0;
		v1.Y = 0;
		v1.Z = CollisionHeight + gun.Default.CollisionHeight;
		v2 = v1 >> Rotation;
		v2 += Location;
		gun.bHackable=False;
		gun.SetLocation(v2);
		gun.SetBase(Self);
	}

	// set up the alarm listeners
	//AISetEventCallback('Alarm', 'AlarmHeard');

	maxRange = mpTurretRange;
	gunDamage = mpTurretDamage;
	bDisabled = !bActive;
}

function PostBeginPlay()
{
   safeTarget = None;
   prevTarget = None;
   TargetRefreshTime = 0;
   Super.PostBeginPlay();
}

defaultproperties
{
    TurretHealth=100
    titleString="AutoTurret"
    bTrackPlayersOnly=True
    bActive=True
    maxRange=512
    fireRate=0.25
    gunAccuracy=0.50
    gunDamage=5
    AmmoAmount=1000
    confusionDuration=120.00
    pitchLimit=11000.00
    Team=500
    mpTurretDamage=20
    mpTurretRange=1024
    HitPoints=100
    minDamageThreshold=100
    bHighlight=False
    ItemName="Turret Base"
    bPushable=False
    Physics=0
    Mesh=LodMesh'DeusExDeco.AutoTurretBase'
    SoundRadius=48
    SoundVolume=192
    AmbientSound=Sound'DeusExSounds.Generic.AutoTurretHum'
    CollisionRadius=14.00
    CollisionHeight=20.20
    Mass=50.00
    Buoyancy=10.00
    bVisionImportant=True
}
