class TCWeaponGasGrenade extends WeaponGasGrenade;

function PlaceGrenade()
{
	if (AmmoType.AmmoAmount <= 0) 
	{
		Destroy();
		return;
	}
	super.PlaceGrenade();
	if (AmmoType.AmmoAmount <= 0) Destroy();
}

state NormalFire
{
	function AnimEnd()
	{
		if (bAutomatic)
		{
			if ((Pawn(Owner).bFire != 0) && (AmmoType.AmmoAmount > 0))
			{
				if (PlayerPawn(Owner) != None)
					Global.Fire(0);
				else 
					GotoState('FinishFire');
			}
			else 
				GotoState('FinishFire');
		}
		else
		{
			// if we are a thrown weapon and we run out of ammo, destroy the weapon
			if (bHandToHand && (ReloadCount > 0) && (AmmoType.AmmoAmount <= 0))
			{
				// fix disappear bug:
				//Destroy();
			}
		}
	}
}

function Fire(float Value)
{
	local float sndVolume;
	local bool bListenClient;

	if (Pawn(Owner) != None)
	{
		if (bNearWall)
		{
			bReadyToFire = False;
			GotoState('NormalFire');
			bPointing = True;
			PlayAnim('Place',, 0.1);
			return;
		}
	}

	bListenClient = (Owner.IsA('DeusExPlayer') && DeusExPlayer(Owner).PlayerIsListenClient());

	sndVolume = TransientSoundVolume;

	if ( Level.NetMode != NM_Standalone )  // Turn up the sounds a bit in mulitplayer
	{
		sndVolume = TransientSoundVolume * 2.0;
		if ( Owner.IsA('DeusExPlayer') && (DeusExPlayer(Owner).NintendoImmunityTimeLeft > 0.01) || (!bClientReady && (!bListenClient)) )
		{
			DeusExPlayer(Owner).bJustFired = False;
			bReadyToFire = True;
			bPointing = False;
			bFiring = False;
			return;
		}
	}
	// check for surrounding environment
	if ((EnviroEffective == ENVEFF_Air) || (EnviroEffective == ENVEFF_Vacuum) || (EnviroEffective == ENVEFF_AirVacuum))
	{
		if (Region.Zone.bWaterZone)
		{
			if (Pawn(Owner) != None)
			{
				Pawn(Owner).ClientMessage(msgNotWorking);
				if (!bHandToHand)
					PlaySimSound( Misc1Sound, SLOT_None, sndVolume, 1024 );		// play dry fire sound
			}
			GotoState('Idle');
			return;
		}
	}

	if (bHandToHand)
	{
		if (( Level.NetMode != NM_Standalone ) && !bListenClient )
			bClientReady = False;
		bReadyToFire = False;
		GotoState('NormalFire');
		bPointing=True;
		if ( Owner.IsA('PlayerPawn') )
			PlayerPawn(Owner).PlayFiring();
		PlaySelectiveFiring();
		PlayFiringSound();
	}
}

simulated function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Projectile proj;

	if (AmmoType.AmmoAmount <= 0)
	{
		bDestroyOnFinish = true;
		return none;
	}
	
	proj = super.ProjectileFire(ProjClass, ProjSpeed, bWarn);
	if (proj != none)
	{
		if (ReloadCount > 0) AmmoType.UseAmmo(1);

		if ( AmmoType.AmmoAmount <= 0 )
			bDestroyOnFinish = True;

		// Update ammo count on object belt
		if (DeusExPlayer(Owner) != None)
			DeusExPlayer(Owner).UpdateBeltText(Self);
	}

	return proj;
}

simulated function bool ClientFire( float value )
{
    //servernotify("clientFire - netmode:"@level.NetMode);
    if(ReloadCount <= 0)
        ReloadCount=1;

    return Super.ClientFire(value);
}


defaultproperties
{
    //ProjectileClass=Class'TCGasGrenade'
}
