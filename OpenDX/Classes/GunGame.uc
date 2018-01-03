//=============================================================================
// yee
//=============================================================================
class GunGame expands TCDeathmatch;

function PostBeginPlay()
{
local DeusExWeapon w;
local int r;

    super.PostBeginPlay();
	
		SetTimer(5,true);

		for(r=0;r<Arraycount(Settings.SaveSpawnWeapons);r++) //Weapon clearing and saving array weapons.
		{
			Foreach AllActors(class'DeusExWeapon',w)
			{	
				if(w.tag != Settings.SaveSpawnWeapons[r])
				{
					w.Destroy();
				}
			}
		}

}

function Timer()
{
	local TCPlayer ssp;
	foreach AllActors(class'TCPlayer',ssp)		
		if (ssp !=None)
			SSP.AmmoRestock();
}

function Killed( pawn Killer, pawn Other, name damageType )
{
	local bool NotifyDeath;
	local DeusExPlayer otherPlayer;
	local Pawn CurPawn;
	local class<actor> checkClass;
	local int i;
	local TCPlayer TCP;
	local class<Inventory> GiveClass;
	local int Passes, r;
	local Inventory anItem, anItem2;
   local Class<Inventory> w;
   //both players...
   if ((Killer.bIsPlayer) && (Other.bIsPlayer))
   {
			for(i=0;i<Arraycount(Settings.DemoteWeapons) && Settings.DemoteWeapons[i] != "";i++)
			{
				checkClass=class<Actor>(DynamicLoadObject(Settings.DemoteWeapons[i],class'class'));

				if(TCPlayer(Killer).inHand.class != none && checkClass != none)
				{
					if(TCPlayer(Killer).inHand.class == checkClass)
					{
						if(TCPRI(TCPlayer(Other).PlayerReplicationInfo).Rank > 1)
						{
							TCPRI(TCPlayer(Other).PlayerReplicationInfo).Rank -= 1;	
							BroadcastMessage(Other.PlayerReplicationInfo.PlayerName$" was demoted!");
						}

					}
				}
			}
		if (Killer != Other)
		{
				// Grant the kill to the killer, and increase his streak
				Killer.PlayerReplicationInfo.Score += 1;
				if(TCPRI(TCPlayer(Killer).PlayerReplicationInfo).Rank < 12)
				{		
					TCPRI(TCPlayer(Killer).PlayerReplicationInfo).Rank += 1;
					RemovePlayerInventory(TCPlayer(Killer));
					//TCPlayer(Killer).GGRank();
					r = TCPRI(TCPlayer(Killer).PlayerReplicationInfo).Rank;

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
					anItem.Frob(TCPlayer(Killer),None);	  
					Inventory.bInObjectBelt = True;
					anItem.Destroy();
						 
					anItem = Spawn(class'WeaponCombatKnife');
					anItem.Frob(TCPlayer(Killer),None);	  
					Inventory.bInObjectBelt = True;
					anItem.Destroy();
					TCPlayer(Killer).ClientMessage("|P7Ranked up to "$TCPRI(TCPlayer(Killer).PlayerReplicationInfo).Rank$"!");
				}
		}
   }

      Super.Killed(Killer,Other,damageType);

}

function RemovePlayerInventory(DeusExPlayer Player)
{
   local Inventory item, nextItem, lastItem;

   if (Player.Inventory != None)
   {
      item = Player.Inventory;
      nextItem = item.Inventory;
      lastItem = item;

      do
      {
         if ((item != None) && item.bDisplayableInv || item.IsA('Ammo'))
         {
            // make sure everything is turned off
            if (item.IsA('DeusExWeapon'))
            {
               DeusExWeapon(item).ScopeOff();
               DeusExWeapon(item).LaserOff();
            }
            if (item.IsA('DeusExPickup'))
            {
               if (DeusExPickup(item).bActive)
                  DeusExPickup(item).Activate();
            }

            if (item.IsA('ChargedPickup'))
               Player.RemoveChargedDisplay(ChargedPickup(item));

            Player.DeleteInventory(item);
            item.Destroy();
            item = Player.Inventory;
         }
         else
            item = nextItem;

         if (item != None)
            nextItem = item.Inventory;
      }
      until ((item == None) || (item == lastItem));
   }
}

defaultproperties
{
	GTName="Arsenal (WIP)"
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) - |P2(Your weapon changes as you streak)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) - |P2(Your weapon changes as you streak)"
}
