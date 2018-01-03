//=============================================================================
// Radar
//=============================================================================
class AugRadar extends Augmentation;

var float mpAugValue;
var float mpEnergyDrain;

state Active
{
Begin:
	if(Player.Energy < 1)
		Deactivate();
Loop:
	if(Player.Energy > 0)
	{
		Scan();
	}
	else
		Deactivate();
		
	Sleep(5.0);
	
	Goto('Loop');
}

function Scan()
{
    local Actor a;
    local TCPlayer target;
    local int count, allycount;

    count = 0;
	allycount = 0;
	foreach RadiusActors(class'Actor', a, 256, Player.Location)
	{
		if(a.IsA('TCPlayer'))
		{
			target = TCPlayer(a);
			if(target.PlayerReplicationInfo != None && target != TCPlayer(Player) && !target.PlayerReplicationInfo.bIsSpectator && target.Health > 0 && target.AugmentationSystem.GetAugLevelValue(class'AugRadarTrans') == -1.0 && !target.bHidden )
			{
				count++;
			
				if(AreAllies(TCPlayer(Player), target))
					allycount++;
			}
		}
	}
	
	if(count > 0)
	{
		Player.Energy -= 1;
		Player.ClientMessage("Hostiles detected. "$count$" targets, "$allycount$" allies.");
	}
}

function bool AreAllies(TCPlayer POne, TCPlayer PTwo)
{
	if(TCDeathmatch(player.DXGame) != None)
		return TCDeathmatch(player.DXGame).ArePlayersAllied2(POne,PTwo);
		
	if(TCTeam(player.DXGame) != None)
		return TCTeam(player.DXGame).ArePlayersAllied(POne,PTwo);	
}


simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// If this is a netgame, then override defaults
	if ( Level.NetMode != NM_StandAlone )
	{
		LevelValues[3] = mpAugValue;
		EnergyRate = mpEnergyDrain;
        AugmentationLocation = LOC_Cranial;
	}
}

defaultproperties
{
    mpAugValue=0
    mpEnergyDrain=0
    EnergyRate=0
    Icon=Texture'AugIconDataLink'
    smallIcon=Texture'AugIconDataLink_Small'
    AugmentationName="Radar"
    Description=""
    MPInfo="Scans nearby hostiles"
    LevelValues(0)=0
    LevelValues(1)=0
    LevelValues(2)=0
    LevelValues(3)=0
    AugmentationLocation=5
    MPConflictSlot=9
}
