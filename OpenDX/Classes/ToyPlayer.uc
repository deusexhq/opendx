//=============================================================================
// SSPlayer
//=============================================================================
class ToyPlayer expands TCPlayer;

function bool SetBasedPawnSize(float newRadius, float newHeight)
{
	local float  oldRadius, oldHeight;
	local bool   bSuccess;
	local vector centerDelta, lookDir, upDir;
	local float  deltaEyeHeight;
	local Decoration savedDeco;

	if (newRadius < 0)
		newRadius = 0;
	if (newHeight < 0)
		newHeight = 0;

	oldRadius = CollisionRadius;
	oldHeight = CollisionHeight;

	if ( Level.NetMode == NM_Standalone )
	{
		if ((oldRadius == newRadius) && (oldHeight == newHeight))
			return true;
	}

	centerDelta    = vect(0, 0, 1)*(newHeight-oldHeight);
	deltaEyeHeight = GetDefaultCollisionHeight() - Default.BaseEyeHeight;

	if ( Level.NetMode != NM_Standalone )
	{
		if ((oldRadius == newRadius) && (oldHeight == newHeight) && (BaseEyeHeight == newHeight - deltaEyeHeight))
			return true;
	}

	if (CarriedDecoration != None)
		savedDeco = CarriedDecoration;

	bSuccess = false;
	if ((newHeight <= CollisionHeight) && (newRadius <= CollisionRadius))  // shrink
	{
		SetCollisionSize(newRadius, newHeight);
		if (Move(centerDelta))
			bSuccess = true;
		else
			SetCollisionSize(oldRadius, oldHeight);
	}
	else
	{
		if (Move(centerDelta))
		{
			SetCollisionSize(newRadius, newHeight);
			bSuccess = true;
		}
	}

	if (bSuccess)
	{
		// make sure we don't lose our carried decoration
		if (savedDeco != None)
		{
			savedDeco.SetPhysics(PHYS_None);
			savedDeco.SetBase(Self);
			savedDeco.SetCollision(False, False, False);

			// reset the decoration's location
			lookDir = Vector(Rotation);
			lookDir.Z = 0;				
			upDir = vect(0,0,0);
			upDir.Z = CollisionHeight / 2;		// put it up near eye level
			savedDeco.SetLocation(Location + upDir + (0.5 * CollisionRadius + CarriedDecoration.CollisionRadius) * lookDir);
		}

//		PrePivotOffset  = vect(0, 0, 1)*(GetDefaultCollisionHeight()-newHeight);
		PrePivot        -= centerDelta;
//		DesiredPrePivot -= centerDelta;
		BaseEyeHeight   = newHeight - deltaEyeHeight;

		EyeHeight		-= centerDelta.Z;
	}
	return (bSuccess);
}

state PlayerWalking
{
	function ProcessMove ( float DeltaTime, vector newAccel, eDodgeDir DodgeMove, rotator DeltaRot)
	{
		local int newSpeed, defSpeed;
		local name mat;
		local vector HitLocation, HitNormal, checkpoint, downcheck;
		local Actor HitActor, HitActorDown;
		local bool bCantStandUp;
		local Vector loc, traceSize;
		local float alpha, maxLeanDist;
		local float legTotal, weapSkill;
		local vector start, checkNorm, Extent;
		local TCControls TCC;
		
		TCC = GetControls();
		Super.ProcessMove(DeltaTime, newAccel, DodgeMove, DeltaRot);
		//Kaiser: Mantling system.
		if (Physics == PHYS_Falling && velocity.Z != 0 && TCC.bMantling)
		{
			if (CarriedDecoration == None && Energy >= TCC.MantleBio)
			{
				checkpoint = vector(Rotation);
				checkpoint.Z = 0.0;
				checkNorm = Normal(checkpoint);
				checkPoint = Location + CollisionRadius * checkNorm;
				//Extent = CollisionRadius * vect(1,1,0);
				Extent = CollisionRadius * vect(0.2,0.2,0);
				Extent.Z = CollisionHeight;
				HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, True, Extent);
				if ( (HitActor != None) && (Pawn(HitActor) == None) && (HitActor == Level || HitActor.bCollideActors) && !HitActor.IsA('DeusExCarcass'))
				{
					WallNormal = -1 * HitNormal;
					start = Location;
					start.Z += 1.1 * MaxStepHeight + CollisionHeight;
					checkPoint = start + 2 * CollisionRadius * checkNorm;
					HitActor = Trace(HitLocation, HitNormal, checkpoint, start, true, Extent);
					if (HitActor == None)
					{
						if(!isMantling)	
						{
							Energy -= TCC.MantleBio;
							isMantling = True;
							setPhysics(PHYS_Falling);
							Velocity.Z = TCC.MantleVelocity;
							Acceleration = vect(0,0,0);
							PlaySound(sound'MaleLand', SLOT_None, 1.5, true, 1200, (1.0 + 0.2*FRand()) * 1.0 );
							Acceleration = wallNormal * AccelRate / 8;
						}
					}
				}
			}
		}
		// if the spy drone augmentation is active
		if (bSpyDroneActive)
		{
			if ( aDrone != None ) 
			{
				// put away whatever is in our hand
				if (inHand != None)
					PutInHand(None);

				// make the drone's rotation match the player's view
				aDrone.SetRotation(ViewRotation);

				// move the drone
				loc = Normal((aUp * vect(0,0,1) + aForward * vect(1,0,0) + aStrafe * vect(0,1,0)) >> ViewRotation);

				// opportunity for client to translate movement to server
				MoveDrone( DeltaTime, loc );

				// freeze the player
				Velocity = vect(0,0,0);
			}
			return;
		}

		defSpeed = GetCurrentGroundSpeed();

      // crouching makes you two feet tall
		if (bIsCrouching || bForceDuck)
		{
			SetBasedPawnSize(Default.CollisionRadius, Default.CollisionHeight);

			// check to see if we could stand up if we wanted to
			checkpoint = Location;
			// check normal standing height
			checkpoint.Z = checkpoint.Z - CollisionHeight + 2 * GetDefaultCollisionHeight();
			traceSize.X = CollisionRadius;
			traceSize.Y = CollisionRadius;
			traceSize.Z = 1;
			HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, True, traceSize);
			if (HitActor == None)
				bCantStandUp = False;
			else
				bCantStandUp = True;
		}
		else
		{
         // DEUS_EX AMSD Changed this to grab defspeed, because GetCurrentGroundSpeed takes 31k cycles to run.
			GroundSpeed = defSpeed;

			// make sure the collision height is fudged for the floor problem - CNN
			if (!IsLeaning())
			{
				ResetBasedPawnSize();
			}
		}

		if (bCantStandUp)
			bForceDuck = True;
		else
			bForceDuck = False;

		// if the player's legs are damaged, then reduce our speed accordingly
		newSpeed = defSpeed;

		if ( Level.NetMode == NM_Standalone )
		{
			if (HealthLegLeft < 1)
				newSpeed -= (defSpeed/2) * 0.25;
			else if (HealthLegLeft < 34)
				newSpeed -= (defSpeed/2) * 0.15;
			else if (HealthLegLeft < 67)
				newSpeed -= (defSpeed/2) * 0.10;

			if (HealthLegRight < 1)
				newSpeed -= (defSpeed/2) * 0.25;
			else if (HealthLegRight < 34)
				newSpeed -= (defSpeed/2) * 0.15;
			else if (HealthLegRight < 67)
				newSpeed -= (defSpeed/2) * 0.10;

			if (HealthTorso < 67)
				newSpeed -= (defSpeed/2) * 0.05;
		}

		// let the player pull themselves along with their hands even if both of
		// their legs are blown off
		if ((HealthLegLeft < 1) && (HealthLegRight < 1))
		{
			newSpeed = defSpeed * 0.8;
			bIsWalking = True;
			bForceDuck = True;
		}
		// make crouch speed faster than normal
		else if (bIsCrouching || bForceDuck)
		{
//			newSpeed = defSpeed * 1.8;		// DEUS_EX CNN - uncomment to speed up crouch
			bIsWalking = True;
		}

		if (CarriedDecoration != None)
		{
			newSpeed -= CarriedDecoration.Mass * 2;
		}
		// don't slow the player down if he's skilled at the corresponding weapon skill  
		else if ((DeusExWeapon(Weapon) != None) && (Weapon.Mass > 30) && (DeusExWeapon(Weapon).GetWeaponSkill() > -0.25) && (Level.NetMode==NM_Standalone))
		{
			bIsWalking = True;
			newSpeed = defSpeed;
		}
		else if ((inHand != None) && inHand.IsA('POVCorpse'))
		{
			newSpeed -= inHand.Mass * 3;
		}

		// Multiplayer movement adjusters
		if ( Level.NetMode != NM_Standalone )
		{
			if ( Weapon != None )
			{
				weapSkill = DeusExWeapon(Weapon).GetWeaponSkill();
				// Slow down heavy weapons in multiplayer
				if ((DeusExWeapon(Weapon) != None) && (Weapon.Mass > 30) )
				{
					newSpeed = defSpeed;
					newSpeed -= ((( Weapon.Mass - 30.0 ) / (class'WeaponGEPGun'.Default.Mass - 30.0 )) * (0.70 + weapSkill) * defSpeed );
				}
				// Slow turn rate of GEP gun in multiplayer to discourage using it as the most effective close quarters weapon
				if ((WeaponGEPGun(Weapon) != None) && (!WeaponGEPGun(Weapon).bZoomed))
					TurnRateAdjuster = FClamp( 0.20 + -(weapSkill*0.5), 0.25, 1.0 );
				else
					TurnRateAdjuster = 1.0;
			}
			else
				TurnRateAdjuster = 1.0;
		}

		// if we are moving really slow, force us to walking
		if ((newSpeed <= defSpeed / 3) && !bForceDuck)
		{
			bIsWalking = True;
			newSpeed = defSpeed;
		}

		// if we are moving backwards, we should move slower
      // DEUS_EX AMSD Turns out this wasn't working right in multiplayer, I have a fix
      // for it, but it would change all our balance.
		if ((aForward < 0) && (Level.NetMode == NM_Standalone))
			newSpeed *= 0.65;

		GroundSpeed = FMax(newSpeed, 100);

		// if we are moving or crouching, we can't lean
		// uncomment below line to disallow leaning during crouch

			if ((VSize(Velocity) < 10) && (aForward == 0))		// && !bIsCrouching && !bForceDuck)
				bCanLean = True;
			else
				bCanLean = False;

			// check leaning buttons (axis aExtra0 is used for leaning)
			maxLeanDist = 40;

			if (IsLeaning())
			{
				if ( PlayerIsClient() || (Level.NetMode == NM_Standalone) )
					ViewRotation.Roll = curLeanDist * 20;
			
				if (!bIsCrouching && !bForceDuck)
					SetBasedPawnSize(CollisionRadius, GetDefaultCollisionHeight() - Abs(curLeanDist) / 3.0);
			}
			if (bCanLean && (aExtra0 != 0))
			{
				// lean
				DropDecoration();		// drop the decoration that we are carrying
				if (AnimSequence != 'CrouchWalk')
					PlayCrawling();

				alpha = maxLeanDist * aExtra0 * 2.0 * DeltaTime;

				loc = vect(0,0,0);
				loc.Y = alpha;
				if (Abs(curLeanDist + alpha) < maxLeanDist)
				{
					// check to make sure the destination not blocked
					checkpoint = (loc >> Rotation) + Location;
					traceSize.X = CollisionRadius;
					traceSize.Y = CollisionRadius;
					traceSize.Z = CollisionHeight;
					HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, True, traceSize);

					// check down as well to make sure there's a floor there
					downcheck = checkpoint - vect(0,0,1) * CollisionHeight;
					HitActorDown = Trace(HitLocation, HitNormal, downcheck, checkpoint, True, traceSize);
					if ((HitActor == None) && (HitActorDown != None))
					{
						if ( PlayerIsClient() || (Level.NetMode == NM_Standalone))
						{
							SetLocation(checkpoint);
							ServerUpdateLean( checkpoint );
							curLeanDist += alpha;
						}
					}
				}
				else
				{
					if ( PlayerIsClient() || (Level.NetMode == NM_Standalone) )
						curLeanDist = aExtra0 * maxLeanDist;
				}
			}
			else if (IsLeaning())	//if (!bCanLean && IsLeaning())	// uncomment this to not hold down lean
			{
				// un-lean
				if (AnimSequence == 'CrouchWalk')
					PlayRising();

				if ( PlayerIsClient() || (Level.NetMode == NM_Standalone))
				{
					prevLeanDist = curLeanDist;
					alpha = FClamp(7.0 * DeltaTime, 0.001, 0.9);
					curLeanDist *= 1.0 - alpha;
					if (Abs(curLeanDist) < 1.0)
						curLeanDist = 0;
				}

				loc = vect(0,0,0);
				loc.Y = -(prevLeanDist - curLeanDist);

				// check to make sure the destination not blocked
				checkpoint = (loc >> Rotation) + Location;
				traceSize.X = CollisionRadius;
				traceSize.Y = CollisionRadius;
				traceSize.Z = CollisionHeight;
				HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, True, traceSize);

				// check down as well to make sure there's a floor there
				downcheck = checkpoint - vect(0,0,1) * CollisionHeight;
				HitActorDown = Trace(HitLocation, HitNormal, downcheck, checkpoint, True, traceSize);
				if ((HitActor == None) && (HitActorDown != None))
				{
					if ( PlayerIsClient() || (Level.NetMode == NM_Standalone))
					{
						SetLocation( checkpoint );
						ServerUpdateLean( checkpoint );
					}
				}
			}
		
		
	}

	function ZoneChange(ZoneInfo NewZone)
	{
		// if we jump into water, empty our hands
		if (NewZone.bWaterZone)
			DropDecoration();

		Super.ZoneChange(NewZone);
	}

	event PlayerTick(float deltaTime)
	{
        //DEUS_EX AMSD Additional updates
        //Because of replication delay, aug icons end up being a step behind generally.  So refresh them
        //every freaking tick.  
        RefreshSystems(deltaTime);

		DrugEffects(deltaTime);
		Bleed(deltaTime);
		HighlightCenterObject();


		UpdateDynamicMusic(deltaTime);
		UpdateWarrenEMPField(deltaTime);
      // DEUS_EX AMSD Move these funcions to a multiplayer tick
      // so that only that call gets propagated to the server.
      MultiplayerTick(deltaTime);
      // DEUS_EX AMSD For multiplayer...
		FrobTime += deltaTime;

		// save some texture info
		FloorMaterial = GetFloorMaterial();
		WallMaterial = GetWallMaterial(WallNormal);

		// Check if player has walked outside a first-person convo.
		CheckActiveConversationRadius();

		// Check if all the people involved in a conversation are 
		// still within a reasonable radius.
		CheckActorDistances();

		// handle poison
      //DEUS_EX AMSD Now handled in multiplayertick
		//UpdatePoison(deltaTime);

		// Update Time Played
		UpdateTimePlayed(deltaTime);

		Super.PlayerTick(deltaTime);
	}
}

defaultproperties
{
	Mass=2
PlayerReplicationInfoClass=Class'TCPRI'
     CollisionRadius=5.000000
     CollisionHeight=10.000000
     BaseEyeHeight=10.00
     Drawscale=0.18
     mpGroundSpeed=30.00
    mpWaterSpeed=10.00
    Jumpz=200
    MaxStepHeight=10.000000
}
