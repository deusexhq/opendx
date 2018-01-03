class PerkHero extends Perks;

var int HC, HHC, MaxCount, HMaxCount;
var float HRange;

var bool bWasHeal;

function bool bSafe()
{
	local bool bSafety;
	local TCPlayer TCP;
	local ScriptedPawn SP;
	
	bSafety=True; //Start true
	
	if(PerkOwner.InHand != None) //check one, are we armed
	{
		bSafety=False;
	}
	
	foreach PerkOwner.VisibleActors(class'ScriptedPawn', SP, HRange)
	{
		if(SP != None)
			bSafety=False;
	}

	foreach PerkOwner.VisibleActors(class'TCPlayer', TCP, HRange) //check two, is anyone near by
	{
		if(TCP != PerkOwner)
		{
			if(TCDeathmatch(Level.game) != None)
			{
				if(TCPRI(TCP.PlayerReplicationInfo).TeamNamePRI == "") //Target not in team, assume enemy
					bSafety=False;
				else //Target is in a team, move to ally check
				{
					if(TCPRI(TCP.PlayerReplicationInfo).TeamNamePRI != TCPRI(PerkOwner.PlayerReplicationInfo).TeamNamePRI) //Not the same team
						bSafety=False;
				}
			}
			else if(TCTeam(Level.Game) != None)
			{
				if(TCP.PlayerReplicationInfo.Team != PerkOwner.PlayerReplicationInfo.Team)
					bSafety=False;
			}
		}
	}
	
	return bSafety;
}

function PerkTick()
{
	if(bSafe()) //If both checks pass and we're still in safety, begin counting
	{
		if(HC <= MaxCount) //If counter is below the target, keep adding
			HC++;
		else //If counter is above the max, start healing
		{
			if(!bWasHeal)
			{
				bWasHeal=True;
				if(PerkOwner.Health < 100 || PerkOwner.Energy < PerkOwner.EnergyMax)//Only print message if not fully healed
					PerkOwner.ClientMessage("|P3Health has begun regenerating...");
			}
			
			
			HeroHeal();
		}
		
	}
	else //if check fails and we're not in safety, reset counter
	{
		if(bWasHeal && (PerkOwner.Health < 100 || PerkOwner.Energy < PerkOwner.EnergyMax))
			PerkOwner.ClientMessage("|P2Healing cancelled due to possible danger.");
		HC = 0;
		bWasHeal=False;
	}
}

function HeroHeal()
{
	local bool bHealed;
	
	HHC++;
	
	if(HHC > HMaxCount)
	{
		HHC = 0;
		if(PerkOwner.Health < 100)
		{
			PerkOwner.HealPlayer(15, False);
			bHealed=True;
		}
		
		if(PerkOwner.Energy < PerkOwner.EnergyMax)
		{
			PerkOwner.Energy += 15;
			if(PerkOwner.Energy > PerkOwner.EnergyMax)
				PerkOwner.Energy = PerkOwner.EnergyMax;
			
			bHealed=True;
		}
		
		if(bHealed)
			PerkOwner.ClientFlash(0.5, vect(0, 0, 500));
	}
}

defaultproperties
{
	HRange=512
	MaxCount=75
	HMaxCount=10
	PerkName="Hero Health"
}
