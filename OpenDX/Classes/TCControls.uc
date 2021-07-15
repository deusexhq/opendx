class TCControls extends Actor config(OpenDX);

//Core settings
var config bool bFixMovers;
var config bool bChatCommands;
var config bool bSpawnReplacer;
var config string SummonPassword;
var config string ModPassword;
var config string SuperAdminPassword;
var config string _OwnerPassword;
var config bool bAllowModSummon;
var config bool bAllowModCheats;
var config bool bAllowModGhost;
var config bool bAllowModCommand;
var config bool bAllowModMutator;
var config bool bKillMessages;
var config bool bTCFriendlyFire;
var config bool bFixLevel;
var config bool bAllowTPAsk;
var config bool bDisableFallDamage; 
var config bool bAllowSkins;
var config bool bAllowRemote;
var config bool bShowAdmins, bShowMods, bShowStatus;
var config bool bAllowSelfHUD;
var config bool bWordFilter;
var config string ConsoleName;
var config texture ScoreboardTex;
var config string ScoreboardExtStr;
var config bool bAllowRobotSkins, bAllowAnimalSkins;
var config bool bDrawServerInfo;
var config float GlobalLogTimeout;
var config int NotificationTimer;
var config bool bAllowStorage;
var config bool bNotifWhisper;
var config int MantleBio, DoubleJumpBio, WallJumpBio;
var config bool bCanSpectateEnemy;
var config float WhisperRadius;
var config bool bShowHitz;
var config string SilentAdminPassword;
var config bool bShowExtraHud;
var config int ffReduction;
var config bool bAllowMark;
var config bool bGameTypeVote;
var config bool bMapvote;
var config bool bAllowSuicide2;
var config bool bAllowKillphrase;
var config float KillphraseRadius;
var config bool bNewMainMenu, bSpectatorStart;
//var config Texture TextLogo;

struct WordFilter
{
     var config string Trgt;
	 var config string Rep;
};

var config WordFilter Filters[10];

//Anticheat vars
var config bool bPunishDT;
var config int DTLimit;
var config int AutoIdleTime, AutoIdleKickTime;
var config bool bAllowMPInv;
var config bool bEnforceFPS;
var config int FPSCap;

//Parkour vars
var config int MantleVelocity;
var config float WallJumpVelocity, DoubleJumpMultiplier, WallJumpZVelocity;
var config int WallJumpCheck;
var config bool bDoubleJump; 
var config bool bMantling; 
var config bool bWallJumping;
var config int FallDamageReduction;
var config bool bNameDisplay;

enum EHudStyle
{
	HUD_Extended, //Shows all info, the standard OpenDX HUD
	HUD_Basic, //A minimal OpenDX variation, doesn't show as much info, still uses new colouring etc
	HUD_Unified, //Shows Bots as Players, maybe other changes
	HUD_Original, //As it was in base DX
	HUD_Off //Disabled
};
var config EHudStyle HUDType;

//Sub-gametype (GunGame) Settings
var(Arsenal) config string DemoteWeapons[5];
var(Arsenal) config name SaveSpawnWeapons[5];
var(Arsenal) config bool bHealTimer;
var(Arsenal) config int HealTimer;

//Sub-gametype (KillConfirmed) Settings
var(KillConfirmed) config int KCLifespan;
var(KillConfirmed) config int BaseScoreMultiplier;

//Sub-gametype (Juggernaut) Settings
var(Juggernaut) config int StreakLimit;

//Sub-gametype (Sharpshooter) Settings
var(Sharpshooter) config string SSWeapons[30];
var(Sharpshooter) config float SSRoundDelay;
var(Sharpshooter) config bool bMethodOne;

//Static Variables
var bool _bFixedLevel;
var int TeamCount;
var ODXVoteActor Votez;

var OSDActor OSDA;

var(OpenDX) config bool bHasUpdate;
var string netversion;
var string GSCData;
var float TimeUntilUpdate;

const _k013145123423321 = "_dmg";
const version = "180109";
const changestr = "Reverting broken changes.";

function CodeBase _CodeBase()
{
	return Spawn(class'CodeBase');
}

function UpdateCheck();

function string Changes()
{
	return changestr;
}

function Timer()
{
	local TCPlayer TCP;
	local string datastring, DataStore, corever, netmsg;

	foreach AllActors(class'TCPlayer',TCP)
	{
		/*if(TCP.bTCDebug)
		{
			TCP.UpdateDebug("[DEBUG] Warns="$TCP.CheatWarns$"  Frame_info="$TCP.FrameCounter@TCP.FPS);
		}*/
		if(TCPRI(TCP.PlayerReplicationInfo).DT > DTLimit && bPunishDT && !TCPRI(TCP.PlayerReplicationInfo).bDead)
		{
			Log(TCP.PlayerReplicationInfo.PlayerName$" potential cheating.",'OpenDX');
			TCP.CheatWarns++;
			if(TCP.CheatWarns == 1)
				TCP.ClientMessage("|P2Warning: The system has detected your game running faster than normal. Please disable any external tools that modify the game speed.");
			else if(TCP.CheatWarns == 2)
				TCP.ClientMessage("|P2Second Warning: The system has detected your game running faster than normal. Please disable any external tools that modify the game speed.");
			else if(TCP.CheatWarns == 3)
				TCP.ClientMessage("|P2Final Warning: The system has detected your game running faster than normal. Please disable any external tools that modify the game speed.");
			else if(TCP.CheatWarns == 4)
			{
				Print(TCP.PlayerReplicationInfo.PlayerName$" was removed from the game. (Reason: Game speed modification)");
				TCP.Destroy();
			}
		}
		
	TCP.NetUpdatePing();
	}
}

function PostBeginPlay()
{
	local Mover m;
	
	//Fix for encroach glitch
	if(bFixMovers)
		foreach AllActors(class'Mover', m)
			if(m.MoverEncroachType != ME_CrushWhenEncroach)
				m.MoverEncroachType = ME_IgnoreWhenEncroach;
		
	SetTimer(5,True);
	Votez = Spawn(class'ODXVoteActor');
	UpdateCheck();
	TimeUntilUpdate=RandRange(10,15);
}

function string GetVer()
{
	local string str;
	
	if(TCTeam(level.game) != None)
	{
		str = "OpenDX Team Deathmatch";	
	}
	if(TCDeathMatch(level.game) != None)
	{
		str = "OpenDX Deathmatch";
	}			
	
	if(OpenDXDevTest(level.game) != None)
	{
		str = "OpenDX Development Test";		
	}
	if(OpenDX(level.game) != None)
	{
		str = "OpenDX Testing";		
	}
	if(Juggernaut(level.game) != None)
	{
		str = "Juggernaut";		
	}
	if(Infection(level.game) != None)
	{
		str = "Infection";		
	}
	if(JuggernautDM(level.game) != None)
	{
		str = "Juggernaut DM";		
	}
	if(KillConfirmed(level.game) != None)
	{
		str = "Kill Confirmed (Skullz or it didn't happen)";		
	}
	if(KillConfirmedTeam(level.game) != None)
	{
		str = "Kill Confirmed Team (Skullz or it didn't happen)";		
	}
	if(Playground(level.game) != None)
	{
		str = "Playground";
	}
	if(GunGame(level.game) != None)
	{
		str = "Arsenal/GunGame";	
	}
	if(Sharpshooter(level.game) != None)
	{
		str = "Sharpshooter";	
	}
	if(Toybox(level.game) != None)
	{
		str = "Toybox";	
	}
	str = str$" Version "$version;
	return str;
}
			
function tick (float deltatime)
{
	local carcass c;
	local DeusExLevelInfo Z52;
	
	if (!_bFixedLevel && bFixLevel)
	{
		foreach AllActors(Class'DeusExLevelInfo',Z52)
		{
			Z52.missionNumber=7;
			Z52.bMultiPlayerMap=True;
			Z52.ConversationPackage=Class'DeusExLevelInfo'.Default.ConversationPackage;
		}
		_bFixedLevel = true;
	}
	
	if(GunGame(Level.Game) != None || Sharpshooter(Level.Game) != None)
	{
			foreach allactors (class'Carcass', c)
			if (c != None)
				c.Destroy();
	}

}

function Print(string str)
{
	local MessagingSpectator MS;
	local bool bFoundAthena;
	
	//Adding custom command to allow ODX to control Athena without making the mods dependant
	foreach AllActors(class'MessagingSpectator',MS)
		if(MS.IsA('AthenaSpectator')) 
		{
			MS.ClientMessage("SAY "$str);
			bFoundAthena=True;
		}
	
	if(!bFoundAthena)	
	{
		BroadcastMessage(str);
		Log(str, 'OpenDX');
	}
}

//Sets the nums as shutdown time str, then runs the tick for matching if current time as str matches. Also run the calcs for how long it is from now til then
function SetShutdownTime(int Hours, int Mins) 
{
	local string modmins;
	
	if(OSDA == None)
	{
		if(mins < 10)
			modmins = "0"$mins;
		else modmins = string(mins);
		
		OSDA = Spawn(class'OSDActor');
		OSDA.ShutdownAtTime = string(hours) $ ":" $ modmins;
		OSDA.SDAMins = mins;
		OSDA.SDAHours = hours;
		OSDA.bSDAt=True;
		OSDA.SetTimer(60,True);
		OSDA.SetSDStr("Shuts down at "$OSDA.ShutdownAtTime);
		Print("WARNING Server will be closing at "$string(hours) $ ":" $ modmins$". This is an automated process.");
	}
	else
	Log("Scheduled shutdown error - OSDA already exists.");
}

//Shuts down in X mins, spawns a timer that runs every 60, which adds a +1 mins int, when it hits the X, close
function SetShutdownIn(int mins) 
{
	if(OSDA == None)
	{
		OSDA = Spawn(class'OSDActor');
		OSDA.ShutdownInTime = mins;
		OSDA.bSDIn=True;
		OSDA.SetTimer(60,True);
		OSDA.SetSDStr("Shuts down in "$OSDA.ShutdownInTime);
		Print("WARNING Server will be closing in "$mins$" minutes. This is an automated process.");
	}
	else
	Log("Scheduled shutdown error - OSDA already exists.");
}

function CheckSD()
{
	if(OSDA != None)
	{
		if(OSDA.bSDIn)
			Print("Shutdown in "$OSDA.ShutdownInTime - OSDA.SDInCur$" minutes scheduled.");
		
		if(OSDA.bSDAt)
			Print("Shutdown at "$OSDA.ShutdownAtTime$" scheduled.");
	}
	else
	Print("No shutdown is scheduled.");
}

function CancelSD()
{
	if(OSDA != None)
	{
		OSDA.Destroy();
		OSDA = None;
		Print("Shutdown aborted.");
	}
	else
	Log("Abort shutdown error - OSDA not found.");
}

function serverSay3(string str)
{
	local Pawn P;
    local string playerName, msg;
	local MessagingSpectator MS;

	playername = Left(str, InStr(str,">>"));
	msg = Right(str, Len(str)-instr(str,">>")-Len(">>"));
    for(P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if(TCPlayer(P) != None && P.PlayerReplicationInfo != None)
        {
            P.ClientMessage(playername$"[CONSOLE]: "$msg,'say');
        }
    }
    
    foreach AllActors(class'MessagingSpectator',MS)
		if(MS.IsA('AthenaSpectator')) //Spoofing telnet to allow console to control athena, cos too lazy to create a new override
			MS.ClientMessage(playername$"[TELNET]: "$msg,'Say');
		else
			MS.ClientMessage(playername$"[CONSOLE]: "$msg,'Say');
}

function serverSayAthena(string str)
{
	Print(str);
}

function serverSay2(string str)
{
	local Pawn P;
    local string playerName;
	local MessagingSpectator MS;
	
    for(P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if(TCPlayer(P) != None && P.PlayerReplicationInfo != None)
        {
            P.ClientMessage(ConsoleName$"[CONSOLE]: "$str,'say');
        }
    }
    
    foreach AllActors(class'MessagingSpectator',MS)
		if(MS.IsA('AthenaSpectator')) //Spoofing telnet to allow console to control athena, cos too lazy to create a new override
			MS.ClientMessage(ConsoleName$"[TELNET]: "$str,'Say');
		else
			MS.ClientMessage(ConsoleName$"[CONSOLE]: "$str,'Say');
}

function serverKick(int playerID)
{
    local Pawn P;
    local string playerName;

    for(P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if(TCPlayer(P) != None && P.PlayerReplicationInfo != None)
        {
            if(P.PlayerReplicationInfo.PlayerID == playerID)
            {
                playerName = P.PlayerReplicationInfo.PlayerName@"("$P.PlayerReplicationInfo.PlayerID$")";
                TCPlayer(P).V7D = true;
                P.Destroy();
                Print(playername@"has been kicked via console.");
                //Log(playername@"has been kicked via console.", 'OpenDX');
                return;
            }
        }
    }
    Log("Could not find a player with ID"@playerID, 'OpenDX');
}

function serverBan(int playerID) 
{
    local Pawn P;
    local string IP, playerName;
    local int i;

    for(P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if(TCPlayer(P) != None && P.PlayerReplicationInfo != None && NetConnection(PlayerPawn(P).Player) != None)
        {
            if(P.PlayerReplicationInfo.PlayerID == playerID)
            {
                IP = TCPlayer(P).GetPlayerNetworkAddress();
                if(Level.Game.CheckIPPolicy(IP))
                {
                    playerName = P.PlayerReplicationInfo.PlayerName@"("$P.PlayerReplicationInfo.PlayerID$")";
                    IP = Left(IP, InStr(IP, ":"));
                    Log("Adding IP Ban for: "$IP, 'ANNA');
                    for(i=0; i<50; i++)
                        if(Level.Game.IPPolicies[i] == "")
                            break;

                    if(i < 50)
                        Level.Game.IPPolicies[i] = "DENY,"$IP;

                    Level.Game.SaveConfig();
                }
                P.Destroy();
                Print(playername@"has been banned via console.");
                return;
            }
        }
    }
    Log("Could not find a player with ID"@playerID, 'OpenDX');
}

function serverPlayerList()
{
    local Pawn P;
    local string IP;

    Log("	ID		PLAYERNAME		IP-ADDRESS", 'OpenDX');
    for(P=Level.PawnList; P!=None; P=P.NextPawn)
    {
        if(TCPlayer(P) != None && P.PlayerReplicationInfo != None)
        {
            IP = TCPlayer(P).GetPlayerNetworkAddress();
            IP = Left(IP, InStr(IP, ":"));
            Log("	"$P.PlayerReplicationInfo.PlayerID$"		"$P.PlayerReplicationInfo.PlayerName$"		"$IP, 'OpenDX');
        }
    }
}

defaultproperties
{
	bShowExtraHud=True
	StreakLimit=5
	BaseScoreMultiplier=1
	KCLifespan=360
	bPunishDT=True
	DTLimit=125
	GlobalLogTimeout=15
	NotificationTimer=20
	bDrawServerInfo=True;
	WallJumpCheck=55
	bShowAdmins=True
	bShowMods=True
	bShowStatus=True
	DoubleJumpMultiplier=0.795
	WallJumpVelocity=1500
	WallJumpZVelocity=100
	MantleVelocity=300
	bChatCommands=True
	bTCFriendlyFire=False
	bSpawnReplacer=True
	bHealTimer=True
	HealTimer=30
	bAllowModSummon=True
	bAllowModCheats=True
	bAllowModGhost=True
	bAllowModCommand=True
	bAllowModMutator=True
	bKillMessages=True
	ModPassword="defo"
    RemoteRole=0
    bHidden=True
    bMapvote=true
    ScoreboardTex=Texture'Nano_SFX_A'
    bFixMovers=True
    bAllowKillphrase=True
    //TextLogo=Texture'DeusExSmallIcon'
}
