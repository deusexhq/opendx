//=============================================================================
// AugmentationManager
//=============================================================================
class TCAugmentationManager extends CBPAugmentationManager;

var Class<Augmentation> augClassesODX[45]; //we need MOAR AUGS - Upped from 25 to 31, maybe more than needed..

function AddAllAugs()
{
	local int augIndex;

	// Loop through all the augmentation classes and create
	// any augs that don't exist.  Then set them all to the 
	// maximum level.

	for(augIndex=0; augIndex<arrayCount(augClassesODX); augIndex++)
	{
		if (augClasses[augIndex] != None)
			GivePlayerAugmentation(augClassesODX[augIndex]);
	}
}


function CreateAugmentations(DeusExPlayer newPlayer)
{
	local int augIndex;
	local Augmentation anAug;
	local Augmentation lastAug;

	FirstAug = None;
	LastAug  = None;

	player = newPlayer;

	for(augIndex=0; augIndex<arrayCount(augClassesODX); augIndex++)
	{
		if (augClassesODX[augIndex] != None)
		{
			anAug = Spawn(augClassesODX[augIndex], Self);
			anAug.Player = player;

			// Manage our linked list
			if (anAug != None)
			{
				if (FirstAug == None)
				{
					FirstAug = anAug;
				}
				else
				{
					LastAug.next = anAug;
				}

				LastAug  = anAug;
			}
		}
	}
}

simulated function int GetClassLevel(class<Augmentation> augClass)
{
  if(Player != None && Player.PlayerReplicationInfo != None)
    if(Player.IsInState('Spectating'))
      if(augClass == Class'DeusEx.AugRadarTrans')
        return 3;

  return Super.GetClassLevel(augClass);
}

simulated function Augmentation FindAugmentation(Class<Augmentation> findClass)
{
	local Augmentation anAug, currentAug;

	anAug = FirstAug;
	while(anAug != None)
	{
        currentAug = anAug;

        if(currentAug.Owner != None && currentAug.Owner.isA('Augmentation'))
            currentAug = Augmentation(currentAug.Owner);
        
		if(currentAug.Class == findClass)
        {
            anAug = currentAug;
			break;
        }

		anAug = anAug.next;
	}

	return anAug;
}

defaultproperties
{
	 augClassesODX(0)=Class'DeusEx.AugSpeed'
     augClassesODX(1)=Class'DeusEx.AugTarget'
     augClassesODX(2)=Class'DeusEx.AugCloak'
     augClassesODX(3)=Class'DeusEx.AugBallistic'
     augClassesODX(4)=Class'DeusEx.AugRadarTrans'
     augClassesODX(5)=Class'DeusEx.AugShield'
     augClassesODX(6)=Class'DeusEx.AugEnviro'
     augClassesODX(7)=Class'DeusEx.AugEMP'
     augClassesODX(8)=Class'DeusEx.AugCombat'
     augClassesODX(9)=Class'OpenDX.AugHealing2'
     augClassesODX(10)=Class'DeusEx.AugStealth'
     augClassesODX(11)=Class'DeusEx.AugIFF'
     augClassesODX(12)=Class'CBPAugLight'
     augClassesODX(13)=Class'DeusEx.AugMuscle'
     augClassesODX(14)=Class'DeusEx.AugVision'
     augClassesODX(15)=Class'DeusEx.AugDrone'
     augClassesODX(16)=Class'DeusEx.AugDefense'
     augClassesODX(17)=Class'DeusEx.AugAqualung'
     augClassesODX(18)=Class'DeusEx.AugDatalink'
     augClassesODX(19)=Class'DeusEx.AugHeartLung'
     augClassesODX(20)=Class'DeusEx.AugPower'
     augClassesODX(21)=Class'OpenDX.AugSkullgun'
     augClassesODX(22)=Class'OpenDX.AugIcarus'
     augClassesODX(23)=Class'OpenDX.AugNuke'
     augClassesODX(24)=Class'OpenDX.AugRepel'
     augClassesODX(25)=Class'OpenDX.AugMediAura'
     augClassesODX(26)=Class'OpenDX.AugFlight'
     augClassesODX(27)=Class'OpenDX.AugRadar'
     augClassesODX(28)=Class'OpenDX.AugTakedown'
     augClassesODX(29)=Class'OpenDX.AugMagnet'
}
