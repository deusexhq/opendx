class PerkMediAura extends Perks;
var int db;

function HealPlayers()
{
    local Actor a;
    local TCPlayer target, targetList[3], Player;
    local int count, i, healamount, totalamount;

	Player = PerkOwner;
    count = 0;

    if(TCTeam(Player.DXGame) != None) // Healing teammates in deathmatch is useless.
    {
        foreach RadiusActors(class'Actor', a, 256, Player.Location)
        {
            if(a.IsA('TCPlayer')) // TODO: Only heal teammates
            {
                target = TCPlayer(a);
                if(target.PlayerReplicationInfo != None && target != Player &&!target.PlayerReplicationInfo.bIsSpectator && target.Health > 0 && target.Health < 100 && (target.lastTeamHeal+1 <= Level.TimeSeconds) && (target.PlayerReplicationInfo.Team == player.PlayerReplicationInfo.Team))
                {
                    targetList[count] = target;
                    count++;
                    if(count == 3) // We heal a maximum of 3 players
                        break;
                }
            }
        }
        
        if(count > 0)
        {
            healamount = Min(30, (45/count));
            totalamount = healamount*count;
            for(i = 0; i < count; i++)
            {
                if(targetList[i] != None)
                {
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
    }
    else if(TCDeathmatch(Player.DXGame) != None)
    {
		foreach RadiusActors(class'Actor', a, 256, Player.Location)
        {
            if(a.IsA('TCPlayer')) // TODO: Only heal teammates
            {
                target = TCPlayer(a);
                if(target.PlayerReplicationInfo != None && target != player &&!target.PlayerReplicationInfo.bIsSpectator && target.Health > 0 && target.Health < 100 && (target.lastTeamHeal+1 <= Level.TimeSeconds) && AreAlliesBasic(target, Player))
                {
                    targetList[count] = target;
                    count++;
                    if(count == 3) // We heal a maximum of 3 players
                        break;
                }
            }
        }
        
        if(count > 0)
        {
            healamount = Min(30, (45/count));
            totalamount = healamount*count;
            for(i = 0; i < count; i++)
            {
                if(targetList[i] != None)
                {
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
	}
}

function bool AreAlliesBasic(TCPlayer one, tcplayer two)
{
	if(TCPRI(One.PlayerReplicationInfo).TeamNamePRI == "" || TCPRI(Two.PlayerReplicationInfo).TeamNamePRI == "")
		return false;
	
	if(TCPRI(One.PlayerReplicationInfo).TeamNamePRI == TCPRI(Two.PlayerReplicationInfo).TeamNamePRI)
		return true;
}

function PerkTick()
{
	db += 1;
	
	if(db % 100 == 0)
		HealPlayers();
}

defaultproperties
{
	PerkName="Medical Aura"
}
