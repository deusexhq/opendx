//=============================================================================
// Pickup class that can be set to give any aug.
//=============================================================================
class PraxisKit extends DeusExPickup;

#exec TEXTURE IMPORT NAME="PraxisTex1" FILE="Textures\Praxis1.pcx" GROUP="Skins"

#exec TEXTURE IMPORT NAME="LargeIconPraxis" FILE="Textures\LargeIconPraxis.pcx" GROUP=Icons FLAGS=2
#exec TEXTURE IMPORT NAME="BeltIconPraxis" FILE="Textures\BeltIconPraxis.pcx" GROUP=Icons FLAGS=2

var() bool bResetAugSystem, bResetPerks;

var() class<Augmentation> PraxisAug;
var() string PraxisPerk;

state Activated
{
	function Activate()
	{
		// can't turn it off
	}

	function BeginState()
	{
		local DeusExPlayer player;
		local bool bUseUp;
			local int i;
			
		Super.BeginState();

		player = DeusExPlayer(Owner);
		if (player != None)
		{
			if(bResetAugSystem)
			{
				if (Player.AugmentationSystem != None)
				{
					Player.AugmentationSystem.DeactivateAll();
					Player.AugmentationSystem.ResetAugmentations();
					Player.AugmentationSystem.Destroy();
					Player.AugmentationSystem = None;
					Player.ClientMessage("|P2Removing augmentations...");
				}
				
				if (Player.AugmentationSystem == None)
				{
					Player.AugmentationSystem = Spawn(class'TCAugmentationManager', Player);
					Player.AugmentationSystem.CreateAugmentations(Player);
					Player.AugmentationSystem.AddDefaultAugmentations();        
					Player.AugmentationSystem.SetOwner(Player);     
				}
			}
			
			if(bResetPerks)
			{
				Player.ClientMessage("|P2Resetting perks...");
				for(i=0;i<10;i++)
					TCPlayer(Player).RemovePerk(i);
				bUseUp=True;
			}
			
			if(PraxisAug != None)
			{
					bUseUp=True;
					player.AugmentationSystem.GivePlayerAugmentation(PraxisAug);
					player.AugmentationSystem.GivePlayerAugmentation(PraxisAug);
			}
			
			if(PraxisPerk != "")
			{
						TCPlayer(Player).GetPerk(PraxisPerk);
						bUseUp=True;
			}
		}
		
	if(bUseUp)
		UseOnce();
	}
Begin:
}

defaultproperties
{
     maxCopies=1
     bCanHaveMultipleCopies=True
     bActivatable=True
     ItemName="Praxis Kit"
     M_Activated=""
     ItemArticle="a"
     PlayerViewOffset=(X=30.000000,Z=-12.000000)
     PlayerViewMesh=LodMesh'DeusExItems.MedKit'
     PickupViewMesh=LodMesh'DeusExItems.MedKit'
     ThirdPersonMesh=LodMesh'DeusExItems.MedKit3rd'
     LandSound=Sound'DeusExSounds.Generic.PlasticHit2'
     Icon=Texture'AugIconDatalink_Small'
     largeIcon=Texture'AugIconDatalink'
     largeIconWidth=39
     largeIconHeight=46
     MultiSkins(0)=Texture'PraxisTex1'
     Description="Contained the nano-data for augmentations."
     beltDescription="PRAXIS"
     Mesh=LodMesh'DeusExItems.MedKit'
     CollisionRadius=7.500000
     CollisionHeight=1.000000
     Mass=10.000000
     Buoyancy=8.000000
}
