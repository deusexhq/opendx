//=============================================================================
// Medical Aurra
//=============================================================================
class AugMediAura extends Augmentation;

#exec TEXTURE IMPORT NAME="AugIconHealingAura_Small" FILE="Textures\AugIconHealingAura_Small.pcx" GROUP=Icons FLAGS=2
#exec TEXTURE IMPORT NAME="AugIconHealingAura" FILE="Textures\AugIconHealingAura.pcx" GROUP=Icons FLAGS=2

var float mpAugValue;
var float mpEnergyDrain;

state Active
{
Begin:
	if(Player.Energy < 3)
		Deactivate();
		
Loop:
	Sleep(1.0);
    
	if(Player.Energy > 3)
	{
		HealPlayers();
	}

	Goto('Loop');
}

function HealPlayers()
{
    local Actor a;
    local TCPlayer target, targetList[3];
    local int count, i, healamount, totalamount, edrain;

    count = 0;

    if(TCTeam(Player.DXGame) != None) // Healing teammates in deathmatch is useless.
    {
        foreach RadiusActors(class'Actor', a, 256, Player.Location)
        {
            if(a.IsA('TCPlayer')) // TODO: Only heal teammates
            {
                target = TCPlayer(a);
                if(target.PlayerReplicationInfo != None && target != TCPlayer(Player) && !target.PlayerReplicationInfo.bIsSpectator && target.Health > 0 && target.Health < 100 && (target.lastTeamHeal+1 <= Level.TimeSeconds) && (target.PlayerReplicationInfo.Team == player.PlayerReplicationInfo.Team))
                {
                    targetList[count] = target;
                    count++;
                    edrain = 3 * count;
                    if(count == 3) // We heal a maximum of 3 players
                        break;
                }
            }
        }
        
        if(count > 0)
        {
			LoopSound=Sound'DeusExSounds.Augmentation.AugLoop';
            healamount = Min(30, (45/count));
            totalamount = healamount*count;
            for(i = 0; i < count; i++)
            {
                if(targetList[i] != None)
                {
					Player.Energy -= edrain;
                    targetList[i].HealPlayer(healamount, False);
                    targetList[i].ClientFlash(0.5, vect(0, 0, 500));
                    targetList[i].lastTeamHeal = Level.TimeSeconds;
                }
            }
            if(totalamount > 0)
            {
                Player.ClientMessage("Healed"@count@"nearby player(s) for"@totalamount$"HP");
            }
        }
        else LoopSound=None;
    }
    else if(TCDeathmatch(Player.DXGame) != None)
    {
		foreach RadiusActors(class'Actor', a, 256, Player.Location)
        {
            if(a.IsA('TCPlayer')) // TODO: Only heal teammates
            {
                target = TCPlayer(a);
                if(target.PlayerReplicationInfo != None && target != TCPlayer(Player) && !target.PlayerReplicationInfo.bIsSpectator && target.Health > 0 && target.Health < 100 && (target.lastTeamHeal+1 <= Level.TimeSeconds) && AreAlliesBasic(target, TCPlayer(Player)))
                {
                    targetList[count] = target;
                    count++;
                    edrain = 3 * count;
                    if(count == 3) // We heal a maximum of 3 players
                        break;
                }
            }
        }
        
        if(count > 0)
        {
			LoopSound=Sound'DeusExSounds.Augmentation.AugLoop';
            healamount = Min(30, (45/count));
            totalamount = healamount*count;
            for(i = 0; i < count; i++)
            {
                if(targetList[i] != None)
                {
					Player.Energy -= edrain;
                    targetList[i].HealPlayer(healamount, False);
                    targetList[i].ClientFlash(0.5, vect(0, 0, 500));
                    targetList[i].lastTeamHeal = Level.TimeSeconds;
                }
            }
            if(totalamount > 0)
            {
                Player.ClientMessage("Healed"@count@"nearby player(s) for"@totalamount$"HP");
            }
        }
        else LoopSound=none;
	}
}

function bool AreAlliesBasic(TCPlayer one, tcplayer two)
{
	if(TCPRI(One.PlayerReplicationInfo).TeamNamePRI == "" || TCPRI(Two.PlayerReplicationInfo).TeamNamePRI == "")
		return false;
	
	if(TCPRI(One.PlayerReplicationInfo).TeamNamePRI == TCPRI(Two.PlayerReplicationInfo).TeamNamePRI)
		return true;
}

function float GetEnergyRate()
{
	return energyRate * LevelValues[CurrentLevel];
}

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// If this is a netgame, then override defaults
	if ( Level.NetMode != NM_StandAlone )
	{
		LevelValues[3] = mpAugValue;
		EnergyRate = mpEnergyDrain;
        AugmentationLocation = LOC_Torso;
	}
}

defaultproperties
{
    mpAugValue=0
    mpEnergyDrain=0
    EnergyRate=0
    Icon=Texture'AugIconHealingAura'
    smallIcon=Texture'AugIconHealingAura_Small'
    AugmentationName="Medic Aura"
    Description="Radar-absorbent resin augments epithelial proteins; microprojection units distort agent's visual signature. Provides highly effective concealment from automated detection systems -- bots, cameras, turrets.|n|nTECH ONE: Power drain is normal.|n|nTECH TWO: Power drain is reduced slightly.|n|nTECH THREE: Power drain is reduced moderately.|n|nTECH FOUR: Power drain is reduced significantly."
    MPInfo="Heals your allies close-by."
    LevelValues(0)=0
    LevelValues(1)=0
    LevelValues(2)=0
    LevelValues(3)=0
    LoopSound=None
	AugmentationLocation=LOC_Torso
	MPConflictSlot=2
}
