//=============================================================================
// yee
//=============================================================================
class Sharpshooter expands TCDeathmatch;
var int SSCount, SSDefaultCount;
function PostBeginPlay()
{
local DeusExWeapon w;
local int r;
local SSTimer SST;

    super.PostBeginPlay();
	
	
	Log(Settings.SSRoundDelay$" round timer.");
	SST = Spawn(class'SSTimer');
	SST.SetTimer(1,true);
	SST.SSCount = Settings.SSRoundDelay;
	SST.SSDefaultCount = Settings.SSRoundDelay;
	SST.myGame = Self;
	Foreach AllActors(class'DeusExWeapon',w)
	{	
			w.Destroy();
	}
}

function RollItems()
{
	local TCPlayer TCP;
	local class<Inventory> GiveClass;
	local int Passes, r;
	
	foreach AllActors(class'TCPlayer', TCP)
	{
		if(Settings.bHealTimer)
			TCP.HealPlayer(15, True);
			
		RemovePlayerInventory(TCP);
		while(Passes < 3)
		{
			if(Passes == 0) r = RandRange(0,10);
			if(Passes == 1) r = RandRange(11, 20);
			if(Passes == 2) r = RandRange(21,29);
			Passes++;
			
			GiveClass = class<inventory>( DynamicLoadObject( Settings.SSWeapons[r], class'Class' ) );
			if( GiveClass!=None )
				SilentAdd(GiveClass, TCP);
			else
				Log("Error in TCControls.SSWeapons array: "$r$" slot could not be spawned.");
		}
		Passes = 0;
	}
}

function SilentAdd(class<inventory> addClass, DeusExPlayer addTarget)
{ 
	local Inventory anItem;
	
	if(Settings.bMethodOne)
	{
		anItem = Spawn(addClass,,,addTarget.Location); 
		anItem.SpawnCopy(addTarget);
		anItem.Destroy();
	}
	else
	{
		anItem.Instigator = addTarget; 
		anItem.GotoState('Idle2'); 
		anItem.bHeldItem = true; 
		anItem.bTossedOut = false; 
		
		if(Weapon(anItem) != None) 
			Weapon(anItem).GiveAmmo(addTarget); 
		anItem.GiveTo(addTarget);
	}
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
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) -|P2 (Weapons randomized through the match)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) -|P2 (Weapons randomized through the match)"
	GTName="Sharpshooter (WIP)"
}
