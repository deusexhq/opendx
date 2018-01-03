class TCTeamManager extends Mutator;
//Even though its called Team Manager, because this class used to only manage Teams friendlyfire
//Now extended to include any takedamage hooks required.

function string GetDisplayName(pawn Chk)
{
	if(ScriptedPawn(Chk) != None)
		return ScriptedPawn(Chk).FamiliarName;
		
	if(TCPlayer(Chk) != None)
		return TCPlayer(Chk).PlayerReplicationInfo.PlayerName;	
}

function string CalcHitLoc(int HitPart)
{
	if(HitPart == 1)
		return "Head";

	if(HitPart == 2)
		return "Torso";
		
	if(HitPart == 3)
		return "Legs";

	if(HitPart == 4)
		return "Legs";
	
	if(HitPart == 5)
		return "Torso";

	if(HitPart == 6)
		return "Torso";
}

function MutatorTakeDamage (out Int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, out Vector Momentum, Name DamageType)
{
	local string hitstr, colstr, quadstr;
	super.MutatorTakeDamage (ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType);


	if(TCPlayer(instigatedBy) != None)
	{
		if(TCPlayer(Victim).HasPerk("Infection"))
		{
				ActualDamage = ActualDamage * 1.5;
		}
		
		if(TCPlayer(instigatedBy).HasPerk("Quad Damage"))
		{
				ActualDamage = ActualDamage * 4;
		}
		
		if(Juggernaut(level.game) != None)
		{
			if(TCPlayer(Victim) == Juggernaut(level.game).Juggernaut)
			{
				ActualDamage = ActualDamage / 2;
			}
		}
		
		if(DeusExPlayer(victim) != None)
			hitstr = CalcHitLoc(DeusExPlayer(victim).GetMPHitLocation(HitLocation));

		if(TCPlayer(instigatedBy).GetControls().bShowHitz)
		{
			if(ActualDamage > 0)
			{
				if(DamageType == 'EMP')
					colstr = "|C1E90FF";
				if(DamageType == 'Flamed' || DamageType == 'Burned')
					colstr = "|P2";
				if(DamageType == 'PoisonEffect' || DamageType == 'Poison' || DamageType == 'TearGas')
					colstr = "|C14D920";
				if(DamageType == 'KnockedOut' || DamageType == 'exploded' || DamageType == 'Stunned' || DamageType == 'stomped')
					colstr = "|CEEF600";
				if(DamageType == 'SpecialDamage' || DamageType == 'Tantalus' || DamageType == 'Nanovirus')
					colstr = "|P7";
				if(DamageType == 'shot')
					colstr = "|P1";
				
				if(TCPlayer(instigatedBy).HasPerk("Quad Damage"))
				{
					if(hitstr == "")
						TCPlayer(instigatedBy).ShowHitz(colstr$"("$ActualDamage / 4$" x4)");
					else
						TCPlayer(instigatedBy).ShowHitz(colstr$"("$ActualDamage / 4$" x4) >> "$hitstr$") ");
				}
				else
				{
					if(hitstr == "")
						TCPlayer(instigatedBy).ShowHitz(colstr$"("$ActualDamage$")");
					else
						TCPlayer(instigatedBy).ShowHitz(colstr$"("$ActualDamage$" >> "$hitstr$") ");	
				}

			}
		}
		
		if(TCDeathmatch(level.game) == None)
			return;
		if(TCPlayer(InstigatedBy).TeamName == "")
		return;
		if(TCPlayer(Victim) != None && Victim != InstigatedBy)
		{
			if(TCPlayer(Victim).TeamName == "")
			return;	
					if(TCPlayer(InstigatedBy).TeamName ~= TCPlayer(Victim).TeamName)
					{
						if(!TCDeathMatch(Level.Game).Settings.bTCFriendlyFire)
						{
							ActualDamage /= TCDeathMatch(Level.Game).Settings.ffReduction;
								return;				
						}
		
					}
		}
	}
}

function ModifyPlayer(Pawn Other)
{
	local TCPlayer P;
	local class<Inventory> GiveClass;
	local int Passes, r;
	local Inventory anItem, anItem2, i;
   local Class<Inventory> w;
   
	super.ModifyPlayer(Other);
	p = TCPlayer(Other);
	
	if(GunGame(Level.Game) != None)
	{			 
		   r = TCPRI(P.PlayerReplicationInfo).Rank;

		 if (r == 1)
		   w = class'WeaponStealthPistol';
		   
		 if (r == 2)
		   w = class'WeaponPistol';
		   
		 if (r == 3)
		   w = class'WeaponFlamethrower';
		   
		 if (r == 4)
		   w = class'WeaponMiniCrossbow';
		   
		 if (r == 5)
		   w = class'WeaponShuriken';
		   
		 if (r == 6)
		   w = class'WeaponSawedOffShotgun';
		   
		 if (r == 7)
		   w = class'WeaponAssaultShotgun';
		   
		 if (r == 8)
		   w = class'WeaponAssaultgun';

		 if (r == 9)
		   w = class'WeaponPlasmaRifle';
		   
		 if (r == 10)
		   w = class'WeaponGepGun';
		   
		 if (r == 11)
		   w = class'Weaponrifle';
		   
		 if (r == 12)
		   w = class'WeaponNanoSword';
		   
		anItem = Spawn(w);
		anItem.Frob(P,None);	  
		Inventory.bInObjectBelt = True;
		anItem.Destroy();
			 
		anItem = Spawn(class'WeaponCombatKnife');
		anItem.Frob(P,None);	  
		Inventory.bInObjectBelt = True;
		anItem.Destroy();
	}
	
	else if(Sharpshooter(Level.Game) != None)
	{
		while(Passes < 3)
		{
			
			if(Passes == 0) r = RandRange(0,10);
			if(Passes == 1) r = RandRange(11, 20);
			if(Passes == 2) r = RandRange(21,29);
			Passes++;
			GiveClass = class<inventory>( DynamicLoadObject( p.GetControls().SSWeapons[r], class'Class' ) );
			if( GiveClass!=None )
			{
				anItem = Spawn(GiveClass,,,p.Location); 
				anItem.SpawnCopy(P);
				anItem.Destroy();
			}
			else
				Log("Error in TCControls.SSWeapons array: "$r$" slot could not be spawned. (PLAYER)");
		}
	}

}

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
defaultproperties
{
}
