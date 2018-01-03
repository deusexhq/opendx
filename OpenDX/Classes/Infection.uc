//=============================================================================
// yee
//=============================================================================
class Infection expands TCDeathmatch;

var TCPlayer MainCarrier; //Just a track of who the original infected is.

var int PIK; //Pre-Infected Kills
var int IK; 

function PostBeginPlay()
{
local DeusExWeapon w;
local int r;
local Infectiontimer SST;

    super.PostBeginPlay();
	
	SST = Spawn(class'Infectiontimer');
	SST.SetTimer(1,true);
	
	SST.myGame = Self;
}

//Add MC kills level up everyones infection perk
//Anyone with infection heals 5 * level
function Killed( pawn Killer, pawn Other, name damageType )
{
	local TCPlayer KillerTC, VictimTC;
	local PerkInfection PI;
	KillerTC = TCPlayer(Killer);
	VictimTC = TCPlayer(Other);
	Super.Killed(Killer,Other,damageType);
	
	if(KillerTC != None && VictimTC != None)
	{
		if(MainCarrier == None) 
		{
			PIK++;
			if(FRand() < (0.1 * PIK)) //50% chance of every death of the beginning match triggering the infection
			{
				Settings.Print("|P2The infection begins spreading...");
				MainCarrier = VictimTC;
				VictimTC.GetPerk("OpenDX.PerkInfection");
				TCPRI(VictimTC.PlayerReplicationInfo).bInfected = True;
				VictoryConString2=" |P1) - |P2(Death brings the infection.. be the last human standing!)";
				TimeLimitString2=" |P1) - |P2(Death brings the infection.. be the last human standing!)";
			}
		}
		
		if(TCPRI(KillerTC.PlayerReplicationInfo).bInfected && !TCPRI(VictimTC.PlayerReplicationInfo).bInfected)
		{
			if(KillerTC == MainCarrier)
			{
				IK += 1;
				if(GetOdds(True))
				{
					TCPRI(VictimTC.PlayerReplicationInfo).bInfected = True;
					VictimTC.GetPerk("OpenDX.PerkInfection");
					Settings.Print("|P2"$VictimTC.PlayerReplicationInfo.PlayerName$" was infected.");
				}
			}
			else
			{
				
				if(GetOdds(False))
				{
					KillerTC.HealPlayer(IK, False);
					TCPRI(VictimTC.PlayerReplicationInfo).bInfected = True;
					VictimTC.GetPerk("OpenDX.PerkInfection");
					Settings.Print("|P2"$VictimTC.PlayerReplicationInfo.PlayerName$" was infected.");
				}
			}
		}
	}
}

function bool GetOdds(bool bMain)
{
	local float baseOdds;
	local TCPRI infecteds;
	
	baseOdds = 0.5;
	
	foreach AllActors(class'TCPRI', infecteds)
		baseOdds += 0.1;
		
	if(bMain)
		baseOdds += 0.2;
	
	if(FRand() < baseOdds)
		return True;
	else
		return False;
}

function bool bAllInfected()
{
	local TCPRI infecteds;

	foreach AllActors(class'TCPRI', infecteds)
		if(!infecteds.bInfected)
			return False;
		
	return True;
}

defaultproperties
{
	GTName="Infection"
	VictoryConString1="|P1Hit the score limit! (|P3 "
    VictoryConString2=" |P1) - |P2(Beware of the infection...)"
    TimeLimitString1="|P1Score the most! (|P3 "
    TimeLimitString2=" |P1) - |P2(Beware of the infection...)"
		//bDisableDefaultScoring=True
}
