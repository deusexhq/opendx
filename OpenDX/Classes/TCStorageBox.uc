//=============================================================================
// DeusExCarcass.
//=============================================================================
class TCStorageBox extends Containers;

struct InventoryItemCarcass  {
	var() class<Inventory> Inventory;
	var() int              count;
};

var(Inventory) InventoryItemCarcass InitialInventory[8];  // Initial inventory items held in the carcass
var bool bQueuedDestroy;

var string OwnerName, myName;
var bool bLocked;

replication
{
    reliable if (ROLE == ROLE_Authority)
		OwnerName, myName;
}
function PostBeginPlay()
{
	local int i, j;
	local Inventory inv;

	bCollideWorld = true;
	// Add initial inventory items
	for (i=0; i<8; i++)
	{
		if ((InitialInventory[i].inventory != None) && (InitialInventory[i].count > 0))
		{
			for (j=0; j<InitialInventory[i].count; j++)
			{
				inv = spawn(InitialInventory[i].inventory, self);
				if (inv != None)
				{
					inv.bHidden = True;
					inv.SetPhysics(PHYS_None);
					AddInventory(inv);
				}
			}
		}
	}

	Super.PostBeginPlay();
}


function Frob(Actor Frobber, Inventory frobWith)
{
	local Inventory item, nextItem, startItem;
	local Pawn P;
	local DeusExWeapon W;
	local bool bFoundSomething;
	local DeusExPlayer player;
	local ammo AmmoType;
	local bool bPickedItemUp;
	local POVCorpse corpse;
	local DeusExPickup invItem;
	local int itemCount;
	local bool bDontDestroy;
	
	player = DeusExPlayer(Frobber);

	if (bQueuedDestroy)
		return;

	if(bLocked)
	{
		player.ClientMessage("It's locked.");
		return;
	}
	bFoundSomething = False;
	//bSearchMsgPrinted = False;
	P = Pawn(Frobber);
	if (P != None)
	{

		if (Inventory != None)
		{

			item = Inventory;
			startItem = item;

			do
			{

				nextItem = item.Inventory;

				bPickedItemUp = False;

				if (item.IsA('Ammo'))
				{
					// Only let the player pick up ammo that's already in a weapon
					DeleteInventory(item);
					item.Destroy();
					item = None;
				}
				else if ( (item.IsA('DeusExWeapon')) )
				{
               // Any weapons have their ammo set to a random number of rounds (1-4)
               // unless it's a grenade, in which case we only want to dole out one.
               // DEUS_EX AMSD In multiplayer, give everything away.
               W = DeusExWeapon(item);
               
               // Grenades and LAMs always pickup 1
               if (W.IsA('WeaponNanoVirusGrenade') || 
                  W.IsA('WeaponGasGrenade') || 
                  W.IsA('WeaponEMPGrenade') ||
                  W.IsA('WeaponLAM'))
                  W.PickupAmmoCount = 1;
               else if (Level.NetMode == NM_Standalone)
                  W.PickupAmmoCount = Rand(4) + 1;
				}
				
				if (item != None)
				{
					bFoundSomething = True;

					if (item.IsA('DeusExWeapon'))   // I *really* hate special cases
					{
						// Okay, check to see if the player already has this weapon.  If so,
						// then just give the ammo and not the weapon.  Otherwise give
						// the weapon normally. 
						W = DeusExWeapon(player.FindInventoryType(item.Class));

						// If the player already has this item in his inventory, piece of cake,
						// we just give him the ammo.  However, if the Weapon is *not* in the 
						// player's inventory, first check to see if there's room for it.  If so,
						// then we'll give it to him normally.  If there's *NO* room, then we 
						// want to give the player the AMMO only (as if the player already had 
						// the weapon).

						if ((W != None) || ((W == None) && (!player.FindInventorySlot(item, True))))
						{
							// Don't bother with this is there's no ammo
							if ((Weapon(item).AmmoType != None) && (Weapon(item).AmmoType.AmmoAmount > 0))
							{
								AmmoType = Ammo(player.FindInventoryType(Weapon(item).AmmoName));

                        if ((AmmoType != None) && (AmmoType.AmmoAmount < AmmoType.MaxAmmo))
								{
                           AmmoType.AddAmmo(Weapon(item).PickupAmmoCount);
                           AddReceivedItem(player, AmmoType, Weapon(item).PickupAmmoCount);
                           
									// Update the ammo display on the object belt
									player.UpdateAmmoBeltText(AmmoType);

									// if this is an illegal ammo type, use the weapon name to print the message
									if (AmmoType.PickupViewMesh == Mesh'TestBox')
										P.ClientMessage(item.PickupMessage @ item.itemArticle @ item.itemName, 'Pickup');
									else
										P.ClientMessage(AmmoType.PickupMessage @ AmmoType.itemArticle @ AmmoType.itemName, 'Pickup');

									// Mark it as 0 to prevent it from being added twice
									Weapon(item).AmmoType.AmmoAmount = 0;
								}
							}

							// Print a message "Cannot pickup blah blah blah" if inventory is full
							// and the player can't pickup this weapon, so the player at least knows
							// if he empties some inventory he can get something potentially cooler
							// than he already has. 
							if ((W == None) && (!player.FindInventorySlot(item, True)))
								{
									bDontDestroy=True;
									P.ClientMessage(Sprintf(Player.InventoryFull, item.itemName));
								}

							// Only destroy the weapon if the player already has it.
							if (W != None)
							{
								// Destroy the weapon, baby!
								DeleteInventory(item);
								item.Destroy();
								item = None;
							}

							bPickedItemUp = True;
						}
					}

					else if (item.IsA('DeusExAmmo'))
					{
						if (DeusExAmmo(item).AmmoAmount == 0)
							bPickedItemUp = True;
					}

					if (!bPickedItemUp)
					{
						// Special case if this is a DeusExPickup(), it can have multiple copies
						// and the player already has it.

						if ((item.IsA('DeusExPickup')) && (DeusExPickup(item).bCanHaveMultipleCopies) && (player.FindInventoryType(item.class) != None))
						{
							invItem   = DeusExPickup(player.FindInventoryType(item.class));
							itemCount = DeusExPickup(item).numCopies;

							// Make sure the player doesn't have too many copies
							if ((invItem.MaxCopies > 0) && (DeusExPickup(item).numCopies + invItem.numCopies > invItem.MaxCopies))
							{	
								// Give the player the max #
								if ((invItem.MaxCopies - invItem.numCopies) > 0)
								{
									itemCount = (invItem.MaxCopies - invItem.numCopies);
									DeusExPickup(item).numCopies -= itemCount;
									invItem.numCopies = invItem.MaxCopies;
									P.ClientMessage(invItem.PickupMessage @ invItem.itemArticle @ invItem.itemName, 'Pickup');
									AddReceivedItem(player, invItem, itemCount);
								}
								else
								{
									bDontDestroy=True;
									P.ClientMessage("No room for "$invItem.itemName);
								}
							}
							else
							{
								invItem.numCopies += itemCount;
								DeleteInventory(item);

								P.ClientMessage(invItem.PickupMessage @ invItem.itemArticle @ invItem.itemName, 'Pickup');
								AddReceivedItem(player, invItem, itemCount);
							}
						}
						else
						{
							// check if the pawn is allowed to pick this up
							if ((P.Inventory == None) || (Level.Game.PickupQuery(P, item)))
							{
								DeusExPlayer(P).FrobTarget = item;
								if (DeusExPlayer(P).HandleItemPickup(Item) != False)
								{
                           DeleteInventory(item);

                           // DEUS_EX AMSD Belt info isn't always getting cleaned up.  Clean it up.
                           item.bInObjectBelt=False;
                           item.BeltPos=-1;
									
                           item.SpawnCopy(P);

									// Show the item received in the ReceivedItems window and also 
									// display a line in the Log
									AddReceivedItem(player, item, 1);
									
									P.ClientMessage(Item.PickupMessage @ Item.itemArticle @ Item.itemName, 'Pickup');
									PlaySound(Item.PickupSound);
								}
							}
							else
							{
								DeleteInventory(item);
								item.Destroy();
								item = None;
							}
						}
					}
				}

				item = nextItem;
			}
			until ((item == None) || (item == startItem));
		}

//log("  bFoundSomething = " $ bFoundSomething);

		if (!bFoundSomething)
			P.ClientMessage("Empty...");
	}

	Super.Frob(Frobber, frobWith);

   if ((Level.Netmode != NM_Standalone) && (Player != None) && !bDontDestroy)   
   {
	   bQueuedDestroy = true;
	   //Destroy();	 
	   bInvincible=False;
	   TakeDamage(1000,P, vect(0,0,0), vect(0,0,0),'Tantalus');
   }
}

// ----------------------------------------------------------------------
// AddReceivedItem()
// ----------------------------------------------------------------------

function AddReceivedItem(DeusExPlayer player, Inventory item, int count)
{
	local DeusExWeapon w;
	local Inventory altAmmo;

   DeusExRootWindow(player.rootWindow).hud.receivedItems.AddItem(item, 1);

	// Make sure the object belt is updated
	if (item.IsA('Ammo'))
		player.UpdateAmmoBeltText(Ammo(item));
	else
		player.UpdateBeltText(item);

	// Deny 20mm and WP rockets off of bodies in multiplayer
	if ( Level.NetMode != NM_Standalone )
	{
		if ( item.IsA('WeaponAssaultGun') || item.IsA('WeaponGEPGun') )
		{
			w = DeusExWeapon(player.FindInventoryType(item.Class));
			if (( Ammo20mm(w.AmmoType) != None ) || ( AmmoRocketWP(w.AmmoType) != None ))
			{
				altAmmo = Spawn( w.AmmoNames[0] );
				DeusExAmmo(altAmmo).AmmoAmount = w.PickupAmmoCount;
				altAmmo.Frob(player,None);
				altAmmo.Destroy();
				w.AmmoType.Destroy();
				w.LoadAmmo( 0 );
			}
		}
	}
}

// ----------------------------------------------------------------------
// AddInventory()
//
// copied from Engine.Pawn
// Add Item to this carcasses inventory. 
// Returns true if successfully added, false if not.
// ----------------------------------------------------------------------

function bool AddInventory( inventory NewItem )
{
	// Skip if already in the inventory.
	local inventory Inv;

	for( Inv=Inventory; Inv!=None; Inv=Inv.Inventory )
		if( Inv == NewItem )
			return false;

	// The item should not have been destroyed if we get here.
	assert(NewItem!=None);

	// Add to front of inventory chain.
	NewItem.SetOwner(Self);
	NewItem.Inventory = Inventory;
	NewItem.InitialState = 'Idle2';
	Inventory = NewItem;

	return true;
}

// ----------------------------------------------------------------------
// DeleteInventory()
// 
// copied from Engine.Pawn
// Remove Item from this pawn's inventory, if it exists.
// Returns true if it existed and was deleted, false if it did not exist.
// ----------------------------------------------------------------------

function bool DeleteInventory( inventory Item )
{
	// If this item is in our inventory chain, unlink it.
	local actor Link;

	for( Link = Self; Link!=None; Link=Link.Inventory )
	{
		if( Link.Inventory == Item )
		{
			Link.Inventory = Item.Inventory;
			break;
		}
	}
   Item.SetOwner(None);
}

defaultproperties
{
	 bPushable=False
 FragType=Class'DeusEx.WoodFragment'
 bInvincible=True
     ItemName="Storage Crate"
     bBlockSight=True
     Skin=Texture'DeusExDeco.Skins.CrateBreakableMedTex3'
     Mesh=LodMesh'DeusExDeco.CrateBreakableMed'
     CollisionRadius=34.000000
     CollisionHeight=24.000000
     Mass=50.000000
     Buoyancy=60.000000
}
